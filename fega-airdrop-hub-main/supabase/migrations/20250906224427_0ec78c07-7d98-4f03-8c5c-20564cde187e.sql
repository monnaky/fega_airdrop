-- ===============================
-- TASK 1: FINAL ADMIN SETTINGS FUNCTION
-- ===============================
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  p_weekly_claim_amt NUMERIC,
  p_referral_bonus NUMERIC, 
  p_min_withdrawal NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Check if user is admin (using existing is_admin function)
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- HARD UPDATE - No demo mode, direct database modification
  UPDATE settings SET value = p_weekly_claim_amt::TEXT WHERE key = 'weekly_claim_amount';
  UPDATE settings SET value = p_referral_bonus::TEXT WHERE key = 'referral_bonus';  
  UPDATE settings SET value = p_min_withdrawal::TEXT WHERE key = 'min_withdrawal_amount';
  
  -- Insert if settings don't exist (production safety)
  INSERT INTO settings (key, value) VALUES ('weekly_claim_amount', p_weekly_claim_amt::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_weekly_claim_amt::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('referral_bonus', p_referral_bonus::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_bonus::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  RETURN json_build_object('status', 'success', 'message', 'Settings permanently updated - PRODUCTION MODE');
END;
$$;

-- ===============================
-- TASK 2: REFERRAL SYSTEM WITH TRIGGERS
-- ===============================

-- Ensure users table has required referral columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS referrals_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS referral_earnings NUMERIC DEFAULT 0;

-- Update existing users to have default values
UPDATE users SET referrals_count = 0 WHERE referrals_count IS NULL;
UPDATE users SET referral_earnings = 0 WHERE referral_earnings IS NULL;

-- Make columns non-nullable
ALTER TABLE users 
ALTER COLUMN referrals_count SET NOT NULL,
ALTER COLUMN referral_earnings SET NOT NULL;

-- Create trigger function for new user referrals
CREATE OR REPLACE FUNCTION public.on_new_user_referral()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  referral_bonus_amount INTEGER;
BEGIN
  -- Only process if new user has a referrer
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT value::INTEGER INTO referral_bonus_amount 
    FROM settings WHERE key = 'referral_bonus';
    
    IF referral_bonus_amount IS NULL THEN
      referral_bonus_amount := 50; -- Production fallback
    END IF;
    
    -- Update referrer's stats and balance immediately
    UPDATE users 
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + referral_bonus_amount,
      balance = balance + referral_bonus_amount
    WHERE wallet_address = NEW.referrer_wallet;
    
    -- Create referral record for tracking
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward)
    VALUES (NEW.referrer_wallet, NEW.wallet_address, referral_bonus_amount);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if exists and create new one
DROP TRIGGER IF EXISTS trigger_new_user_referral ON users;
CREATE TRIGGER trigger_new_user_referral
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION on_new_user_referral();

-- ===============================
-- TASK 3: CLAIM DAILY BONUS FUNCTION  
-- ===============================
CREATE OR REPLACE FUNCTION public.claim_daily_bonus(p_wallet_address text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  daily_claim_amount INTEGER;
  last_claim_time TIMESTAMP WITH TIME ZONE;
  current_balance INTEGER;
  new_balance INTEGER;
  user_exists BOOLEAN;
BEGIN
  -- Get daily claim amount from settings
  SELECT value::INTEGER INTO daily_claim_amount FROM settings WHERE key = 'weekly_claim_amount';
  IF daily_claim_amount IS NULL THEN
    daily_claim_amount := 100; -- Production fallback
  END IF;
  
  -- Check if user exists
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_wallet_address) INTO user_exists;
  IF NOT user_exists THEN
    INSERT INTO users (wallet_address) VALUES (p_wallet_address);
    last_claim_time := NULL;
  ELSE
    SELECT weekly_claim_last, balance INTO last_claim_time, current_balance 
    FROM users WHERE wallet_address = p_wallet_address;
  END IF;
  
  -- Check if 24 hours have passed since last claim
  IF last_claim_time IS NOT NULL AND (NOW() - last_claim_time) < INTERVAL '24 hours' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Must wait 24 hours between claims',
      'next_claim_time', last_claim_time + INTERVAL '24 hours'
    );
  END IF;
  
  -- Process claim - HARD UPDATE to database
  UPDATE users 
  SET balance = balance + daily_claim_amount,
      weekly_claim_last = NOW()
  WHERE wallet_address = p_wallet_address
  RETURNING balance INTO new_balance;
  
  RETURN json_build_object(
    'success', true,
    'amount_claimed', daily_claim_amount,
    'new_balance', new_balance,
    'message', 'Daily bonus claimed successfully - PRODUCTION MODE'
  );
END;
$$;