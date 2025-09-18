-- Fix 1: CREATE CORRECTED admin_update_settings function (no more demo mode)
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER,  
  p_min_withdrawal NUMERIC
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Check admin authorization
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- PRODUCTION UPDATE - Direct database modification
  INSERT INTO settings (key, value) VALUES ('referral_reward', p_referral_reward::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_reward::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('claim_cooldown', p_claim_cooldown_hours::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_claim_cooldown_hours::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  -- FINAL SUCCESS MESSAGE - NO DEMO MODE REFERENCE
  RETURN json_build_object('status', 'success', 'message', 'Settings permanently saved.');
END;
$$;