-- Fix admin_update_settings to use admin key instead of user authentication
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  p_admin_key TEXT,
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER,
  p_min_withdrawal NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_correct_admin_key TEXT := 'fegaadmin@11111'; -- The admin key used in the frontend
BEGIN
  -- Check if the provided key matches the correct key
  IF p_admin_key IS NULL OR p_admin_key != v_correct_admin_key THEN
    RAISE EXCEPTION 'Unauthorized: Invalid admin key';
  END IF;

  -- Update settings using key-value pairs
  INSERT INTO settings (key, value) VALUES ('referral_reward', p_referral_reward::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_reward::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('claim_cooldown', p_claim_cooldown_hours::TEXT)  
  ON CONFLICT (key) DO UPDATE SET value = p_claim_cooldown_hours::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  RETURN json_build_object('status', 'success', 'message', 'Settings saved successfully');
END;
$$;