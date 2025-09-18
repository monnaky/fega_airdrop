-- 03_security_and_admin.sql - Secure Admin Functions and Fix Security Issues

-- Create admins table to manage admin users
CREATE TABLE admins (
  id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  role TEXT DEFAULT 'admin',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on admins table
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admins table
CREATE POLICY "Only service role can manage admins" ON admins FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins 
    WHERE id = auth.uid()
  );
END;
$$;

-- Create secure admin function to update settings
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  weekly_claim_amount NUMERIC, 
  referral_bonus NUMERIC, 
  min_withdrawal NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Update settings
  INSERT INTO settings (key, value) VALUES ('weekly_claim_amount', weekly_claim_amount::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = weekly_claim_amount::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('referral_bonus', referral_bonus::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = referral_bonus::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = min_withdrawal::TEXT;
  
  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;

-- Create secure admin function to process withdrawals
CREATE OR REPLACE FUNCTION public.admin_process_withdrawal(
  withdrawal_id UUID, 
  new_status TEXT
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  withdrawal_amount NUMERIC;
  withdrawal_user_id UUID;
  current_status TEXT;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Validate status
  IF new_status NOT IN ('approved', 'rejected') THEN
    RETURN json_build_object('success', false, 'error', 'Invalid status. Must be approved or rejected');
  END IF;
  
  -- Get withdrawal details
  SELECT amount, user_id, status INTO withdrawal_amount, withdrawal_user_id, current_status
  FROM withdrawals 
  WHERE id = withdrawal_id;
  
  IF withdrawal_amount IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Withdrawal not found');
  END IF;
  
  IF current_status != 'pending' THEN
    RETURN json_build_object('success', false, 'error', 'Withdrawal already processed');
  END IF;
  
  -- If rejecting, refund the amount to user's balance
  IF new_status = 'rejected' THEN
    UPDATE users 
    SET balance = balance + withdrawal_amount::INTEGER
    WHERE id = withdrawal_user_id;
  END IF;
  
  -- Update withdrawal status
  UPDATE withdrawals 
  SET status = new_status
  WHERE id = withdrawal_id;
  
  RETURN json_build_object(
    'success', true, 
    'withdrawal_id', withdrawal_id,
    'status', new_status,
    'amount', withdrawal_amount
  );
END;
$$;

-- Create secure admin function to get platform stats
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result json;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Get comprehensive admin data
  WITH platform_stats AS (
    SELECT 
      COUNT(DISTINCT u.id) as total_users,
      SUM(u.balance) as total_balance,
      COUNT(DISTINCT ut.id) as total_task_completions,
      COUNT(DISTINCT w.id) as total_withdrawals,
      COALESCE(SUM(CASE WHEN w.status = 'pending' THEN w.amount ELSE 0 END), 0) as pending_withdrawals,
      COUNT(DISTINCT r.id) as total_referrals
    FROM users u
    LEFT JOIN user_tasks ut ON u.wallet_address = ut.user_wallet
    LEFT JOIN withdrawals w ON w.user_id = u.id
    LEFT JOIN referrals r ON r.referrer_wallet = u.wallet_address
  )
  SELECT json_build_object(
    'success', true,
    'stats', row_to_json(platform_stats)
  ) INTO result
  FROM platform_stats;
  
  RETURN result;
END;
$$;

-- Fix security issues: Update all existing functions to have proper search_path
CREATE OR REPLACE FUNCTION public.complete_task_enhanced(p_wallet_address text, p_task_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_user_id UUID;
  v_task_reward INTEGER;
  v_existing_completion BOOLEAN;
BEGIN
  -- Find user ID from wallet address
  SELECT id INTO v_user_id 
  FROM users 
  WHERE wallet_address = p_wallet_address;
  
  -- If user doesn't exist, create them
  IF v_user_id IS NULL THEN
    INSERT INTO users (wallet_address) 
    VALUES (p_wallet_address)
    RETURNING id INTO v_user_id;
  END IF;
  
  -- Check if task is already completed
  SELECT EXISTS(
    SELECT 1 FROM user_tasks 
    WHERE user_wallet = p_wallet_address 
    AND task_id = p_task_id
  ) INTO v_existing_completion;
  
  IF v_existing_completion THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Task already completed'
    );
  END IF;
  
  -- Get task reward amount
  SELECT reward INTO v_task_reward 
  FROM tasks 
  WHERE id = p_task_id;
  
  IF v_task_reward IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Task not found'
    );
  END IF;
  
  -- Insert task completion record
  INSERT INTO user_tasks (user_wallet, task_id)
  VALUES (p_wallet_address, p_task_id);
  
  -- Update user balance
  UPDATE users 
  SET balance = balance + v_task_reward
  WHERE id = v_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Task completed successfully!',
    'reward', v_task_reward
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- Grant necessary permissions to authenticated role
GRANT EXECUTE ON FUNCTION public.admin_update_settings TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_process_withdrawal TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_referral_stats TO authenticated;