-- Create new schema as specified
-- Drop existing tables that will be replaced
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS task_completions CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS referrals CASCADE;

-- Create users table
CREATE TABLE public.users (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    wallet_address TEXT NOT NULL UNIQUE,
    balance INTEGER NOT NULL DEFAULT 0,
    referrer_wallet TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- Create tasks table (restructured)
DROP TABLE IF EXISTS tasks CASCADE;
CREATE TABLE public.tasks (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    link TEXT NOT NULL,
    reward INTEGER NOT NULL DEFAULT 0,
    type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- Create user_tasks table
CREATE TABLE public.user_tasks (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_wallet TEXT NOT NULL,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE(user_wallet, task_id)
);

-- Create referrals table (restructured)
CREATE TABLE public.referrals (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    referrer_wallet TEXT NOT NULL,
    referee_wallet TEXT NOT NULL UNIQUE,
    reward INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- Create admin_settings table for dynamic configuration
CREATE TABLE public.admin_settings (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    setting_key TEXT NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- Insert default referral reward setting
INSERT INTO admin_settings (setting_key, setting_value) 
VALUES ('referral_reward', '50');

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update their own profile" ON public.users FOR UPDATE USING (true);

-- RLS Policies for tasks table
CREATE POLICY "Tasks are viewable by everyone" ON public.tasks FOR SELECT USING (true);

-- RLS Policies for user_tasks table
CREATE POLICY "Users can view all task completions" ON public.user_tasks FOR SELECT USING (true);
CREATE POLICY "Users can create task completions" ON public.user_tasks FOR INSERT WITH CHECK (true);

-- RLS Policies for referrals table
CREATE POLICY "Referrals are viewable by everyone" ON public.referrals FOR SELECT USING (true);
CREATE POLICY "Referrals can be created" ON public.referrals FOR INSERT WITH CHECK (true);

-- RLS Policies for admin_settings table
CREATE POLICY "Admin settings viewable by everyone" ON public.admin_settings FOR SELECT USING (true);

-- Create indexes for performance
CREATE INDEX idx_users_wallet_address ON public.users(wallet_address);
CREATE INDEX idx_user_tasks_user_wallet ON public.user_tasks(user_wallet);
CREATE INDEX idx_user_tasks_task_id ON public.user_tasks(task_id);
CREATE INDEX idx_referrals_referrer_wallet ON public.referrals(referrer_wallet);
CREATE INDEX idx_referrals_referee_wallet ON public.referrals(referee_wallet);

-- Create functions for business logic
CREATE OR REPLACE FUNCTION public.complete_task(
    p_user_wallet TEXT,
    p_task_id UUID
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    task_reward INTEGER;
    user_exists BOOLEAN;
BEGIN
    -- Check if user exists, create if not
    SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_user_wallet) INTO user_exists;
    
    IF NOT user_exists THEN
        INSERT INTO users (wallet_address) VALUES (p_user_wallet);
    END IF;
    
    -- Get task reward
    SELECT reward INTO task_reward FROM tasks WHERE id = p_task_id;
    
    IF task_reward IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Task not found');
    END IF;
    
    -- Insert task completion (will fail if already completed due to unique constraint)
    BEGIN
        INSERT INTO user_tasks (user_wallet, task_id) VALUES (p_user_wallet, p_task_id);
    EXCEPTION WHEN unique_violation THEN
        RETURN json_build_object('success', false, 'error', 'Task already completed');
    END;
    
    -- Update user balance
    UPDATE users SET balance = balance + task_reward WHERE wallet_address = p_user_wallet;
    
    RETURN json_build_object('success', true, 'reward', task_reward);
END;
$$;

CREATE OR REPLACE FUNCTION public.process_referral(
    p_referrer_wallet TEXT,
    p_referee_wallet TEXT
) RETURNS json
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
    SELECT setting_value::INTEGER INTO referral_reward 
    FROM admin_settings WHERE setting_key = 'referral_reward';
    
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

CREATE OR REPLACE FUNCTION public.reset_production_data()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    -- Truncate user-related data but keep tasks
    TRUNCATE user_tasks;
    TRUNCATE referrals;
    UPDATE users SET balance = 0;
    
    RETURN json_build_object('success', true, 'message', 'Production data reset successfully');
END;
$$;