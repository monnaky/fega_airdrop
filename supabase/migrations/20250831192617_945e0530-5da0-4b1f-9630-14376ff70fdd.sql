-- Enable RLS on the settings table
ALTER TABLE IF EXISTS settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for settings table  
CREATE POLICY "Anyone can read settings" 
ON settings FOR SELECT 
USING (true);

CREATE POLICY "Only service role can manage settings" 
ON settings FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Fix existing functions that don't have search_path set
CREATE OR REPLACE FUNCTION public.process_referral_enhanced(p_new_user_wallet text, p_referrer_code text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  referrer_wallet TEXT;
  referral_bonus INTEGER;
  new_user_exists BOOLEAN;
  referrer_exists BOOLEAN;
BEGIN
  -- Validate inputs
  IF p_new_user_wallet = p_referrer_code THEN
    RETURN json_build_object('success', false, 'error', 'Cannot refer yourself');
  END IF;
  
  -- Find referrer by code (assuming referrer_code maps to wallet_address for now)
  SELECT wallet_address INTO referrer_wallet FROM users WHERE wallet_address = p_referrer_code;
  IF referrer_wallet IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Invalid referrer code');
  END IF;
  
  -- Check if new user already has a referrer
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_new_user_wallet AND referrer_wallet IS NOT NULL) INTO new_user_exists;
  IF new_user_exists THEN
    RETURN json_build_object('success', false, 'error', 'User already has a referrer');
  END IF;
  
  -- Get referral bonus from settings
  SELECT value::INTEGER INTO referral_bonus FROM settings WHERE key = 'referral_bonus';
  IF referral_bonus IS NULL THEN
    referral_bonus := 100; -- Default fallback
  END IF;
  
  -- Create/update new user with referrer
  INSERT INTO users (wallet_address, referrer_wallet) 
  VALUES (p_new_user_wallet, referrer_wallet)
  ON CONFLICT (wallet_address) 
  DO UPDATE SET referrer_wallet = referrer_wallet;
  
  -- Create referral record
  INSERT INTO referrals (referrer_wallet, referee_wallet, reward) 
  VALUES (referrer_wallet, p_new_user_wallet, referral_bonus);
  
  -- Credit referrer
  UPDATE users 
  SET balance = balance + referral_bonus, 
      referral_count = referral_count + 1 
  WHERE wallet_address = referrer_wallet;
  
  RETURN json_build_object(
    'success', true,
    'referrer_bonus', referral_bonus,
    'message', 'Referral processed successfully'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_withdrawal_enhanced(p_wallet_address text, p_amount numeric)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  user_balance INTEGER;
  min_withdrawal INTEGER;
  withdrawal_id UUID;
BEGIN
  -- Get minimum withdrawal from settings
  SELECT value::INTEGER INTO min_withdrawal FROM settings WHERE key = 'min_withdrawal_amount';
  IF min_withdrawal IS NULL THEN
    min_withdrawal := 1000; -- Default fallback
  END IF;
  
  -- Get user balance
  SELECT balance INTO user_balance FROM users WHERE wallet_address = p_wallet_address;
  IF user_balance IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Validate withdrawal amount
  IF p_amount < min_withdrawal THEN
    RETURN json_build_object(
      'success', false, 
      'error', format('Minimum withdrawal is %s tokens', min_withdrawal)
    );
  END IF;
  
  IF p_amount > user_balance THEN
    RETURN json_build_object('success', false, 'error', 'Insufficient balance');
  END IF;
  
  -- Process withdrawal in transaction
  BEGIN
    -- Deduct balance
    UPDATE users SET balance = balance - p_amount WHERE wallet_address = p_wallet_address;
    
    -- Create withdrawal record
    INSERT INTO withdrawals (user_id, amount) 
    VALUES (
      (SELECT id FROM users WHERE wallet_address = p_wallet_address), 
      p_amount
    )
    RETURNING id INTO withdrawal_id;
    
    RETURN json_build_object(
      'success', true,
      'withdrawal_id', withdrawal_id,
      'amount', p_amount,
      'remaining_balance', user_balance - p_amount::INTEGER,
      'status', 'pending'
    );
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', 'Failed to process withdrawal');
  END;
END;
$$;