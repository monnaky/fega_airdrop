import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Wallet, TrendingDown, AlertCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useAddress, useSDK } from '@thirdweb-dev/react';
import { LAUNCH_SETTINGS } from '@/utils/constants';

interface WithdrawalFormProps {
  userBalance: number;
  walletAddress: string;
  onWithdrawalSuccess: () => void;
}

export const WithdrawalForm: React.FC<WithdrawalFormProps> = ({
  userBalance,
  walletAddress,
  onWithdrawalSuccess
}) => {
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState<'confirm' | 'gas-payment' | 'processing'>('confirm');
  const { toast } = useToast();
  const address = useAddress();
  const sdk = useSDK();

  // Use hardcoded settings for launch
  const gasFee = LAUNCH_SETTINGS.CLAIM_GAS_FEE;
  const gasWallet = LAUNCH_SETTINGS.GAS_FEE_WALLET;

  const handleGasPayment = async () => {
    if (!sdk || !address) {
      toast({
        title: "Wallet Error",
        description: "Please ensure your wallet is connected",
        variant: "destructive"
      });
      return;
    }

    try {
      setLoading(true);
      setStep('gas-payment');

      if (!gasWallet) {
        throw new Error('Gas fee wallet address not configured');
      }

      // Send BNB gas fee to admin wallet
      const gasPaymentTx = await sdk.wallet.transfer(gasWallet, gasFee.toString());
      
      toast({
        title: "Gas Fee Paid",
        description: `Successfully paid ${gasFee} BNB as gas fee. Processing withdrawal...`,
      });

      // Wait for transaction confirmation
      await gasPaymentTx.receipt;

      // Now proceed with FEGA token withdrawal
      setStep('processing');
      await processWithdrawal(gasPaymentTx.receipt.transactionHash);

    } catch (error: any) {
      console.error('Gas payment error:', error);
      toast({
        title: "Gas Payment Failed",
        description: error.message || "Failed to pay gas fee",
        variant: "destructive"
      });
      setStep('confirm');
    } finally {
      setLoading(false);
    }
  };

  const processWithdrawal = async (gasPaymentTxHash: string) => {
    try {
      // Call the withdraw_to_wallet RPC function
      const { data, error } = await supabase.rpc('withdraw_to_wallet', {
        p_wallet_address: walletAddress,
        p_amount: userBalance
      });

      if (error) {
        throw new Error(error.message || 'Failed to process withdrawal');
      }

      const result = data as { success: boolean; remaining_balance?: number; error?: string };
      
      if (result?.success) {
        toast({
          title: "Withdrawal Complete",
          description: `Successfully withdrew ${userBalance.toLocaleString()} FEGA tokens! Gas fee: ${gasFee} BNB`,
        });
        onWithdrawalSuccess();
        setStep('confirm');
      } else {
        throw new Error(result?.error || 'Failed to process withdrawal');
      }
    } catch (error: any) {
      console.error('Withdrawal error:', error);
      toast({
        title: "Withdrawal Failed",
        description: error.message || "Failed to process withdrawal",
        variant: "destructive"
      });
      setStep('confirm');
    }
  };

  const renderContent = () => {
    switch (step) {
      case 'confirm':
        return (
          <>
            <div className="flex items-center justify-between p-4 bg-card rounded-lg border">
              <div>
                <p className="font-semibold">Full Balance Withdrawal</p>
                <p className="text-sm text-muted-foreground">{userBalance.toLocaleString()} FEGA tokens</p>
              </div>
              <Wallet className="h-8 w-8 text-primary" />
            </div>
            
            <div className="flex items-start space-x-3 p-4 bg-amber-50 dark:bg-amber-950/20 rounded-lg border border-amber-200 dark:border-amber-800">
              <AlertCircle className="h-5 w-5 text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
              <div className="text-sm">
                <p className="font-medium text-amber-800 dark:text-amber-200">
                  Gas Fee Required
                </p>
                <p className="text-amber-700 dark:text-amber-300">
                  A gas fee of <strong>{gasFee} BNB</strong> is required to process your withdrawal.
                  This fee covers blockchain transaction costs.
                </p>
              </div>
            </div>

            <div className="flex items-center space-x-2 text-sm text-muted-foreground">
              <span>✅ Automatic processing via smart contract</span>
            </div>

            <Button 
              onClick={handleGasPayment}
              disabled={loading || userBalance <= 0}
              className="w-full"
            >
              {loading ? "Processing..." : `Pay ${gasFee} BNB & Withdraw ${userBalance.toLocaleString()} FEGA`}
            </Button>
          </>
        );

      case 'gas-payment':
        return (
          <div className="text-center space-y-4">
            <div className="animate-spin mx-auto h-8 w-8 border-4 border-primary border-t-transparent rounded-full" />
            <p className="font-medium">Paying Gas Fee...</p>
            <p className="text-sm text-muted-foreground">
              Please confirm the {gasFee} BNB transaction in your wallet
            </p>
          </div>
        );

      case 'processing':
        return (
          <div className="text-center space-y-4">
            <div className="animate-spin mx-auto h-8 w-8 border-4 border-primary border-t-transparent rounded-full" />
            <p className="font-medium">Processing Withdrawal...</p>
            <p className="text-sm text-muted-foreground">
              Gas fee paid successfully. Withdrawing your FEGA tokens...
            </p>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <Card className="card-glow">
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <TrendingDown className="h-5 w-5" />
          <span>Withdraw Tokens</span>
        </CardTitle>
        <CardDescription>
          Request a withdrawal of your FEGA tokens. Available balance: {userBalance.toLocaleString()} FEGA
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {renderContent()}
      </CardContent>
    </Card>
  );
};