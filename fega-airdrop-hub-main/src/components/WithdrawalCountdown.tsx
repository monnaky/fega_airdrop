import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Clock, Wallet } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

interface WithdrawalCountdownProps {
  userBalance: number;
  onWithdraw: () => void;
  userWallet: string;
}

interface WithdrawalStatus {
  next_available_date: string;
  is_available: boolean;
  countdown_hours: number;
}

const WithdrawalCountdown: React.FC<WithdrawalCountdownProps> = ({ userBalance, onWithdraw, userWallet }) => {
  const [withdrawalStatus, setWithdrawalStatus] = useState<WithdrawalStatus | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const { toast } = useToast();

  const fetchWithdrawalStatus = async () => {
    try {
      console.log('🔍 WITHDRAWAL DEBUG: Fetching status for wallet:', userWallet);
      
      if (!userWallet) {
        console.log('🔍 WITHDRAWAL DEBUG: No wallet address provided');
        return;
      }

      const { data, error } = await supabase.rpc('get_withdrawal_status', {
        p_wallet_address: userWallet
      });

      if (error) {
        throw error;
      }

      console.log('🔍 WITHDRAWAL DEBUG: Database result:', data);
      setWithdrawalStatus(data as unknown as WithdrawalStatus);
    } catch (error: any) {
      console.error('Error fetching withdrawal status:', error);
      toast({
        title: "Error",
        description: "Failed to load withdrawal status",
        variant: "destructive"
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (userWallet) {
      fetchWithdrawalStatus();
      
      // Refresh every minute
      const interval = setInterval(fetchWithdrawalStatus, 60000);
      return () => clearInterval(interval);
    }
  }, [userWallet]);

  const formatCountdown = (hours: number) => {
    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;
    
    if (days > 0) {
      return `${days}d ${remainingHours}h`;
    }
    return `${remainingHours}h`;
  };

  const handleWithdraw = () => {
    if (withdrawalStatus?.is_available) {
      onWithdraw();
    }
  };

  if (isLoading) {
    return (
      <Card className="card-glow">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Withdrawal Status</CardTitle>
          <Clock className="h-4 w-4 text-primary" />
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-center">
            <p className="text-sm text-muted-foreground">Loading...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="card-glow">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">Withdrawal Window</CardTitle>
        <Wallet className="h-4 w-4 text-primary" />
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="text-center">
          {withdrawalStatus?.is_available ? (
            <div className="space-y-2">
              <p className="text-sm text-green-600 font-medium">🟢 Withdrawal Available!</p>
              <Button 
                onClick={handleWithdraw}
                className="w-full btn-pink glow-effect"
                size="lg"
              >
                <Wallet className="w-4 h-4 mr-2" />
                Withdraw Tokens
              </Button>
            </div>
          ) : (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Next withdrawal window:</p>
              <div className="text-2xl font-bold text-primary font-mono">
                {withdrawalStatus ? formatCountdown(withdrawalStatus.countdown_hours) : '--'}
              </div>
              <p className="text-xs text-muted-foreground">
                {withdrawalStatus ? new Date(withdrawalStatus.next_available_date).toLocaleDateString('en-US', {
                  weekday: 'long',
                  month: 'short',
                  day: 'numeric'
                }) : 'Loading...'}
              </p>
              <Button 
                disabled
                variant="outline"
                className="w-full opacity-50"
                size="lg"
              >
                <Clock className="w-4 h-4 mr-2" />
                Window Closed
              </Button>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default WithdrawalCountdown;