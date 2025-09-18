-- Update get_settings function to include gas fee
CREATE OR REPLACE FUNCTION public.get_settings()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result JSON;
BEGIN
  -- Build settings object from key-value pairs
  SELECT json_build_object(
    'referral_reward', COALESCE((SELECT value FROM settings WHERE key = 'referral_reward')::NUMERIC, 50),
    'claim_cooldown', COALESCE((SELECT value FROM settings WHERE key = 'claim_cooldown')::INTEGER, 24),  
    'min_withdrawal_amount', COALESCE((SELECT value FROM settings WHERE key = 'min_withdrawal_amount')::NUMERIC, 1000),
    'claim_gas_fee', COALESCE((SELECT value FROM settings WHERE key = 'claim_gas_fee')::NUMERIC, 0.001)
  ) INTO result;
  
  RETURN result;
END;
$$;

-- Update admin_update_settings function to include gas fee
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_admin_key TEXT,
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER,
  p_min_withdrawal NUMERIC,
  p_claim_gas_fee NUMERIC DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_stored_admin_password TEXT;
BEGIN
  -- Get the stored admin password from the settings table
  SELECT admin_password INTO v_stored_admin_password FROM settings WHERE admin_password IS NOT NULL LIMIT 1;

  -- Check if the provided key matches the stored password
  IF p_admin_key IS NULL OR p_admin_key != v_stored_admin_password THEN
    RAISE EXCEPTION 'Unauthorized: Invalid admin key';
  END IF;

  -- If the password is correct, update the settings using key-value pairs
  INSERT INTO settings (key, value) VALUES ('referral_reward', p_referral_reward::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_reward::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('claim_cooldown', p_claim_cooldown_hours::TEXT)  
  ON CONFLICT (key) DO UPDATE SET value = p_claim_cooldown_hours::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;

  -- Update gas fee if provided
  IF p_claim_gas_fee IS NOT NULL THEN
    INSERT INTO settings (key, value) VALUES ('claim_gas_fee', p_claim_gas_fee::TEXT)
    ON CONFLICT (key) DO UPDATE SET value = p_claim_gas_fee::TEXT;
  END IF;

  RETURN json_build_object('status', 'success', 'message', 'Settings saved successfully');
END;
$$;