-- Create bulletproof RPC functions for settings management

-- Function 1: Get settings from the key-value settings table
CREATE OR REPLACE FUNCTION get_settings()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  result JSON;
BEGIN
  -- Build settings object from key-value pairs
  SELECT json_build_object(
    'referral_reward', COALESCE((SELECT value FROM settings WHERE key = 'referral_reward')::NUMERIC, 50),
    'claim_cooldown', COALESCE((SELECT value FROM settings WHERE key = 'claim_cooldown')::INTEGER, 24),  
    'min_withdrawal_amount', COALESCE((SELECT value FROM settings WHERE key = 'min_withdrawal_amount')::NUMERIC, 1000)
  ) INTO result;
  
  RETURN result;
END;
$$;

-- Function 2: Admin update settings (corrected version)
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER, 
  p_min_withdrawal NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Check admin authorization
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Update or insert settings using key-value structure
  INSERT INTO settings (key, value) VALUES ('referral_reward', p_referral_reward::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_reward::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('claim_cooldown', p_claim_cooldown_hours::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_claim_cooldown_hours::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  -- Return success without any "demo mode" reference
  RETURN json_build_object('status', 'success', 'message', 'Settings saved successfully');
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_settings TO authenticated, anon;
GRANT EXECUTE ON FUNCTION admin_update_settings TO authenticated;