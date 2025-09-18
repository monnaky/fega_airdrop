-- Fix security warnings: Set immutable search_path for functions
CREATE OR REPLACE FUNCTION public.claim_daily_bonus(p_wallet_address TEXT)
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
    daily_claim_amount := 100; -- Fallback
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
  
  -- Check if 24 hours have passed
  IF last_claim_time IS NOT NULL AND (NOW() - last_claim_time) < INTERVAL '24 hours' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Must wait 24 hours between claims',
      'next_claim_time', last_claim_time + INTERVAL '24 hours'
    );
  END IF;
  
  -- Process claim
  UPDATE users 
  SET balance = balance + daily_claim_amount,
      weekly_claim_last = NOW()
  WHERE wallet_address = p_wallet_address
  RETURNING balance INTO new_balance;
  
  RETURN json_build_object(
    'success', true,
    'amount_claimed', daily_claim_amount,
    'new_balance', new_balance,
    'message', 'Daily bonus claimed successfully'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.on_new_user_referral()
RETURNS TRIGGER
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
      referral_bonus_amount := 50; -- Fallback
    END IF;
    
    -- Update referrer's stats and balance
    UPDATE users 
    SET referrals_count = referrals_count + 1,
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

CREATE OR REPLACE FUNCTION public.withdraw_to_wallet(
  p_wallet_address TEXT,
  p_amount NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  user_balance INTEGER;
  min_withdrawal_amount INTEGER;
  user_id UUID;
BEGIN
  -- Get minimum withdrawal from settings
  SELECT value::INTEGER INTO min_withdrawal_amount 
  FROM settings WHERE key = 'min_withdrawal_amount';
  
  IF min_withdrawal_amount IS NULL THEN
    min_withdrawal_amount := 1000; -- Fallback
  END IF;
  
  -- Get user data
  SELECT id, balance INTO user_id, user_balance 
  FROM users WHERE wallet_address = p_wallet_address;
  
  IF user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Validate withdrawal amount
  IF p_amount < min_withdrawal_amount THEN
    RETURN json_build_object(
      'success', false,
      'error', format('Minimum withdrawal is %s FEGA', min_withdrawal_amount)
    );
  END IF;
  
  IF user_balance < p_amount THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;
  
  -- Deduct amount from user balance
  UPDATE users 
  SET balance = balance - p_amount::INTEGER
  WHERE wallet_address = p_wallet_address;
  
  -- Create withdrawal record
  INSERT INTO withdrawals (user_id, amount, status)
  VALUES (user_id, p_amount, 'pending');
  
  -- Return success (smart contract integration will be handled by edge function)
  RETURN json_build_object(
    'success', true,
    'message', 'Withdrawal initiated - processing blockchain transaction',
    'amount', p_amount,
    'remaining_balance', user_balance - p_amount::INTEGER
  );
END;
$$;