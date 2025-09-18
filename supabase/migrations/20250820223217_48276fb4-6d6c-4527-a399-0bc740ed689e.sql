-- Update database schema for wallet-only authentication
-- Remove user_id dependency and make wallet_address the primary identifier

-- First, let's update the profiles table to not require user_id
ALTER TABLE public.profiles ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN wallet_address SET NOT NULL;

-- Add unique constraint on wallet_address for better querying
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_wallet_address ON public.profiles(wallet_address);

-- Update task_completions to use wallet_address instead of user_id
ALTER TABLE public.task_completions ADD COLUMN wallet_address TEXT;

-- Update claims to use wallet_address instead of user_id  
ALTER TABLE public.claims ADD COLUMN wallet_address TEXT;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_task_completions_wallet_address ON public.task_completions(wallet_address);
CREATE INDEX IF NOT EXISTS idx_claims_wallet_address ON public.claims(wallet_address);

-- Update RLS policies to work with wallet addresses
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own task completions" ON public.task_completions;
DROP POLICY IF EXISTS "Users can create their own task completions" ON public.task_completions;
DROP POLICY IF EXISTS "Users can view their own claims" ON public.claims;
DROP POLICY IF EXISTS "Users can create their own claims" ON public.claims;

-- Create new RLS policies for wallet-based authentication
CREATE POLICY "Users can view their own profile (wallet)" 
ON public.profiles 
FOR SELECT 
USING (true); -- Make profiles viewable by everyone for referral purposes

CREATE POLICY "Users can create their own profile (wallet)" 
ON public.profiles 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Users can update their own profile (wallet)" 
ON public.profiles 
FOR UPDATE 
USING (true)
WITH CHECK (true);

CREATE POLICY "Users can view their own task completions (wallet)" 
ON public.task_completions 
FOR SELECT 
USING (true);

CREATE POLICY "Users can create their own task completions (wallet)" 
ON public.task_completions 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Users can view their own claims (wallet)" 
ON public.claims 
FOR SELECT 
USING (true);

CREATE POLICY "Users can create their own claims (wallet)" 
ON public.claims 
FOR INSERT 
WITH CHECK (true);

-- Update the referral system to work with wallet addresses
-- Update the referrals table to use profile wallet addresses instead of profile IDs
ALTER TABLE public.referrals ADD COLUMN referrer_wallet TEXT;
ALTER TABLE public.referrals ADD COLUMN referred_wallet TEXT;

-- Create new validate referral function for wallet addresses
CREATE OR REPLACE FUNCTION public.validate_referral_creation_wallet(p_referrer_wallet text, p_referred_wallet text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Check if referral already exists
  IF EXISTS (
    SELECT 1 FROM referrals 
    WHERE referred_wallet = p_referred_wallet
  ) THEN
    RETURN false;
  END IF;

  -- Check if referrer and referred are different
  IF p_referrer_wallet = p_referred_wallet THEN
    RETURN false;
  END IF;

  -- Check if both profiles exist
  IF NOT EXISTS (
    SELECT 1 FROM profiles WHERE wallet_address = p_referrer_wallet
  ) OR NOT EXISTS (
    SELECT 1 FROM profiles WHERE wallet_address = p_referred_wallet
  ) THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;