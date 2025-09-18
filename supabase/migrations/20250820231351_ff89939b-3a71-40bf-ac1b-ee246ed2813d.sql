-- Clean up all existing data for fresh start
DELETE FROM task_completions;
DELETE FROM claims;
DELETE FROM referrals;
DELETE FROM profiles;

-- Reset sequences if they exist
DO $$ 
BEGIN
    -- No sequences to reset for UUID primary keys
END $$;

-- Update referrals table to support wallet-only system
ALTER TABLE referrals DROP CONSTRAINT IF EXISTS referrals_referred_wallet_fkey;
ALTER TABLE referrals DROP CONSTRAINT IF EXISTS referrals_referrer_wallet_fkey;

-- Make sure wallet fields are properly indexed
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_wallet ON referrals(referrer_wallet);
CREATE INDEX IF NOT EXISTS idx_referrals_referred_wallet ON referrals(referred_wallet);
CREATE INDEX IF NOT EXISTS idx_profiles_wallet_address ON profiles(wallet_address);
CREATE INDEX IF NOT EXISTS idx_task_completions_wallet ON task_completions(wallet_address);
CREATE INDEX IF NOT EXISTS idx_claims_wallet ON claims(wallet_address);

-- Update RLS policies for wallet-only access
DROP POLICY IF EXISTS "Users can view referrals they made" ON referrals;
DROP POLICY IF EXISTS "Users can view referrals they received" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals for themselves" ON referrals;

-- Create new wallet-based RLS policies for referrals
CREATE POLICY "Users can view referrals they made (wallet)" 
ON referrals FOR SELECT 
USING (referrer_wallet IS NOT NULL);

CREATE POLICY "Users can view referrals they received (wallet)" 
ON referrals FOR SELECT 
USING (referred_wallet IS NOT NULL);

CREATE POLICY "Users can create referrals (wallet)" 
ON referrals FOR INSERT 
WITH CHECK (referred_wallet IS NOT NULL AND referrer_wallet IS NOT NULL);

-- Add some sample tasks for testing
INSERT INTO tasks (title, description, task_type, task_url, reward_tokens, is_active) VALUES
('Follow FEGA on Twitter', 'Follow our official Twitter account @FegatToken', 'twitter', 'https://twitter.com/FegatToken', 100, true),
('Join FEGA Telegram', 'Join our official Telegram community', 'telegram', 'https://t.me/FegatToken', 150, true),
('Subscribe to FEGA YouTube', 'Subscribe to our YouTube channel', 'youtube', 'https://youtube.com/@FegatToken', 200, true),
('Follow FEGA Instagram', 'Follow our Instagram account', 'instagram', 'https://instagram.com/FegatToken', 100, true);

-- Create admin settings
INSERT INTO platform_settings (setting_key, setting_value, description) VALUES
('base_reward', '1000', 'Base reward for completing all tasks'),
('referral_bonus', '500', 'Bonus tokens for each successful referral'),
('claim_enabled', 'true', 'Whether claiming is currently enabled'),
('admin_password', 'fega2024', 'Admin dashboard password')
ON CONFLICT (setting_key) DO UPDATE SET
setting_value = EXCLUDED.setting_value,
updated_at = now();