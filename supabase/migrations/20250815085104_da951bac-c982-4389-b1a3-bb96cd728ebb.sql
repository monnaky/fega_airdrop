-- Phase 1: Critical Security Fixes

-- 1. Fix Profile Data Exposure - Restrict public access to sensitive data
DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;

-- Create more restrictive profile policies
CREATE POLICY "Users can view their own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (is_admin());

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
ALTER TABLE public.referrals 
ADD CONSTRAINT referrals_no_self_referral 
CHECK (referrer_id != referred_id);

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

-- 5. Add updated_at trigger for referrals table
CREATE TRIGGER update_referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 6. Add index for better performance on referral queries
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred_id ON public.referrals(referred_id);