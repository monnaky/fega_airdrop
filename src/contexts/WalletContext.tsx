import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAddress, useConnectionStatus } from '@thirdweb-dev/react';
import { supabase } from '@/integrations/supabase/client';

interface User {
  id: string;
  wallet_address: string;
  balance: number;
  referrer_id: string | null;
  referrals_count: number;
  referral_earnings: number;
  created_at: string;
}

interface WalletContextType {
  address: string | undefined;
  user: User | null;
  loading: boolean;
  isConnected: boolean;
  refetchUser: () => Promise<void>;
  syncUserState: () => Promise<void>;
}

const WalletContext = createContext<WalletContextType | null>(null);

export const useWalletContext = () => {
  const context = useContext(WalletContext);
  if (!context) {
    throw new Error('useWalletContext must be used within a WalletProvider');
  }
  return context;
};

export const WalletProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const address = useAddress();
  const connectionStatus = useConnectionStatus();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isConnected, setIsConnected] = useState(false);

  // Restore connection state from localStorage
  useEffect(() => {
    const storedConnection = localStorage.getItem('wallet_connected');
    const storedAddress = localStorage.getItem('wallet_address');
    
    if (storedConnection === 'true' && storedAddress && !address) {
      // Auto-reconnect logic will be handled by thirdweb
      console.log('Previous wallet connection detected, waiting for auto-reconnect...');
    }
  }, []);

  // Monitor connection changes
  useEffect(() => {
    const connected = connectionStatus === 'connected' && !!address;
    setIsConnected(connected);

    if (connected) {
      localStorage.setItem('wallet_connected', 'true');
      localStorage.setItem('wallet_address', address);
      fetchOrCreateUser();
      processReferralIfExists();
    } else {
      localStorage.removeItem('wallet_connected');
      localStorage.removeItem('wallet_address');
      setUser(null);
      setLoading(false);
    }
  }, [address, connectionStatus]);

  const fetchOrCreateUser = async () => {
    if (!address) return;

    try {
      setLoading(true);
      const walletAddress = address.toLowerCase();

      const { data: existingUsers, error: existingError } = await supabase
        .from('users')
        .select('*')
        .eq('wallet_address', walletAddress)
        .limit(1);

      if (existingError) {
        console.error('Error checking existing user:', existingError);
        return;
      }

      if (existingUsers && existingUsers.length > 0) {
        setUser(existingUsers[0]);
      } else {
        // FIXED: Check URL for referral code FIRST, then localStorage as fallback
        const urlParams = new URLSearchParams(window.location.search);
        const urlReferrerWallet = urlParams.get('ref');
        let referrerWallet = localStorage.getItem('referrer_wallet');
        
        // If URL has ref param, use it and store it (handles direct navigation)
        if (urlReferrerWallet) {
          referrerWallet = urlReferrerWallet;
          localStorage.setItem('referrer_wallet', urlReferrerWallet);
          console.log('🔧 FIXED: Found referrer in URL:', urlReferrerWallet);
        }
        
        let referrerId = null;
        
        console.log('🔍 STEP 2 DEBUG: Checking for referral...');
        console.log('🔍 STEP 2 DEBUG: referrerWallet from localStorage:', referrerWallet);
        
        if (referrerWallet) {
          console.log('🔍 STEP 2 DEBUG: Processing referral for:', referrerWallet);
          
          // Find referrer's ID by wallet address
          const { data: referrerData, error: referrerError } = await supabase
            .from('users')
            .select('id, referrals_count, referral_earnings, balance')
            .eq('wallet_address', referrerWallet.toLowerCase())
            .single();
          
          if (referrerData && !referrerError) {
            referrerId = referrerData.id;
            console.log('✅ STEP 2 DEBUG: Found referrer with ID:', referrerId);
            console.log('✅ STEP 2 DEBUG: Referrer data:', referrerData);
          } else {
            console.log('❌ STEP 2 DEBUG: Referrer not found, error:', referrerError);
          }
        }

        // Create new user with referrer_id
        const insertData: any = { wallet_address: walletAddress };
        if (referrerId) {
          insertData.referrer_id = referrerId;
        }

        const { data: newUser, error: insertError } = await supabase
          .from('users')
          .insert([insertData])
          .select()
          .single();

        if (insertError) {
          console.error('Error creating user:', insertError);
          return;
        }

        if (newUser) {
          setUser(newUser);
          
          // MANUAL REFERRAL PROCESSING: Update referrer stats manually
          if (referrerId && referrerWallet) {
            console.log('🎯 STEP 2 DEBUG: Starting manual referrer stats update...');
            console.log('🎯 STEP 2 DEBUG: referrerId:', referrerId, 'referrerWallet:', referrerWallet);
            
            // Get current referrer stats first
            const { data: currentReferrer } = await supabase
              .from('users')
              .select('referrals_count, referral_earnings, balance')
              .eq('id', referrerId)
              .single();
              
            if (currentReferrer) {
              // Update referrer stats manually
              const { error: updateError } = await supabase
                .from('users')
                .update({
                  referrals_count: (currentReferrer.referrals_count || 0) + 1,
                  referral_earnings: (currentReferrer.referral_earnings || 0) + 50,
                  balance: (currentReferrer.balance || 0) + 50
                })
                .eq('id', referrerId);
                
              if (updateError) {
                console.error('❌ STEP 2 DEBUG: Failed to update referrer stats:', updateError);
              } else {
                console.log('✅ STEP 2 DEBUG: Referral bonus awarded to referrer:', referrerId);
                console.log('✅ STEP 2 DEBUG: Updated referrer stats successfully');
              }
            }
            
            // Clear referrer from localStorage
            localStorage.removeItem('referrer_wallet');
          }
        }
      }
    } catch (error) {
      console.error('Error in fetchOrCreateUser:', error);
    } finally {
      setLoading(false);
    }
  };

  const processReferralIfExists = async () => {
    if (!address) return;

    const referrerWallet = localStorage.getItem('referrer_wallet');
    if (!referrerWallet) return;

    try {
      // Remove the RPC call since we don't need it anymore - referral is handled by trigger
      console.log('Referral will be processed automatically when user is created');
      localStorage.removeItem('referrer_wallet');
    } catch (error) {
      console.error('Error in processReferralIfExists:', error);
    }
  };

  const refetchUser = async () => {
    if (address && connectionStatus === 'connected') {
      await fetchOrCreateUser();
    }
  };

  const syncUserState = async () => {
    if (!address) return;
    await fetchOrCreateUser();
  };

  const value: WalletContextType = {
    address,
    user,
    loading: loading || connectionStatus === 'connecting',
    isConnected,
    refetchUser,
    syncUserState
  };

  return (
    <WalletContext.Provider value={value}>
      {children}
    </WalletContext.Provider>
  );
};