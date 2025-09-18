import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { User } from './useNewWalletAuth';

export interface ReferralData {
  totalReferrals: number;
  referralEarnings: number;
  recentReferrals: any[];
}

export const useNewReferralData = (user: User | null) => {
  const [referralData, setReferralData] = useState<ReferralData>({
    totalReferrals: 0,
    referralEarnings: 0,
    recentReferrals: []
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user?.wallet_address) {
      loadReferralData();
    }
  }, [user]);

  const loadReferralData = async () => {
    if (!user?.wallet_address) return;

    try {
      setLoading(true);

      // Get user's referral stats directly from the users table
      const { data: userStats, error: userError } = await supabase
        .from('users')
        .select('referrals_count, referral_earnings')
        .eq('wallet_address', user.wallet_address)
        .single();

      if (userError) {
        console.error('Error loading user referral stats:', userError);
        setReferralData({
          totalReferrals: 0,
          referralEarnings: 0,
          recentReferrals: []
        });
        return;
      }

      // Since we don't have a referrals table anymore, just use empty array
      const referrals: any[] = [];

      setReferralData({
        totalReferrals: userStats?.referrals_count || 0,
        referralEarnings: Number(userStats?.referral_earnings) || 0,
        recentReferrals: referrals
      });

    } catch (error) {
      console.error('Error loading referral data:', error);
      setReferralData({
        totalReferrals: 0,
        referralEarnings: 0,
        recentReferrals: []
      });
    } finally {
      setLoading(false);
    }
  };

  return {
    referralData,
    loading,
    refetch: loadReferralData
  };
};