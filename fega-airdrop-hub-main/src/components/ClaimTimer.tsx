import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Clock, Coins } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

interface ClaimTimerProps {
  userBalance: number;
  onClaim: () => void;
  userWallet: string;
}

const ClaimTimer: React.FC<ClaimTimerProps> = ({ userBalance, onClaim, userWallet }) => {
  const [timeLeft, setTimeLeft] = useState(0);
  const [canClaim, setCanClaim] = useState(false);
  const [isClaiming, setIsClaiming] = useState(false);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  // 24 hour claim cooldown
  const CLAIM_COOLDOWN = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

  // Load claim status from DATABASE, not localStorage
  useEffect(() => {
    if (userWallet) {
      loadClaimStatusFromDatabase();
    }
  }, [userWallet]);

  const loadClaimStatusFromDatabase = async () => {
    try {
      setLoading(true);
      
      console.log('🔍 CLAIM DEBUG: Loading claim status for wallet:', userWallet);
      
      // Query the ACTUAL database for user's last claim time
      const { data: userData, error } = await supabase
        .from('users')
        .select('weekly_claim_last')
        .eq('wallet_address', userWallet)
        .maybeSingle();

      if (error) {
        console.error('Error loading claim status:', error);
        setCanClaim(true); // Allow claim if we can't check
        setLoading(false);
        return;
      }

      const now = Date.now();
      
      if (userData && (userData as any).weekly_claim_last) {
        const lastClaimTime = new Date((userData as any).weekly_claim_last).getTime();
        const timeSinceLastClaim = now - lastClaimTime;
        const remainingTime = CLAIM_COOLDOWN - timeSinceLastClaim;

        console.log('🔍 CLAIM DEBUG: Database last claim:', (userData as any).weekly_claim_last);
        console.log('🔍 CLAIM DEBUG: Time since last claim:', timeSinceLastClaim / 1000 / 60 / 60, 'hours');
        console.log('🔍 CLAIM DEBUG: Remaining time:', remainingTime / 1000 / 60 / 60, 'hours');

        if (remainingTime > 0) {
          setTimeLeft(remainingTime);
          setCanClaim(false);
        } else {
          setTimeLeft(0);
          setCanClaim(true);
        }
      } else {
        console.log('🔍 CLAIM DEBUG: No previous claim found, allowing claim');
        setCanClaim(true);
        setTimeLeft(0);
      }
    } catch (error) {
      console.error('Error checking claim status:', error);
      setCanClaim(true); // Allow claim on error
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (timeLeft > 0) {
      const timer = setInterval(() => {
        setTimeLeft(prev => {
          const newTime = prev - 1000;
          if (newTime <= 0) {
            setCanClaim(true);
            return 0;
          }
          return newTime;
        });
      }, 1000);

      return () => clearInterval(timer);
    }
  }, [timeLeft]);

  const formatTime = (ms: number) => {
    const hours = Math.floor(ms / (1000 * 60 * 60));
    const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((ms % (1000 * 60)) / 1000);

    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  };

  const handleClaim = async () => {
    if (!canClaim || isClaiming || !userWallet) return;

    setIsClaiming(true);
    
    try {
      console.log('🔍 CLAIM DEBUG: Attempting claim for wallet:', userWallet);
      
      // Call the database function - NO localStorage involved!
      const { data, error } = await supabase.rpc('claim_daily_bonus', {
        p_wallet_address: userWallet
      });

      if (error) {
        throw error;
      }
      
      const result = data as any;
      console.log('🔍 CLAIM DEBUG: Database result:', result);
      
      if (result?.success) {
        // NO localStorage! Reload from database instead
        await loadClaimStatusFromDatabase();
        
        onClaim(); // Refresh parent component
        
        toast({
          title: "Daily Bonus Claimed!",
          description: `You've received ${result.amount_claimed} FEGA tokens! New balance: ${result.new_balance}`,
        });
      } else {
        toast({
          title: "Claim Failed",
          description: result?.error || "Failed to claim bonus",
          variant: "destructive",
        });
      }
    } catch (error: any) {
      console.error('Claim error:', error);
      toast({
        title: "Claim Failed",
        description: error.message || "An unexpected error occurred",
        variant: "destructive",
      });
    } finally {
      setIsClaiming(false);
    }
  };

  if (loading) {
    return (
      <Card className="card-glow">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Daily Claim</CardTitle>
          <Clock className="h-4 w-4 text-primary" />
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-center">
            <p className="text-sm text-muted-foreground">Checking claim status...</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="card-glow">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">Daily Claim</CardTitle>
        <Clock className="h-4 w-4 text-primary" />
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="text-center">
          {canClaim ? (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Ready to claim!</p>
              <Button 
                onClick={handleClaim}
                disabled={isClaiming}
                className="w-full btn-pink glow-effect"
                size="lg"
              >
                <Coins className="w-4 h-4 mr-2" />
                {isClaiming ? 'Claiming...' : 'Claim 100 FEGA'}
              </Button>
            </div>
          ) : (
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Next claim in:</p>
              <div className="text-2xl font-bold text-primary font-mono">
                {formatTime(timeLeft)}
              </div>
              <Button 
                disabled
                variant="outline"
                className="w-full opacity-50"
                size="lg"
              >
                <Clock className="w-4 h-4 mr-2" />
                Come back later
              </Button>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default ClaimTimer;