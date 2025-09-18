-- Add admin_password column to settings table
ALTER TABLE settings ADD COLUMN IF NOT EXISTS admin_password TEXT;

-- Set the custom admin password (replace with your preferred password)
INSERT INTO settings (key, value, admin_password) VALUES ('admin_config', 'active', 'fegaadmin@11111')
ON CONFLICT (key) DO UPDATE SET admin_password = 'fegaadmin@11111';

-- Update the admin_update_settings function to use custom password validation
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_admin_key TEXT, -- The key from the login form
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER,
  p_min_withdrawal NUMERIC
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

  RETURN json_build_object('status', 'success', 'message', 'Settings saved successfully');
END;
$$;