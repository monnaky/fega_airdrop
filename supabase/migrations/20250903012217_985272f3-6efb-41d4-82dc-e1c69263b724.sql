-- Drop the existing function first to avoid parameter name conflicts
DROP FUNCTION IF EXISTS public.admin_update_settings(numeric, numeric, numeric);

-- TASK 1: Fix Admin Settings Function (Remove Demo Mode)
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  p_weekly_claim_amount NUMERIC, 
  p_referral_bonus NUMERIC, 
  p_min_withdrawal NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Update settings with hard update approach
  UPDATE settings SET value = p_weekly_claim_amount::TEXT WHERE key = 'weekly_claim_amount';
  UPDATE settings SET value = p_referral_bonus::TEXT WHERE key = 'referral_bonus';
  UPDATE settings SET value = p_min_withdrawal::TEXT WHERE key = 'min_withdrawal_amount';
  
  -- Insert if not exists (fallback)
  INSERT INTO settings (key, value) VALUES ('weekly_claim_amount', p_weekly_claim_amount::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_weekly_claim_amount::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('referral_bonus', p_referral_bonus::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_bonus::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  RETURN json_build_object('status', 'success', 'message', 'Settings saved successfully.');
END;
$$;

-- TASK 2: Finalize Referral System
-- Add missing columns to users table if they don't exist
DO $$ 
BEGIN
  -- Add referrals_count if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'referrals_count'
  ) THEN
    ALTER TABLE users ADD COLUMN referrals_count INTEGER DEFAULT 0;
  END IF;
  
  -- Add referral_earnings if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'referral_earnings'
  ) THEN
    ALTER TABLE users ADD COLUMN referral_earnings NUMERIC DEFAULT 0;
  END IF;
  
  -- Add weekly_claim_last for claim functionality
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'weekly_claim_last'
  ) THEN
    ALTER TABLE users ADD COLUMN weekly_claim_last TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Recreate referral stats trigger function
CREATE OR REPLACE FUNCTION public.update_referral_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  referral_bonus_amount INTEGER;
BEGIN
  -- Only process if user has a referrer
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT value::INTEGER INTO referral_bonus_amount 
    FROM settings WHERE key = 'referral_bonus';
    
    IF referral_bonus_amount IS NULL THEN
      referral_bonus_amount := 50; -- Default fallback
    END IF;
    
    -- Update referrer's stats immediately
    UPDATE users 
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + referral_bonus_amount,
      balance = balance + referral_bonus_amount
    WHERE wallet_address = NEW.referrer_wallet;
    
    -- Create referral record
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward)
    VALUES (NEW.referrer_wallet, NEW.wallet_address, referral_bonus_amount);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_user_referral_update ON users;

-- Create trigger on INSERT
CREATE TRIGGER on_user_referral_update
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_referral_stats();

-- TASK 3: Enhanced Claim Weekly Bonus Function
CREATE OR REPLACE FUNCTION public.claim_weekly_bonus(p_wallet_address text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  weekly_amount INTEGER;
  last_claim_time TIMESTAMP WITH TIME ZONE;
  now_time TIMESTAMP WITH TIME ZONE;
  time_since_claim INTERVAL;
  user_exists BOOLEAN;
  new_balance INTEGER;
BEGIN
  now_time := NOW();
  
  -- Get weekly claim amount from settings
  SELECT value::INTEGER INTO weekly_amount FROM settings WHERE key = 'weekly_claim_amount';
  IF weekly_amount IS NULL THEN
    weekly_amount := 1000; -- Default fallback
  END IF;
  
  -- Check if user exists, create if not
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_wallet_address) INTO user_exists;
  IF NOT user_exists THEN
    INSERT INTO users (wallet_address) VALUES (p_wallet_address);
    last_claim_time := NULL;
  ELSE
    -- Get last claim time
    SELECT weekly_claim_last INTO last_claim_time FROM users WHERE wallet_address = p_wallet_address;
  END IF;
  
  -- Check eligibility (7 days = 168 hours)
  IF last_claim_time IS NOT NULL THEN
    time_since_claim := now_time - last_claim_time;
    IF time_since_claim < INTERVAL '7 days' THEN
      RETURN json_build_object(
        'success', false, 
        'error', 'Weekly claim not available yet',
        'next_eligible', last_claim_time + INTERVAL '7 days'
      );
    END IF;
  END IF;
  
  -- Process claim
  UPDATE users 
  SET balance = balance + weekly_amount,
      weekly_claim_last = now_time
  WHERE wallet_address = p_wallet_address
  RETURNING balance INTO new_balance;
  
  RETURN json_build_object(
    'success', true,
    'amount', weekly_amount,
    'new_balance', new_balance,
    'message', 'Weekly bonus claimed successfully'
  );
END;
$$;

-- TASK 5: Get All Withdrawals Function for Admin Dashboard
CREATE OR REPLACE FUNCTION public.get_all_withdrawals()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result json;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- Get all withdrawals with user wallet addresses
  SELECT json_agg(
    json_build_object(
      'id', w.id,
      'amount', w.amount,
      'status', w.status,
      'created_at', w.created_at,
      'wallet_address', u.wallet_address,
      'tx_hash', w.tx_hash
    )
    ORDER BY w.created_at DESC
  ) INTO result
  FROM withdrawals w
  JOIN users u ON w.user_id = u.id;
  
  RETURN json_build_object('success', true, 'withdrawals', COALESCE(result, '[]'::json));
END;
$$;

-- Add tx_hash column to withdrawals table for transaction logging
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'withdrawals' AND column_name = 'tx_hash'
  ) THEN
    ALTER TABLE withdrawals ADD COLUMN tx_hash TEXT;
  END IF;
END $$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION admin_update_settings TO authenticated;
GRANT EXECUTE ON FUNCTION claim_weekly_bonus TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_withdrawals TO authenticated;