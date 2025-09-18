import { supabase } from '@/integrations/supabase/client';

/**
 * FEGA Airdrop Service Layer
 * Provides frontend functions to interact with Supabase RPC functions
 */

/**
 * Complete a task and credit user's balance
 * @param {string} userWallet - User's wallet address
 * @param {string} taskId - Task UUID
 * @returns {Promise<Object>} Result with success status and reward amount
 */
export const completeTask = async (userWallet, taskId) => {
  try {
    const { data, error } = await supabase.rpc('complete_task_enhanced', {
      p_wallet_address: userWallet,
      p_task_id: taskId
    });

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error completing task:', error);
    return {
      success: false,
      error: error.message || 'Failed to complete task'
    };
  }
};

/**
 * Claim weekly bonus if eligible
 * @param {string} userWallet - User's wallet address
 * @returns {Promise<Object>} Result with success status and bonus amount
 */
export const claimWeeklyBonus = async (userWallet) => {
  try {
    const { data, error } = await supabase.rpc('claim_weekly_bonus', {
      p_wallet_address: userWallet
    });

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error claiming weekly bonus:', error);
    return {
      success: false,
      error: error.message || 'Failed to claim weekly bonus'
    };
  }
};

/**
 * Process referral for new user
 * @param {string} newUserWallet - New user's wallet address
 * @param {string} referrerCode - Referrer's code
 * @returns {Promise<Object>} Result with success status
 */
export const processReferral = async (newUserWallet, referrerCode) => {
  try {
    const { data, error } = await supabase.rpc('process_referral_enhanced', {
      p_new_user_wallet: newUserWallet,
      p_referrer_code: referrerCode
    });

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error processing referral:', error);
    return {
      success: false,
      error: error.message || 'Failed to process referral'
    };
  }
};

/**
 * Request withdrawal of tokens
 * @param {string} userWallet - User's wallet address
 * @param {number} amount - Amount to withdraw
 * @returns {Promise<Object>} Result with success status and withdrawal ID
 */
export const requestWithdrawal = async (userWallet, amount) => {
  try {
    const { data, error } = await supabase.rpc('request_withdrawal_enhanced', {
      p_wallet_address: userWallet,
      p_amount: amount
    });

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error requesting withdrawal:', error);
    return {
      success: false,
      error: error.message || 'Failed to request withdrawal'
    };
  }
};

/**
 * Get comprehensive user dashboard data
 * @param {string} userWallet - User's wallet address
 * @returns {Promise<Object>} Combined user data with tasks, referrals, and withdrawals
 */
export const getUserDashboardData = async (userWallet) => {
  try {
    // Get user data
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('wallet_address', userWallet)
      .single();

    if (userError && userError.code !== 'PGRST116') {
      throw userError;
    }

    // Get completed tasks
    const { data: completedTasks, error: tasksError } = await supabase
      .from('user_tasks')
      .select(`
        *,
        task:tasks(*)
      `)
      .eq('user_wallet', userWallet);

    if (tasksError) {
      throw tasksError;
    }

    // Get referrals where this user is the referrer
    const { data: referrals, error: referralsError } = await supabase
      .from('referrals')
      .select('*')
      .eq('referrer_wallet', userWallet);

    if (referralsError) {
      throw referralsError;
    }

    // Get withdrawal history
    const { data: withdrawals, error: withdrawalsError } = await supabase
      .from('withdrawals')
      .select('*')
      .eq('user_id', userData?.id || null);

    if (withdrawalsError) {
      console.warn('Error fetching withdrawals:', withdrawalsError);
    }

    return {
      success: true,
      user: userData || {
        wallet_address: userWallet,
        balance: 0,
        referral_count: 0,
        referrer_wallet: null
      },
      completedTasks: completedTasks || [],
      referrals: referrals || [],
      withdrawals: withdrawals || []
    };
  } catch (error) {
    console.error('Error getting user dashboard data:', error);
    return {
      success: false,
      error: error.message || 'Failed to fetch dashboard data'
    };
  }
};

/**
 * Get all available tasks
 * @returns {Promise<Object>} All tasks from the database
 */
export const getAllTasks = async () => {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .order('created_at', { ascending: true });

    if (error) {
      throw error;
    }

    return {
      success: true,
      tasks: data || []
    };
  } catch (error) {
    console.error('Error getting tasks:', error);
    return {
      success: false,
      error: error.message || 'Failed to fetch tasks',
      tasks: []
    };
  }
};

/**
 * Check if user has completed a specific task
 * @param {string} userWallet - User's wallet address
 * @param {string} taskId - Task UUID
 * @returns {Promise<boolean>} True if task is completed
 */
export const isTaskCompleted = async (userWallet, taskId) => {
  try {
    const { data, error } = await supabase
      .from('user_tasks')
      .select('id')
      .eq('user_wallet', userWallet)
      .eq('task_id', taskId)
      .single();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    return !!data;
  } catch (error) {
    console.error('Error checking task completion:', error);
    return false;
  }
};