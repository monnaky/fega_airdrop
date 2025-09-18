-- Fix security linter warnings for search_path in functions
-- These functions need explicit search_path setting for security

-- Fix function search paths that were flagged
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  EXECUTE sql;
  RETURN json_build_object('success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
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