import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

interface ReferralData {
  referrals_count: number;
  referral_earnings: number;
  loading: boolean;
  error: string | null;
}

export const useReferralData = (walletAddress: string | null) => {
  const [data, setData] = useState<ReferralData>({
    referrals_count: 0,
    referral_earnings: 0,
    loading: true,
    error: null
  });

  const fetchReferralData = async () => {
    if (!walletAddress) {
      setData(prev => ({ ...prev, loading: false }));
      return;
    }

    try {
      setData(prev => ({ ...prev, loading: true, error: null }));
      
      // Get referral data directly from users table (production query)
      const { data: userData, error } = await supabase
        .from('users')
        .select('referrals_count, referral_earnings')
        .eq('wallet_address', walletAddress)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          // User doesn't exist yet - create them
          const { error: insertError } = await supabase
            .from('users')
            .insert({ wallet_address: walletAddress });
          
          if (insertError) throw insertError;
          
          setData({
            referrals_count: 0,
            referral_earnings: 0,
            loading: false,
            error: null
          });
          return;
        }
        throw error;
      }

      setData({
        referrals_count: userData?.referrals_count || 0,
        referral_earnings: userData?.referral_earnings || 0,
        loading: false,
        error: null
      });
    } catch (error: any) {
      console.error('Error fetching referral data:', error);
      setData(prev => ({
        ...prev,
        loading: false,
        error: error.message || 'Failed to fetch referral data'
      }));
    }
  };

  useEffect(() => {
    fetchReferralData();
  }, [walletAddress]);

  return { ...data, refetch: fetchReferralData };
};