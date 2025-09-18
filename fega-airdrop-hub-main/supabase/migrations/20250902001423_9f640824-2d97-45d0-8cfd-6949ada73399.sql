-- 01_production_init.sql - Complete Production Database Initialization

-- Drop all tables in correct order to avoid foreign key conflicts
DROP TABLE IF EXISTS withdrawals CASCADE;
DROP TABLE IF EXISTS user_tasks CASCADE;
DROP TABLE IF EXISTS referrals CASCADE;
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS admin_settings CASCADE;
DROP TABLE IF EXISTS platform_settings CASCADE;

-- Create settings table first (no dependencies)
CREATE TABLE settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Create tasks table (no dependencies)
CREATE TABLE tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL,
  link TEXT NOT NULL,
  reward INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create users table with referral support
CREATE TABLE users (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  wallet_address TEXT NOT NULL UNIQUE,
  balance INTEGER NOT NULL DEFAULT 0,
  referrer_wallet TEXT,
  referral_count INTEGER DEFAULT 0,
  referrals_count INTEGER DEFAULT 0,
  referral_earnings NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create referrals table
CREATE TABLE referrals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_wallet TEXT NOT NULL,
  referee_wallet TEXT NOT NULL,
  reward INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create user_tasks table
CREATE TABLE user_tasks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_wallet TEXT NOT NULL,
  task_id UUID NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(user_wallet, task_id)
);

-- Create claims table
CREATE TABLE claims (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID,
  task_id UUID,
  claimed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  status TEXT DEFAULT 'pending'
);

-- Create withdrawals table
CREATE TABLE withdrawals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID,
  amount NUMERIC NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable Row Level Security on all tables
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for settings (public read, service role write)
CREATE POLICY "Anyone can read settings" ON settings FOR SELECT USING (true);
CREATE POLICY "Only service role can manage settings" ON settings FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for tasks (public read, service role write)
CREATE POLICY "Users can only view tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Only service_role can manage tasks" ON tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for users (public read for platform functionality, service role write)
CREATE POLICY "Anyone can read users" ON users FOR SELECT USING (true);
CREATE POLICY "Service role has full access to users" ON users FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for referrals
CREATE POLICY "Users can create referrals" ON referrals FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to referrals" ON referrals FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for user_tasks
CREATE POLICY "Anyone can read user_tasks" ON user_tasks FOR SELECT USING (true);
CREATE POLICY "Insert user_tasks via function" ON user_tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to user_tasks" ON user_tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for claims
CREATE POLICY "Anyone can read claims" ON claims FOR SELECT USING (true);
CREATE POLICY "Insert claims via function" ON claims FOR INSERT WITH CHECK (true);
CREATE POLICY "Service role has full access to claims" ON claims FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- RLS Policies for withdrawals
CREATE POLICY "Service role has full access to withdrawals" ON withdrawals FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- Insert initial settings
INSERT INTO settings (key, value) VALUES 
  ('weekly_claim_amount', '100'),
  ('referral_bonus', '50'),
  ('min_withdrawal_amount', '1000'),
  ('task_reward_multiplier', '1'),
  ('task_reward_cap', '500'),
  ('airdrop_start', NOW()::TEXT),
  ('airdrop_end', (NOW() + INTERVAL '90 days')::TEXT);

-- Insert sample tasks
INSERT INTO tasks (name, description, type, link, reward) VALUES 
  ('Follow FEGA on Twitter', 'Follow our official Twitter account for updates', 'twitter', 'https://twitter.com/fega_official', 50),
  ('Join FEGA Telegram', 'Join our Telegram community for discussions', 'telegram', 'https://t.me/fega_official', 75),
  ('Retweet FEGA Announcement', 'Retweet our latest announcement post', 'twitter', 'https://twitter.com/fega_official/status/latest', 100),
  ('Share FEGA with Friends', 'Share FEGA platform with your network', 'social', 'https://fega.io', 125),
  ('Complete KYC Verification', 'Complete identity verification process', 'kyc', 'https://fega.io/kyc', 200);