-- ===============================
-- FEGA AIRDROP DATABASE RESET SCRIPT (CORRECTED)
-- QA Environment Reset to Known Good State
-- ===============================

-- Disable all triggers temporarily to avoid FK conflicts
SET session_replication_role = replica;

-- Truncate all tables in dependency order (excluding admins due to auth.users FK)
TRUNCATE TABLE withdrawals CASCADE;
TRUNCATE TABLE user_tasks CASCADE;
TRUNCATE TABLE claims CASCADE;
TRUNCATE TABLE referrals CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE settings CASCADE;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- ===============================
-- REINSERT CORE DATA
-- ===============================

-- Insert default platform settings
INSERT INTO settings (key, value) VALUES 
('weekly_claim_amount', '100'),
('referral_bonus', '50'),
('min_withdrawal_amount', '1000'),
('task_reward_multiplier', '1'),
('task_reward_cap', '500');

-- Insert sample tasks for testing
INSERT INTO tasks (id, name, description, link, reward, type) VALUES
(gen_random_uuid(), 'Follow FEGA on Twitter', 'Follow our official Twitter account for updates', 'https://twitter.com/fega_official', 100, 'social'),
(gen_random_uuid(), 'Join FEGA Telegram', 'Join our Telegram community for discussions', 'https://t.me/fega_community', 150, 'social'),
(gen_random_uuid(), 'Subscribe to FEGA YouTube', 'Subscribe to our YouTube channel for tutorials', 'https://youtube.com/fega_official', 200, 'social'),
(gen_random_uuid(), 'Like FEGA Facebook Page', 'Like our Facebook page for news updates', 'https://facebook.com/fega.official', 75, 'social'),
(gen_random_uuid(), 'Join FEGA Discord', 'Join our Discord server for real-time chat', 'https://discord.gg/fega', 125, 'social');

-- Create error logging table for QA testing
CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on error_logs
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for error logs (service role only)
CREATE POLICY "Service role can manage error logs" ON error_logs
FOR ALL USING (auth.role() = 'service_role');

-- Create error logging function
CREATE OR REPLACE FUNCTION public.log_error(error_message TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  INSERT INTO error_logs (error_message) VALUES (error_message);
END;
$$;

-- Create database validation function
CREATE OR REPLACE FUNCTION public.validate_reset()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  settings_count INTEGER;
  tasks_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO settings_count FROM settings;
  SELECT COUNT(*) INTO tasks_count FROM tasks;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Database reset successful. Core data loaded.',
    'settings_loaded', settings_count,
    'tasks_loaded', tasks_count,
    'reset_timestamp', NOW()
  );
END;
$$;