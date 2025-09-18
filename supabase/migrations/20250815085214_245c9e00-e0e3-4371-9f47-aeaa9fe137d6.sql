-- Phase 1: Critical Security Fixes (Fixed)

-- 1. Fix Profile Data Exposure - Remove public access to sensitive data
DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;

-- Create restrictive profile policy for user's own data only
CREATE POLICY "Users can view their own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = user_id);

-- 2. Secure Referral System - Add validation to prevent unauthorized referral creation
DROP POLICY IF EXISTS "Users can create referrals" ON public.referrals;

CREATE POLICY "Users can create referrals for themselves" 
ON public.referrals 
FOR INSERT 
WITH CHECK (
  referred_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- 3. Add referral integrity constraints
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage 
    WHERE constraint_name = 'referrals_no_self_referral'
  ) THEN
    ALTER TABLE public.referrals 
    ADD CONSTRAINT referrals_no_self_referral 
    CHECK (referrer_id != referred_id);
  END IF;
END $$;

-- 4. Create secure function for referral processing validation
CREATE OR REPLACE FUNCTION public.validate_referral_creation(
  p_referrer_id uuid,
  p_referred_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Check if referral already exists
  IF EXISTS (
    SELECT 1 FROM referrals 
    WHERE referred_id = p_referred_id
  ) THEN
    RETURN false;
  END IF;

  -- Check if referrer and referred are different
  IF p_referrer_id = p_referred_id THEN
    RETURN false;
  END IF;

  -- Check if both profiles exist
  IF NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = p_referrer_id
  ) OR NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = p_referred_id
  ) THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;

-- 5. Add performance indexes
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred_id ON public.referrals(referred_id);