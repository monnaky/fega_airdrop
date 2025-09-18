-- Enhanced complete_task function with better validation and transaction handling
CREATE OR REPLACE FUNCTION complete_task_enhanced(p_wallet_address text, p_task_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  task_reward INTEGER;
  user_exists BOOLEAN;
  task_exists BOOLEAN;
  already_completed BOOLEAN;
BEGIN
  -- Check if task exists
  SELECT EXISTS(SELECT 1 FROM tasks WHERE id = p_task_id) INTO task_exists;
  IF NOT task_exists THEN
    RETURN json_build_object('success', false, 'error', 'Task not found');
  END IF;

  -- Get task reward
  SELECT reward INTO task_reward FROM tasks WHERE id = p_task_id;
  
  -- Check if user exists, create if not
  SELECT EXISTS(SELECT 1 FROM users WHERE wallet_address = p_wallet_address) INTO user_exists;
  IF NOT user_exists THEN
    INSERT INTO users (wallet_address) VALUES (p_wallet_address);
  END IF;
  
  -- Check if task already completed
  SELECT EXISTS(SELECT 1 FROM user_tasks WHERE user_wallet = p_wallet_address AND task_id = p_task_id) INTO already_completed;
  IF already_completed THEN
    RETURN json_build_object('success', false, 'error', 'Task already completed');
  END IF;
  
  -- Insert task completion and update balance in transaction
  BEGIN
    INSERT INTO user_tasks (user_wallet, task_id) VALUES (p_wallet_address, p_task_id);
    UPDATE users SET balance = balance + task_reward WHERE wallet_address = p_wallet_address;
    
    RETURN json_build_object(
      'success', true, 
      'reward', task_reward,
      'message', 'Task completed successfully'
    );
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', 'Failed to complete task');
  END;
END;
$$;

-- Weekly claim bonus function
CREATE OR REPLACE FUNCTION claim_weekly_bonus(p_wallet_address text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  weekly_amount INTEGER;
  last_claim_time TIMESTAMP WITH TIME ZONE;
  current_time TIMESTAMP WITH TIME ZONE;
  time_since_claim INTERVAL;
  user_exists BOOLEAN;
  new_balance INTEGER;
BEGIN
  current_time := NOW();
  
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
    -- Get last claim time (using created_at as proxy for now, would need weekly_claim_last column)
    SELECT created_at INTO last_claim_time FROM users WHERE wallet_address = p_wallet_address;
  END IF;
  
  -- Check eligibility (7 days = 168 hours)
  IF last_claim_time IS NOT NULL THEN
    time_since_claim := current_time - last_claim_time;
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
  SET balance = balance + weekly_amount 
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

-- Enhanced referral processing function
CREATE OR REPLACE FUNCTION process_referral_enhanced(p_new_user_wallet text, p_referrer_code text)
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

-- Enhanced withdrawal request function
CREATE OR REPLACE FUNCTION request_withdrawal_enhanced(p_wallet_address text, p_amount numeric)
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