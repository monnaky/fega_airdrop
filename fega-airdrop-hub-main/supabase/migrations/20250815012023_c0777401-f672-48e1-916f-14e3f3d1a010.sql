-- Fix referral system issues
-- Add user_id to profiles table for proper RLS

-- First, add user_id column to profiles if not exists
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS user_id UUID;

-- Update RLS policies to handle both wallet_address and user_id for referrals
DROP POLICY IF EXISTS "Users can view referrals they made" ON referrals;
DROP POLICY IF EXISTS "Users can view referrals they received" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals they initiated" ON referrals;

-- Create new policies that work with profiles
CREATE POLICY "Users can view referrals they made" ON referrals 
FOR SELECT USING (
  referrer_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid() OR wallet_address = auth.uid()::text
  )
);

CREATE POLICY "Users can view referrals they received" ON referrals 
FOR SELECT USING (
  referred_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid() OR wallet_address = auth.uid()::text
  )
);

CREATE POLICY "Users can create referrals" ON referrals 
FOR INSERT WITH CHECK (true);

-- Fix profiles policies to work with wallet addresses
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON profiles; 
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

CREATE POLICY "Users can view profiles" ON profiles 
FOR SELECT USING (true);

CREATE POLICY "Users can create profiles" ON profiles 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own profile" ON profiles 
FOR UPDATE USING (
  user_id = auth.uid() OR 
  wallet_address = auth.uid()::text
) WITH CHECK (
  user_id = auth.uid() OR 
  wallet_address = auth.uid()::text
);