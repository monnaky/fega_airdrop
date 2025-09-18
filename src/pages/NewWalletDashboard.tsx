import React, { useEffect, useState } from 'react';
import { ConnectWallet, useAddress, useConnectionStatus } from '@thirdweb-dev/react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Copy, Users, Coins, Trophy, Share2, AlertTriangle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useWalletContext } from '@/contexts/WalletContext';
import { useNewTaskCompletion } from '@/hooks/useNewTaskCompletion';
import { useNewReferralData } from '@/hooks/useNewReferralData';
import { useReferralTracking } from '@/hooks/useReferralTracking';
import { NewTaskCard } from '@/components/NewTaskCard';
import WithdrawalCountdown from '@/components/WithdrawalCountdown';
import { WithdrawalForm } from '@/components/WithdrawalForm';
import { WithdrawalHistory } from '@/components/WithdrawalHistory';
import { supabaseUser } from '@/lib/supabaseClients';

const NewWalletDashboard = () => {
  const address = useAddress();
  const connectionStatus = useConnectionStatus();
  const { toast } = useToast();
  const [withdrawalRefresh, setWithdrawalRefresh] = useState(0);
  
  const { user, loading: authLoading, isConnected, refetchUser, syncUserState } = useWalletContext();
  const { tasks, loading: tasksLoading, markTaskVisited, markTaskCompleted, refetch: refetchTasks } = useNewTaskCompletion();
  const { referralData, loading: referralLoading, refetch: refetchReferrals } = useNewReferralData(user);
  const { getReferralLink } = useReferralTracking();

  const handleTaskVisit = (taskId: string) => {
    markTaskVisited(taskId);
  };

  const handleTaskComplete = async (taskId: string) => {
    await markTaskCompleted(taskId);
    // Sync all user state after task completion
    await syncUserState();
    refetchReferrals();
    refetchTasks(); // Also refresh tasks to ensure consistency
  };

  const copyReferralLink = () => {
    if (!address) return;
    
    const referralLink = getReferralLink(address);
    navigator.clipboard.writeText(referralLink);
    toast({
      title: "Copied!",
      description: "Referral link copied to clipboard",
    });
  };

  const shareReferralLink = () => {
    if (!address) return;
    
    const referralLink = getReferralLink(address);
    if (navigator.share) {
      navigator.share({
        title: 'Join FEGA Token Airdrop',
        text: 'Get free FEGA tokens by completing simple tasks!',
        url: referralLink,
      });
    } else {
      copyReferralLink();
    }
  };

  const handleClaim = async () => {
    // Sync user state after claim
    await syncUserState();
    refetchReferrals();
  };

  const handleWithdrawalSuccess = async () => {
    await syncUserState();
    setWithdrawalRefresh(prev => prev + 1);
  };


  if (!isConnected) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="w-full max-w-md text-center card-glow">
          <CardHeader>
            <CardTitle className="text-2xl">FEGA Token Airdrop</CardTitle>
            <CardDescription>
              Connect your wallet to start earning FEGA tokens
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ConnectWallet 
              theme="dark"
              btnTitle="Connect Wallet"
              modalTitle="Connect Your Wallet"
              switchToActiveChain={true}
              modalSize="wide"
              welcomeScreen={{
                title: "Welcome to FEGA Token Airdrop",
                subtitle: "Connect your wallet to start earning tokens",
              }}
            />
          </CardContent>
        </Card>
      </div>
    );
  }

  if (authLoading || tasksLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-lg">Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4">
      <div className="container mx-auto max-w-6xl">
        {/* Header */}
        <div className="flex flex-col md:flex-row items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">
              FEGA Token Airdrop
            </h1>
            <p className="text-muted-foreground mt-1">Complete tasks and refer friends to earn FEGA tokens</p>
          </div>
          <ConnectWallet 
            theme="dark"
            btnTitle="Wallet Connected"
            modalTitle="Wallet"
            switchToActiveChain={true}
          />
        </div>


        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <WithdrawalCountdown 
            userBalance={user?.balance || 0}
            userWallet={address || ''}
            onWithdraw={() => {
              toast({
                title: "Withdrawal Window Open",
                description: "You can now withdraw your tokens!",
              });
            }}
          />
          <Card className="card-glow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Your Balance</CardTitle>
              <Coins className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{user?.balance?.toLocaleString() || 0} FEGA</div>
            </CardContent>
          </Card>

          <Card className="card-glow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Tasks Completed</CardTitle>
              <Trophy className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{tasks.filter(t => t.completed).length}/{tasks.length}</div>
            </CardContent>
          </Card>

          <Card className="card-glow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Referrals</CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{referralData.totalReferrals}</div>
              <div className="text-sm text-muted-foreground">
                +{referralData.referralEarnings} FEGA earned
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Referral Section */}
        <Card className="mb-8 card-glow">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Share2 className="h-5 w-5" />
              <span>Referral Program</span>
            </CardTitle>
            <CardDescription>
              Earn 50 FEGA tokens for each friend you refer who completes a task
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex space-x-2">
              <Input
                value={address ? getReferralLink(address) : ''}
                readOnly
                className="flex-1"
              />
              <Button onClick={copyReferralLink} variant="outline">
                <Copy className="w-4 h-4" />
              </Button>
              <Button onClick={shareReferralLink}>
                <Share2 className="w-4 h-4 mr-2" />
                Share
              </Button>
            </div>
            
            {referralData.recentReferrals.length > 0 && (
              <div className="mt-4">
                <h4 className="font-semibold mb-2">Recent Referrals</h4>
                <div className="space-y-2">
                  {Array.isArray(referralData.recentReferrals) ? referralData.recentReferrals.map((referral: any) => (
                    <div key={referral.id} className="flex items-center justify-between text-sm">
                      <span className="font-mono">{referral.referee_wallet}</span>
                      <Badge variant="secondary">+{referral.reward_amount} FEGA</Badge>
                    </div>
                  )) : []}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Withdrawal Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <WithdrawalForm
            userBalance={user?.balance || 0}
            walletAddress={address || ''}
            onWithdrawalSuccess={handleWithdrawalSuccess}
          />
          <WithdrawalHistory
            walletAddress={address || ''}
            refreshTrigger={withdrawalRefresh}
          />
        </div>

        {/* Tasks Section */}
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-bold">Available Tasks</h2>
            <Badge variant="outline" className="text-sm">
              {tasks.filter(t => t.completed).length}/{tasks.length} Completed
            </Badge>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.isArray(tasks) ? tasks.map((task) => (
              <NewTaskCard
                key={task.id}
                task={task}
                onVisit={handleTaskVisit}
                onComplete={handleTaskComplete}
                isConnected={isConnected}
              />
            )) : []}
          </div>

          {tasks.length === 0 && (
            <Card className="card-glow">
              <CardContent className="text-center py-12">
                <Trophy className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2">No Tasks Available</h3>
                <p className="text-muted-foreground">
                  Check back later for new tasks to complete and earn FEGA tokens.
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
};

export default NewWalletDashboard;