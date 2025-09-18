-- Fixed weekly claim bonus function
CREATE OR REPLACE FUNCTION claim_weekly_bonus(p_wallet_address text)
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
    -- Get last claim time (using created_at as proxy for now)
    SELECT created_at INTO last_claim_time FROM users WHERE wallet_address = p_wallet_address;
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