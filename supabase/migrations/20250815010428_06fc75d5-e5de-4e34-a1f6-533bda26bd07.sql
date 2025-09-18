-- Production cleanup and database reset
-- This will clear all existing data for production deployment

-- Clear all user data
DELETE FROM task_completions;
DELETE FROM referrals;
DELETE FROM claims;
DELETE FROM profiles;

-- Reset all tasks to inactive and clean slate
UPDATE tasks SET is_active = false;

-- Keep only essential sample tasks for production
DELETE FROM tasks WHERE title NOT IN (
  'Follow us on Twitter',
  'Subscribe to our YouTube Channel', 
  'Join our Telegram Group',
  'Follow us on Instagram'
);

-- Ensure proper task setup for production
UPDATE tasks SET 
  is_active = true,
  created_at = now(),
  updated_at = now()
WHERE title IN (
  'Follow us on Twitter',
  'Subscribe to our YouTube Channel', 
  'Join our Telegram Group',
  'Follow us on Instagram'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_wallet_address ON profiles(wallet_address);
CREATE INDEX IF NOT EXISTS idx_task_completions_user_task ON task_completions(user_id, task_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_claims_user_date ON claims(user_id, created_at);