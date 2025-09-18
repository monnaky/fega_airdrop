import { useState, useEffect } from 'react';
import { useAddress, useConnectionStatus } from '@thirdweb-dev/react';
import { supabase } from '@/integrations/supabase/client';

export interface User {
  id: string;
  wallet_address: string;
  balance: number;
  referrer_id: string | null;
  referrals_count: number;
  referral_earnings: number;
  created_at: string;
}

export const useNewWalletAuth = () => {
  const address = useAddress();
  const connectionStatus = useConnectionStatus();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (address && connectionStatus === 'connected') {
      fetchOrCreateUser();
      processReferralIfExists();
    } else {
      setUser(null);
      setLoading(false);
    }
  }, [address, connectionStatus]);

  const fetchOrCreateUser = async () => {
    if (!address) return;

    try {
      setLoading(true);
      const walletAddress = address.toLowerCase();

      // Check if user already exists
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
        // MANUAL REFERRAL SYSTEM: Get referrer info before creating user
        const referrerWallet = localStorage.getItem('referrer_wallet');
        let referrerId = null;
        
        console.log('🔍 STEP 2 DEBUG (useNewWalletAuth): Checking for referral...');
        console.log('🔍 STEP 2 DEBUG (useNewWalletAuth): referrerWallet from localStorage:', referrerWallet);
        
        if (referrerWallet) {
          console.log('🔍 STEP 2 DEBUG (useNewWalletAuth): Processing referral for:', referrerWallet);
          
          // Find referrer's ID by wallet address
          const { data: referrerData, error: referrerError } = await supabase
            .from('users')
            .select('id, referrals_count, referral_earnings, balance')
            .eq('wallet_address', referrerWallet.toLowerCase())
            .single();
          
          if (referrerData && !referrerError) {
            referrerId = referrerData.id;
            console.log('✅ STEP 2 DEBUG (useNewWalletAuth): Found referrer:', referrerId);
          } else {
            console.log('❌ STEP 2 DEBUG (useNewWalletAuth): Referrer not found:', referrerError);
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
            console.log('🎯 STEP 2 DEBUG (useNewWalletAuth): Manually updating referrer stats...');
            console.log('🎯 STEP 2 DEBUG (useNewWalletAuth): referrerId:', referrerId, 'referrerWallet:', referrerWallet);
            
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
                console.error('❌ STEP 2 DEBUG (useNewWalletAuth): Failed to update referrer stats:', updateError);
              } else {
                console.log('✅ STEP 2 DEBUG (useNewWalletAuth): Referral bonus awarded to referrer:', referrerId);
              }
            }
          }
          
          // Clear referrer from localStorage after successful creation
          if (referrerWallet) {
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
    // This function is no longer needed - referral processing is now handled 
    // automatically by the database trigger when a user is created with referrer_id
    console.log('processReferralIfExists is deprecated - referrals handled by database trigger');
  };

  const refetchUser = () => {
    if (address && connectionStatus === 'connected') {
      fetchOrCreateUser();
    }
  };

  return {
    address,
    user,
    loading: loading || connectionStatus === 'connecting',
    isConnected: connectionStatus === 'connected' && !!address,
    refetchUser
  };
};