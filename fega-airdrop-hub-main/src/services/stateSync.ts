import { supabase } from '@/integrations/supabase/client';

export interface UserState {
  user: {
    id: string;
    wallet_address: string;
    balance: number;
    referrer_id: string | null;
    referrals_count: number;
    referral_earnings: number;
    created_at: string;
  };
  withdrawals: Array<{
    id: string;
    amount: number;
    status: string;
    created_at: string;
  }>;
  completedTasks: Array<{
    task_id: string;
    completed_at: string;
  }>;
}

export const syncUserState = async (walletAddress: string): Promise<UserState | null> => {
  if (!walletAddress) {
    throw new Error('Wallet address is required');
  }

  try {
    const normalizedWallet = walletAddress.toLowerCase();

    // Fetch user data
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('wallet_address', normalizedWallet)
      .single();

    if (userError) {
      console.error('Error fetching user data:', userError);
      throw userError;
    }

    if (!userData) {
      throw new Error('User not found');
    }

    // Fetch withdrawal history
    const { data: withdrawalsData, error: withdrawalsError } = await supabase
      .from('withdrawals')
      .select('id, amount, status, created_at')
      .eq('user_id', userData.id)
      .order('created_at', { ascending: false });

    if (withdrawalsError) {
      console.error('Error fetching withdrawals:', withdrawalsError);
    }

    // Fetch completed tasks - join with users table to get user_id from wallet_address
    const { data: tasksData, error: tasksError } = await supabase
      .from('user_tasks')
      .select('task_id, completed_at, users!inner(wallet_address)')
      .eq('users.wallet_address', normalizedWallet);

    if (tasksError) {
      console.error('Error fetching completed tasks:', tasksError);
    }

    return {
      user: userData,
      withdrawals: withdrawalsData || [],
      completedTasks: tasksData || []
    };
  } catch (error) {
    console.error('Error syncing user state:', error);
    throw error;
  }
};

export const getUserFreshBalance = async (walletAddress: string): Promise<number> => {
  if (!walletAddress) {
    throw new Error('Wallet address is required');
  }

  try {
    const { data, error } = await supabase
      .from('users')
      .select('balance')
      .eq('wallet_address', walletAddress.toLowerCase())
      .single();

    if (error) {
      console.error('Error fetching fresh balance:', error);
      throw error;
    }

    return data?.balance || 0;
  } catch (error) {
    console.error('Error getting fresh balance:', error);
    throw error;
  }
};