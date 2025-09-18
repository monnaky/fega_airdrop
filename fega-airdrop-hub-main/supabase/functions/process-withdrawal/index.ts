import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Use service role key for admin operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    if (req.method === 'POST') {
      const { wallet_address, amount } = await req.json()

      console.log(`Processing withdrawal: ${amount} FEGA to ${wallet_address}`)

      // Validate inputs
      if (!wallet_address || !amount) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing wallet address or amount' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          },
        )
      }

      // Get user data, create if doesn't exist
      let { data: user, error: userError } = await supabaseClient
        .from('users')
        .select('id, balance')
        .eq('wallet_address', wallet_address)
        .single()

      // If user doesn't exist, create them automatically
      if (userError || !user) {
        console.log(`User not found, creating new user for wallet: ${wallet_address}`)
        
        const { data: newUser, error: createError } = await supabaseClient
          .from('users')
          .insert({ wallet_address: wallet_address, balance: 0 })
          .select('id, balance')
          .single()

        if (createError || !newUser) {
          console.error('Failed to create user:', createError)
          return new Response(
            JSON.stringify({ success: false, error: 'Failed to create user account' }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 500,
            },
          )
        }

        user = newUser
      }

      // Get minimum withdrawal amount from settings
      const { data: settings } = await supabaseClient
        .from('settings')
        .select('value')
        .eq('key', 'min_withdrawal_amount')
        .single()

      const minWithdrawal = settings?.value ? parseInt(settings.value) : 1000

      // Validate withdrawal amount
      if (amount < minWithdrawal) {
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: `Minimum withdrawal is ${minWithdrawal} FEGA` 
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          },
        )
      }

      if (user.balance < amount) {
        return new Response(
          JSON.stringify({ success: false, error: 'Insufficient balance' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          },
        )
      }

      // Deduct balance from user
      const { error: updateError } = await supabaseClient
        .from('users')
        .update({ balance: user.balance - amount })
        .eq('id', user.id)

      if (updateError) {
        throw updateError
      }

      // REAL BLOCKCHAIN INTERACTION
      const adminPrivateKey = Deno.env.get('ADMIN_PRIVATE_KEY')
      const fegaContractAddress = Deno.env.get('FEGA_CONTRACT_ADDRESS')
      const bscRpcUrl = Deno.env.get('BSC_RPC_URL') || 'https://bsc-dataseed.binance.org/'

      if (!adminPrivateKey || !fegaContractAddress) {
        throw new Error('Missing ADMIN_PRIVATE_KEY or FEGA_CONTRACT_ADDRESS environment variables')
      }

      console.log(`Processing real blockchain withdrawal: ${amount} FEGA to ${wallet_address}`)
      console.log(`Admin wallet: ${adminPrivateKey.slice(0, 10)}...`)
      console.log(`FEGA Contract: ${fegaContractAddress}`)

      // Import ethers.js for blockchain interaction
      const { ethers } = await import('https://esm.sh/ethers@5.7.2')
      
      // Connect to BSC
      const provider = new ethers.providers.JsonRpcProvider(bscRpcUrl)
      const adminWallet = new ethers.Wallet(adminPrivateKey, provider)
      
      // Check admin wallet BNB balance for gas
      const adminBalance = await adminWallet.getBalance()
      console.log(`Admin BNB balance: ${ethers.utils.formatEther(adminBalance)} BNB`)
      
      if (adminBalance.lt(ethers.utils.parseEther("0.001"))) {
        throw new Error('CRITICAL: Admin wallet has insufficient BNB for gas fees. Fund admin wallet immediately.')
      }

      // ERC20 ABI for FEGA token transfers
      const erc20Abi = [
        "function transfer(address to, uint256 amount) returns (bool)",
        "function balanceOf(address owner) view returns (uint256)",
        "function decimals() view returns (uint8)"
      ]
      
      // Connect to FEGA contract
      const fegaContract = new ethers.Contract(fegaContractAddress, erc20Abi, adminWallet)
      
      // Check admin wallet FEGA balance
      const adminFegaBalance = await fegaContract.balanceOf(adminWallet.address)
      const decimals = await fegaContract.decimals()
      const transferAmount = ethers.utils.parseUnits(amount.toString(), decimals)
      
      console.log(`Admin FEGA balance: ${ethers.utils.formatUnits(adminFegaBalance, decimals)}`)
      console.log(`Transfer amount: ${amount} FEGA`)
      
      if (adminFegaBalance.lt(transferAmount)) {
        throw new Error('CRITICAL: Admin wallet has insufficient FEGA tokens. Load FEGA tokens into admin wallet.')
      }

      // Execute the token transfer
      const tx = await fegaContract.transfer(wallet_address, transferAmount, {
        gasLimit: 100000, // Standard ERC20 transfer gas limit
        gasPrice: ethers.utils.parseUnits('5', 'gwei') // 5 gwei gas price
      })
      
      console.log(`Transaction sent: ${tx.hash}`)
      
      // Wait for confirmation
      const receipt = await tx.wait(1)
      console.log(`Transaction confirmed in block: ${receipt.blockNumber}`)
      
      const txHash = tx.hash

      // Create withdrawal record with approved status and tx hash
      const { data: withdrawal, error: withdrawalError } = await supabaseClient
        .from('withdrawals')
        .insert({
          user_id: user.id,
          amount: amount,
          status: 'approved',
          tx_hash: txHash
        })
        .select()
        .single()

      if (withdrawalError) {
        // Rollback balance update on failure
        await supabaseClient
          .from('users')
          .update({ balance: user.balance })
          .eq('id', user.id)
        
        throw withdrawalError
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Withdrawal processed successfully',
          withdrawal_id: withdrawal.id,
          tx_hash: txHash,
          amount: amount,
          status: 'approved',
          remaining_balance: user.balance - amount
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      )
    }

    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 405,
      },
    )
  } catch (error) {
    console.error('Error processing withdrawal:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})