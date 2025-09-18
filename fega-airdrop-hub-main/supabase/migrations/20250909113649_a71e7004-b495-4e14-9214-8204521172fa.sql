-- Check if admin_update_settings function exists with correct parameters
CREATE OR REPLACE FUNCTION admin_update_settings(
  p_referral_reward NUMERIC,
  p_claim_cooldown_hours INTEGER, 
  p_min_withdrawal NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check admin authorization
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
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

-- Create referral trigger for automatic bonus payments
CREATE OR REPLACE FUNCTION process_new_user_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  referral_bonus INTEGER;
BEGIN
  -- Only process if new user has a referrer
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT value::INTEGER INTO referral_bonus 
    FROM settings WHERE key = 'referral_reward';
    
    IF referral_bonus IS NULL THEN
      referral_bonus := 50; -- Default fallback
    END IF;
    
    -- Update referrer's stats and balance
    UPDATE users 
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + referral_bonus,
      balance = balance + referral_bonus
    WHERE wallet_address = NEW.referrer_wallet;
    
    -- Create referral record
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward)
    VALUES (NEW.referrer_wallet, NEW.wallet_address, referral_bonus);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger on users table for automatic referral processing
DROP TRIGGER IF EXISTS trigger_process_referral ON users;
CREATE TRIGGER trigger_process_referral
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION process_new_user_referral();