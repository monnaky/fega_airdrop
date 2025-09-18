import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Coins, Trophy, Users, ArrowRight } from 'lucide-react';
import { ConnectWallet, useAddress, useConnectionStatus } from '@thirdweb-dev/react';
import { useReferralTracking } from '@/hooks/useReferralTracking';
import heroImage from '@/assets/fega-hero.jpg';

const Index = () => {
  const navigate = useNavigate();
  const address = useAddress();
  const connectionStatus = useConnectionStatus();
  const { isProcessingReferral } = useReferralTracking();

  // Redirect wallet users to wallet dashboard  
  useEffect(() => {
    if (address && connectionStatus === 'connected') {
      navigate('/dashboard');
    }
  }, [address, connectionStatus, navigate]);

  return (
    <div className="min-h-screen">
      {/* Hero Section with Logo */}
      <div className="relative overflow-hidden">
        <div className="absolute inset-0 bg-black/30"></div>
        <div 
          className="relative min-h-screen bg-cover bg-center bg-no-repeat flex items-center justify-center py-8"
          style={{ backgroundImage: `url(${heroImage})` }}
        >
          <div className="text-center text-white space-y-6 md:space-y-8 px-4 max-w-5xl mx-auto">
            {/* Logo */}
            <div className="flex justify-center mb-4 md:mb-8">
              <img 
                src="/lovable-uploads/dfb16167-bde6-46ec-bc8d-878763c351bb.png" 
                alt="FEGA Token Logo" 
                className="h-16 md:h-24 lg:h-32 w-auto animate-float glow-effect"
              />
            </div>
            
            <h1 className="text-3xl md:text-5xl lg:text-7xl font-bold text-white mb-4 md:mb-6 leading-tight">
              FEGA Token Airdrop
            </h1>
            <p className="text-base md:text-xl lg:text-2xl text-gray-200 max-w-3xl mx-auto mb-8 md:mb-12 leading-relaxed px-2">
              Complete simple social media tasks and earn free FEGA tokens. Join thousands of users building the future together.
            </p>

            {/* Connect Wallet CTA - Moved Higher and Mobile Optimized */}
            <div className="mb-12 md:mb-16">
              <ConnectWallet 
                theme="dark"
                btnTitle="🚀 Connect Wallet to Start Earning"
                modalTitle="Connect Your Wallet"
                switchToActiveChain={true}
                modalSize="wide"
                welcomeScreen={{
                  title: "Welcome to FEGA Token Airdrop",
                  subtitle: "Connect your wallet to start earning tokens immediately",
                }}
                className="!bg-gradient-to-r from-pink-500 to-pink-600 !text-white !text-base md:!text-lg !px-6 md:!px-8 !py-3 md:!py-4 !rounded-xl hover:from-pink-600 hover:to-pink-700 transition-all !shadow-pink glow-effect w-full max-w-xs md:max-w-none md:w-auto"
              />
              {isProcessingReferral && (
                <div className="flex items-center justify-center space-x-2 text-sm text-gray-300 mt-4">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary"></div>
                  <span>Processing referral...</span>
                </div>
              )}
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6 mt-8 md:mt-12 max-w-4xl mx-auto px-2">
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 md:p-6 text-center hover-scale">
                <Coins className="h-10 md:h-12 w-10 md:w-12 mx-auto mb-3 md:mb-4 text-yellow-400" />
                <h3 className="text-lg md:text-xl font-semibold mb-2 text-white">Earn Tokens</h3>
                <p className="text-sm md:text-base text-gray-300">Complete social tasks and earn FEGA tokens instantly</p>
              </div>
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 md:p-6 text-center hover-scale">
                <Users className="h-10 md:h-12 w-10 md:w-12 mx-auto mb-3 md:mb-4 text-blue-400" />
                <h3 className="text-lg md:text-xl font-semibold mb-2 text-white">Refer Friends</h3>
                <p className="text-sm md:text-base text-gray-300">Get bonus tokens for every friend you invite</p>
              </div>
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 md:p-6 text-center hover-scale">
                <Trophy className="h-10 md:h-12 w-10 md:w-12 mx-auto mb-3 md:mb-4 text-purple-400" />
                <h3 className="text-lg md:text-xl font-semibold mb-2 text-white">Join Community</h3>
                <p className="text-sm md:text-base text-gray-300">Be part of the growing FEGA ecosystem</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* How it Works Section */}
      <div className="py-12 md:py-20 px-4">
        <div className="container mx-auto max-w-4xl">
          <div className="text-center mb-12 md:mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">How It Works</h2>
            <p className="text-lg md:text-xl text-muted-foreground">Start earning FEGA tokens in 3 simple steps</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <Card className="text-center card-glow">
              <CardContent className="pt-8 pb-6">
                <div className="mx-auto mb-4 p-4 bg-primary/20 rounded-full w-fit glow-effect">
                  <span className="text-3xl font-bold text-primary">1</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">Connect Wallet</h3>
                <p className="text-muted-foreground">
                  Connect your Web3 wallet (MetaMask, Trust Wallet, etc.) - no registration needed
                </p>
              </CardContent>
            </Card>

            <Card className="text-center card-glow">
              <CardContent className="pt-8 pb-6">
                <div className="mx-auto mb-4 p-4 bg-primary/20 rounded-full w-fit glow-effect">
                  <span className="text-3xl font-bold text-primary">2</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">Complete Tasks</h3>
                <p className="text-muted-foreground">
                  Follow social accounts, like posts, join communities - simple one-click tasks
                </p>
              </CardContent>
            </Card>

            <Card className="text-center card-glow">
              <CardContent className="pt-8 pb-6">
                <div className="mx-auto mb-4 p-4 bg-primary/20 rounded-full w-fit glow-effect">
                  <span className="text-3xl font-bold text-primary">3</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">Earn Rewards</h3>
                <p className="text-muted-foreground">
                  Get instant FEGA tokens, refer friends for bonus rewards, and build your balance
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="bg-muted/30 py-12 md:py-20 px-4">
        <div className="container mx-auto max-w-6xl">
          <div className="text-center mb-12 md:mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Why Choose FEGA Token?</h2>
            <p className="text-lg md:text-xl text-muted-foreground">Join thousands of users already earning tokens</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <Card className="card-glow">
              <CardContent className="text-center pt-6">
                <Coins className="h-16 w-16 mx-auto mb-4 text-yellow-500" />
                <h3 className="text-xl font-semibold mb-2">Easy Token Earning</h3>
                <p className="text-muted-foreground">
                  Complete simple social media tasks like following, liking, and sharing to earn FEGA tokens instantly.
                </p>
              </CardContent>
            </Card>

            <Card className="card-glow">
              <CardContent className="text-center pt-6">
                <Users className="h-16 w-16 mx-auto mb-4 text-blue-500" />
                <h3 className="text-xl font-semibold mb-2">Referral Rewards</h3>
                <p className="text-muted-foreground">
                  Invite friends and earn bonus tokens for each person who joins and completes tasks through your link.
                </p>
              </CardContent>
            </Card>

            <Card className="card-glow">
              <CardContent className="text-center pt-6">
                <Trophy className="h-16 w-16 mx-auto mb-4 text-purple-500" />
                <h3 className="text-xl font-semibold mb-2">Community Driven</h3>
                <p className="text-muted-foreground">
                  Be part of a growing ecosystem with exclusive benefits for early adopters and active community members.
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Call to Action */}
      <div className="py-12 md:py-20 px-4">
        <div className="container mx-auto max-w-2xl text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">Ready to Start Earning?</h2>
          <p className="text-lg md:text-xl text-muted-foreground mb-8">
            Join thousands of users already earning FEGA tokens through simple tasks
          </p>
          <ConnectWallet 
            theme="dark"
            btnTitle="🎯 Start Earning Now"
            modalTitle="Connect Your Wallet"
            switchToActiveChain={true}
            modalSize="wide"
            welcomeScreen={{
              title: "Welcome to FEGA Token Airdrop",
              subtitle: "Connect your wallet to start earning tokens",
            }}
            className="!bg-gradient-to-r from-primary to-primary-glow !text-white !text-base md:!text-lg !px-6 md:!px-8 !py-3 md:!py-4 !rounded-xl hover:shadow-pink glow-effect transition-all w-full max-w-xs md:max-w-none md:w-auto"
          />
        </div>
      </div>
    </div>
  );
};

export default Index;