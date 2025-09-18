-- TOTAL SETTINGS SYSTEM REBUILD

-- 1. ANNIHILATE THE OLD BROKEN FUNCTIONS
DROP FUNCTION IF EXISTS admin_update_settings CASCADE;
DROP FUNCTION IF EXISTS get_settings CASCADE;

-- 2. CREATE BULLETPROOF get_settings FUNCTION
CREATE OR REPLACE FUNCTION get_settings()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (SELECT row_to_json(t) FROM (SELECT * FROM settings WHERE id = 1) t);
END;
$$;

-- 3. CREATE BULLETPROOF admin_update_settings FUNCTION
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_admin_key TEXT,
  p_referral_bonus NUMERIC,
  p_claim_cooldown_hours INTEGER,
  p_min_withdrawal NUMERIC,
  p_claim_gas_fee NUMERIC,
  p_gas_fee_wallet_address TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check admin key
  IF p_admin_key != (SELECT admin_password FROM settings WHERE id = 1) THEN
    RAISE EXCEPTION 'Unauthorized: Invalid admin key';
  END IF;

  -- Update ALL settings in a single operation
  UPDATE settings 
  SET 
    referral_bonus = p_referral_bonus,
    claim_cooldown_hours = p_claim_cooldown_hours,
    min_withdrawal = p_min_withdrawal,
    claim_gas_fee = p_claim_gas_fee,
    gas_fee_wallet_address = p_gas_fee_wallet_address
  WHERE id = 1;

  RETURN JSON_BUILD_OBJECT('status', 'success', 'message', 'All settings saved successfully.');
END;
$$;

-- 4. GRANT PERMISSIONS
GRANT EXECUTE ON FUNCTION get_settings TO public;
GRANT EXECUTE ON FUNCTION admin_update_settings TO public;