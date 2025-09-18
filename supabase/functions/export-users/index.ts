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
    // Use service role key for admin operations to bypass RLS
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const url = new URL(req.url)
    const walletAddress = url.searchParams.get('wallet_address')
    const startDate = url.searchParams.get('start_date')
    const endDate = url.searchParams.get('end_date')
    const minReferrals = url.searchParams.get('min_referrals')
    const maxReferrals = url.searchParams.get('max_referrals')

    // Build query with filters
    let query = supabaseClient
      .from('users')
      .select(`
        id,
        wallet_address,
        balance,
        referrer_wallet,
        created_at,
        referrals:referrals!referrer_wallet_fkey(count),
        user_tasks:user_tasks!user_wallet_fkey(
          task_id,
          completed_at,
          tasks:tasks(name)
        )
      `)

    // Apply filters
    if (walletAddress) {
      query = query.ilike('wallet_address', `%${walletAddress}%`)
    }
    if (startDate) {
      query = query.gte('created_at', startDate)
    }
    if (endDate) {
      query = query.lte('created_at', endDate)
    }

    const { data: users, error } = await query

    if (error) {
      throw error
    }

    // Process users data and apply referral filters
    const processedUsers = users
      ?.map(user => {
        const referralCount = Array.isArray(user.referrals) ? user.referrals.length : 0
        const completedTasks = Array.isArray(user.user_tasks) 
          ? user.user_tasks.map(ut => ut.tasks?.name || 'Unknown').join(', ')
          : ''
        const lastClaimAt = Array.isArray(user.user_tasks) && user.user_tasks.length > 0
          ? user.user_tasks.sort((a, b) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime())[0]?.completed_at
          : null

        return {
          id: user.id,
          wallet_address: user.wallet_address,
          total_claimed_tokens: user.balance || 0,
          referrals_count: referralCount,
          created_at: user.created_at,
          completed_tasks: completedTasks,
          last_claim_at: lastClaimAt
        }
      })
      .filter(user => {
        if (minReferrals && user.referrals_count < parseInt(minReferrals)) return false
        if (maxReferrals && user.referrals_count > parseInt(maxReferrals)) return false
        return true
      }) || []

    // Generate CSV
    const headers = ['ID', 'Wallet Address', 'Total Claimed Tokens', 'Referrals Count', 'Created At', 'Completed Tasks', 'Last Claim At']
    const csvRows = [
      headers.join(','),
      ...processedUsers.map(user => [
        user.id,
        user.wallet_address,
        user.total_claimed_tokens,
        user.referrals_count,
        user.created_at,
        `"${user.completed_tasks}"`,
        user.last_claim_at || ''
      ].join(','))
    ]

    const csvContent = csvRows.join('\n')

    return new Response(csvContent, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/csv',
        'Content-Disposition': 'attachment; filename="fega-users-export.csv"'
      },
      status: 200,
    })
  } catch (error) {
    console.error('Error exporting users:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})