-- Fix function search path security warnings
-- Update all functions to have immutable search_path for security

-- Update existing functions to have proper search_path settings
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- For now, we'll use a simple check - in production you'd want proper role management
  -- This function will be enhanced with proper role checking later
  RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION public.calculate_referral_earnings(referrer_profile_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  total_earnings integer := 0;
BEGIN
  -- Count successful referrals (those who have completed at least one task)
  SELECT COUNT(DISTINCT r.referred_id) * 50 INTO total_earnings
  FROM referrals r
  INNER JOIN task_completions tc ON tc.user_id = (
    SELECT user_id FROM profiles WHERE id = r.referred_id
  )
  WHERE r.referrer_id = referrer_profile_id;
  
  RETURN COALESCE(total_earnings, 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_referral_creation(p_referrer_id uuid, p_referred_id uuid)
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

CREATE OR REPLACE FUNCTION public.validate_referral_creation_wallet(p_referrer_wallet text, p_referred_wallet text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
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

CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  task_count integer;
  claim_count integer;
  referral_count integer;
  profile_count integer;
BEGIN
  -- Delete all task completions
  DELETE FROM task_completions;
  GET DIAGNOSTICS task_count = ROW_COUNT;
  
  -- Delete all claims
  DELETE FROM claims;
  GET DIAGNOSTICS claim_count = ROW_COUNT;
  
  -- Delete all referrals
  DELETE FROM referrals;
  GET DIAGNOSTICS referral_count = ROW_COUNT;
  
  -- Delete all profiles
  DELETE FROM profiles;
  GET DIAGNOSTICS profile_count = ROW_COUNT;
  
  RETURN format('Cleanup completed: %s task completions, %s claims, %s referrals, %s profiles deleted', 
                task_count, claim_count, referral_count, profile_count);
END;
$$;