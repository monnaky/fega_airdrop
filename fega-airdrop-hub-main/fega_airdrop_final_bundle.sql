-- ========================================
-- FEGA AIRDROP FINAL PRODUCTION BUNDLE
-- Complete database rebuild script
-- ========================================

-- I. TABLE CREATION
-- 1. Users table (core user management)
CREATE TABLE public.users (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_address TEXT NOT NULL UNIQUE,
    balance INTEGER NOT NULL DEFAULT 0,
    referrer_wallet TEXT,
    referral_count INTEGER DEFAULT 0,
    referrals_count INTEGER DEFAULT 0,
    referral_earnings NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    weekly_claim_last TIMESTAMP WITH TIME ZONE
);

-- 2. Tasks table (available tasks)
CREATE TABLE public.tasks (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    link TEXT NOT NULL,
    reward INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 3. User tasks completion tracking
CREATE TABLE public.user_tasks (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_wallet TEXT NOT NULL,
    task_id UUID NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(user_wallet, task_id)
);

-- 4. Claims table (task claims tracking)
CREATE TABLE public.claims (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    task_id UUID,
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    status TEXT DEFAULT 'pending'
);

-- 5. Referrals table (referral tracking)
CREATE TABLE public.referrals (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    referrer_wallet TEXT NOT NULL,
    referee_wallet TEXT NOT NULL,
    reward INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 6. Withdrawals table (withdrawal requests)
CREATE TABLE public.withdrawals (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    tx_hash TEXT
);

-- 7. Settings table (platform configuration)
CREATE TABLE public.settings (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- 8. Admins table (admin management)
CREATE TABLE public.admins (
    id UUID NOT NULL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    role TEXT DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- II. ROW LEVEL SECURITY SETUP
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Anyone can read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Service role has full access to users" ON public.users FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for tasks table
CREATE POLICY "Users can only view tasks" ON public.tasks FOR SELECT USING (true);
CREATE POLICY "Only service_role can manage tasks" ON public.tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for user_tasks table
CREATE POLICY "Anyone can read user_tasks" ON public.user_tasks FOR SELECT USING (true);
CREATE POLICY "Insert user_tasks via function" ON public.user_tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to user_tasks" ON public.user_tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for claims table
CREATE POLICY "Anyone can read claims" ON public.claims FOR SELECT USING (true);
CREATE POLICY "Insert claims via function" ON public.claims FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to claims" ON public.claims FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for referrals table
CREATE POLICY "Users can create referrals" ON public.referrals FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to referrals" ON public.referrals FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for withdrawals table
CREATE POLICY "Service role has full access to withdrawals" ON public.withdrawals FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for settings table
CREATE POLICY "Anyone can read settings" ON public.settings FOR SELECT USING (true);
CREATE POLICY "Only service role can manage settings" ON public.settings FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for admins table
CREATE POLICY "Only service role can manage admins" ON public.admins FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- III. CORE FUNCTIONS
-- 1. Admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
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

-- 2. Task completion with claims
CREATE OR REPLACE FUNCTION public.complete_task_with_claim(p_user_wallet TEXT, p_task_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  task_reward INTEGER;
  user_exists BOOLEAN;
  claim_id UUID;
  completed_tasks_count INTEGER;
  ref_wallet TEXT;
  referral_bonus INTEGER;
  reward_multiplier NUMERIC;
  reward_cap INTEGER;
BEGIN
  -- Load global settings
  SELECT value::INTEGER INTO referral_bonus 
  FROM settings WHERE key = 'referral_bonus';

  SELECT value::NUMERIC INTO reward_multiplier 
  FROM settings WHERE key = 'task_reward_multiplier';

  SELECT value::INTEGER INTO reward_cap 
  FROM settings WHERE key = 'task_reward_cap';

  -- Apply fallback defaults if missing
  IF referral_bonus IS NULL THEN referral_bonus := 100; END IF;
  IF reward_multiplier IS NULL THEN reward_multiplier := 1; END IF;
  IF reward_cap IS NULL THEN reward_cap := 500; END IF;

  -- Check if user exists, create if not
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_user_wallet) INTO user_exists;
  IF NOT user_exists THEN
    INSERT INTO users (wallet_address) VALUES (p_user_wallet);
  END IF;
  
  -- Get base task reward
  SELECT reward INTO task_reward FROM tasks WHERE id = p_task_id;
  
  IF task_reward IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Task not found');
  END IF;
  
  -- Apply multiplier & cap
  task_reward := LEAST(CEIL(task_reward * reward_multiplier), reward_cap);
  
  -- Prevent duplicate claims
  IF EXISTS(SELECT 1 FROM claims WHERE task_id = p_task_id AND user_wallet = p_user_wallet) THEN
    RETURN json_build_object('success', false, 'error', 'Task already completed');
  END IF;
  
  -- Insert claim
  INSERT INTO claims (user_wallet, task_id) 
  VALUES (p_user_wallet, p_task_id)
  RETURNING id INTO claim_id;
  
  -- Record task completion
  BEGIN
    INSERT INTO user_tasks (user_wallet, task_id) VALUES (p_user_wallet, p_task_id);
  EXCEPTION WHEN unique_violation THEN
    -- Ignore if already exists
  END;
  
  -- Update user balance
  UPDATE users SET balance = balance + task_reward WHERE wallet_address = p_user_wallet;

  -- Check if this is the FIRST completed task (for referral bonus)
  SELECT COUNT(*) INTO completed_tasks_count
  FROM claims
  WHERE user_wallet = p_user_wallet;

  IF completed_tasks_count = 1 THEN
    -- Get referrer
    SELECT referrer_wallet INTO ref_wallet FROM users WHERE wallet_address = p_user_wallet;

    IF ref_wallet IS NOT NULL THEN
      UPDATE users
      SET referral_count = referral_count + 1,
          balance = balance + referral_bonus
      WHERE wallet_address = ref_wallet;
    END IF;
  END IF;
  
  RETURN json_build_object(
    'success', true, 
    'reward', task_reward, 
    'claim_id', claim_id,
    'applied_multiplier', reward_multiplier,
    'reward_cap', reward_cap
  );
END;
$$;

-- 3. Daily bonus claim
CREATE OR REPLACE FUNCTION public.claim_daily_bonus(p_wallet_address TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  daily_claim_amount INTEGER;
  last_claim_time TIMESTAMP WITH TIME ZONE;
  current_balance INTEGER;
  new_balance INTEGER;
  user_exists BOOLEAN;
BEGIN
  -- Get daily claim amount from settings
  SELECT value::INTEGER INTO daily_claim_amount FROM settings WHERE key = 'weekly_claim_amount';
  IF daily_claim_amount IS NULL THEN
    daily_claim_amount := 100; -- Fallback
  END IF;
  
  -- Check if user exists
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_wallet_address) INTO user_exists;
  IF NOT user_exists THEN
    INSERT INTO users (wallet_address) VALUES (p_wallet_address);
    last_claim_time := NULL;
  ELSE
    SELECT weekly_claim_last, balance INTO last_claim_time, current_balance 
    FROM users WHERE wallet_address = p_wallet_address;
  END IF;
  
  -- Check if 24 hours have passed
  IF last_claim_time IS NOT NULL AND (NOW() - last_claim_time) < INTERVAL '24 hours' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Must wait 24 hours between claims',
      'next_claim_time', last_claim_time + INTERVAL '24 hours'
    );
  END IF;
  
  -- Process claim
  UPDATE users 
  SET balance = balance + daily_claim_amount,
      weekly_claim_last = NOW()
  WHERE wallet_address = p_wallet_address
  RETURNING balance INTO new_balance;
  
  RETURN json_build_object(
    'success', true,
    'amount_claimed', daily_claim_amount,
    'new_balance', new_balance,
    'message', 'Daily bonus claimed successfully'
  );
END;
$$;

-- 4. Referral processing
CREATE OR REPLACE FUNCTION public.process_referral(p_referrer_wallet TEXT, p_referee_wallet TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    referral_reward INTEGER;
    referrer_exists BOOLEAN;
    referee_exists BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_referrer_wallet = p_referee_wallet THEN
        RETURN json_build_object('success', false, 'error', 'Cannot refer yourself');
    END IF;
    
    -- Check if referee already has a referrer
    IF EXISTS(SELECT 1 FROM referrals WHERE referee_wallet = p_referee_wallet) THEN
        RETURN json_build_object('success', false, 'error', 'User already referred');
    END IF;
    
    -- Get current referral reward setting
    SELECT value::INTEGER INTO referral_reward 
    FROM settings WHERE key = 'referral_bonus';
    
    IF referral_reward IS NULL THEN
        referral_reward := 50; -- Default fallback
    END IF;
    
    -- Ensure both users exist
    SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_referrer_wallet) INTO referrer_exists;
    SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_referee_wallet) INTO referee_exists;
    
    IF NOT referrer_exists THEN
        INSERT INTO users (wallet_address) VALUES (p_referrer_wallet);
    END IF;
    
    IF NOT referee_exists THEN
        INSERT INTO users (wallet_address, referrer_wallet) VALUES (p_referee_wallet, p_referrer_wallet);
    ELSE
        UPDATE users SET referrer_wallet = p_referrer_wallet WHERE wallet_address = p_referee_wallet;
    END IF;
    
    -- Create referral record
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward) 
    VALUES (p_referrer_wallet, p_referee_wallet, referral_reward);
    
    -- Add reward to referrer's balance
    UPDATE users SET balance = balance + referral_reward WHERE wallet_address = p_referrer_wallet;
    
    RETURN json_build_object('success', true, 'reward', referral_reward);
END;
$$;

-- 5. Withdrawal function
CREATE OR REPLACE FUNCTION public.withdraw_to_wallet(p_wallet_address TEXT, p_amount NUMERIC)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  user_balance INTEGER;
  min_withdrawal_amount INTEGER;
  user_id UUID;
BEGIN
  -- Get minimum withdrawal from settings
  SELECT value::INTEGER INTO min_withdrawal_amount 
  FROM settings WHERE key = 'min_withdrawal_amount';
  
  IF min_withdrawal_amount IS NULL THEN
    min_withdrawal_amount := 1000; -- Fallback
  END IF;
  
  -- Get user data
  SELECT id, balance INTO user_id, user_balance 
  FROM users WHERE wallet_address = p_wallet_address;
  
  IF user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Validate withdrawal amount
  IF p_amount < min_withdrawal_amount THEN
    RETURN json_build_object(
      'success', false,
      'error', format('Minimum withdrawal is %s FEGA', min_withdrawal_amount)
    );
  END IF;
  
  IF user_balance < p_amount THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;
  
  -- Deduct amount from user balance
  UPDATE users 
  SET balance = balance - p_amount::INTEGER
  WHERE wallet_address = p_wallet_address;
  
  -- Create withdrawal record
  INSERT INTO withdrawals (user_id, amount, status)
  VALUES (user_id, p_amount, 'pending');
  
  -- Return success (smart contract integration will be handled by edge function)
  RETURN json_build_object(
    'success', true,
    'message', 'Withdrawal initiated - processing blockchain transaction',
    'amount', p_amount,
    'remaining_balance', user_balance - p_amount::INTEGER
  );
END;
$$;

-- 6. Admin functions
CREATE OR REPLACE FUNCTION public.admin_update_settings(p_weekly_claim_amt NUMERIC, p_referral_bonus NUMERIC, p_min_withdrawal NUMERIC)
RETURNS JSON
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
  UPDATE settings SET value = p_weekly_claim_amt::TEXT WHERE key = 'weekly_claim_amount';
  UPDATE settings SET value = p_referral_bonus::TEXT WHERE key = 'referral_bonus';  
  UPDATE settings SET value = p_min_withdrawal::TEXT WHERE key = 'min_withdrawal_amount';
  
  -- Insert if settings don't exist
  INSERT INTO settings (key, value) VALUES ('weekly_claim_amount', p_weekly_claim_amt::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_weekly_claim_amt::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('referral_bonus', p_referral_bonus::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_bonus::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  RETURN json_build_object('status', 'success', 'message', 'Settings updated successfully');
END;
$$;

CREATE OR REPLACE FUNCTION public.get_all_withdrawals()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result JSON;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Get all withdrawals with user wallet addresses
  SELECT json_agg(
    json_build_object(
      'id', w.id,
      'amount', w.amount,
      'status', w.status,
      'created_at', w.created_at,
      'wallet_address', u.wallet_address,
      'tx_hash', w.tx_hash
    )
    ORDER BY w.created_at DESC
  ) INTO result
  FROM withdrawals w
  JOIN users u ON w.user_id = u.id;
  
  RETURN json_build_object('success', true, 'withdrawals', COALESCE(result, '[]'::JSON));
END;
$$;

-- IV. TRIGGERS
-- Referral trigger for new user signup
CREATE OR REPLACE FUNCTION public.on_new_user_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  referral_bonus_amount INTEGER;
BEGIN
  -- Only process if new user has a referrer
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT value::INTEGER INTO referral_bonus_amount 
    FROM settings WHERE key = 'referral_bonus';
    
    IF referral_bonus_amount IS NULL THEN
      referral_bonus_amount := 50; -- Fallback
    END IF;
    
    -- Update referrer's stats and balance
    UPDATE users 
    SET referrals_count = referrals_count + 1,
        referral_earnings = referral_earnings + referral_bonus_amount,
        balance = balance + referral_bonus_amount
    WHERE wallet_address = NEW.referrer_wallet;
    
    -- Create referral record
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward)
    VALUES (NEW.referrer_wallet, NEW.wallet_address, referral_bonus_amount);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_user_referral_signup
    AFTER INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.on_new_user_referral();

-- V. INITIAL DATA SETUP
-- Insert default settings
INSERT INTO public.settings (key, value) VALUES
('weekly_claim_amount', '100'),
('referral_bonus', '50'),
('min_withdrawal_amount', '1000'),
('task_reward_multiplier', '1'),
('task_reward_cap', '500'),
('airdrop_start', NOW()::TEXT),
('airdrop_end', (NOW() + INTERVAL '3 months')::TEXT);

-- Insert default tasks
INSERT INTO public.tasks (id, name, description, type, link, reward) VALUES
('506ff3a3-4896-4db9-a523-8c66b60ddf04', 'Follow FEGA on Twitter', 'Follow our official Twitter account for updates', 'twitter', 'https://twitter.com/fega_official', 50),
('f8ecefee-e6ee-45c5-bd42-ca19f5c272e3', 'Join FEGA Telegram', 'Join our Telegram community for discussions', 'telegram', 'https://t.me/fega_official', 75),
('459b8587-1dd4-417a-9559-59c35fbc8d90', 'Retweet FEGA Announcement', 'Retweet our latest announcement post', 'twitter', 'https://twitter.com/fega_official/status/latest', 100),
('413a2d2b-9d3e-4aa0-af8c-4d998f556643', 'Share FEGA with Friends', 'Share FEGA platform with your network', 'social', 'https://fega.io', 125),
('e84cce2a-875d-4587-881d-0eeb71951eeb', 'Complete KYC Verification', 'Complete identity verification process', 'kyc', 'https://fega.io/kyc', 200);

-- VI. GRANT PERMISSIONS
-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Grant table permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT ON public.users, public.user_tasks, public.claims, public.referrals TO anon, authenticated;

-- Grant sequence permissions
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Grant function permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- ========================================
-- END OF FEGA AIRDROP FINAL BUNDLE
-- ========================================