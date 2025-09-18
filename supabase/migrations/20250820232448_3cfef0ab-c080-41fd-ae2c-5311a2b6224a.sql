-- Fix remaining functions with mutable search paths
-- These functions were created earlier and need proper security settings

CREATE OR REPLACE FUNCTION public.increment_profile_tokens(p_wallet_address text, p_token_increment integer, p_task_increment integer DEFAULT 1)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Update or insert profile with incremented values
  INSERT INTO profiles (
    wallet_address,
    total_tokens_earned,
    total_tasks_completed,
    created_at,
    updated_at
  )
  VALUES (
    p_wallet_address,
    p_token_increment,
    p_task_increment,
    now(),
    now()
  )
  ON CONFLICT (wallet_address)
  DO UPDATE SET
    total_tokens_earned = profiles.total_tokens_earned + p_token_increment,
    total_tasks_completed = profiles.total_tasks_completed + p_task_increment,
    updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_referral_count(p_wallet_address text, p_token_increment integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Update profile with incremented referral count and tokens
  UPDATE profiles 
  SET 
    referral_count = referral_count + 1,
    total_tokens_earned = total_tokens_earned + p_token_increment,
    updated_at = now()
  WHERE wallet_address = p_wallet_address;
  
  -- If profile doesn't exist, create it
  IF NOT FOUND THEN
    INSERT INTO profiles (
      wallet_address,
      referral_count,
      total_tokens_earned,
      created_at,
      updated_at
    )
    VALUES (
      p_wallet_address,
      1,
      p_token_increment,
      now(),
      now()
    );
  END IF;
END;
$$;

-- Fix the exec_sql function as well
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