-- Fix RLS policies for admin_settings to allow edge function access
-- First check if admin_settings table needs proper policies

-- Drop existing restrictive policies on admin_settings
DROP POLICY IF EXISTS "Admin settings viewable by everyone" ON admin_settings;

-- Create new policies that allow both public read and edge function write
CREATE POLICY "Admin settings are publicly readable" 
ON admin_settings 
FOR SELECT 
USING (true);

CREATE POLICY "Admin settings can be updated by service role" 
ON admin_settings 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Admin settings can be updated by service role for updates" 
ON admin_settings 
FOR UPDATE 
USING (true);

-- Insert default admin settings if they don't exist
INSERT INTO admin_settings (setting_key, setting_value) 
VALUES 
  ('referral_reward', '50'),
  ('claim_cooldown', '24')
ON CONFLICT (setting_key) DO NOTHING;