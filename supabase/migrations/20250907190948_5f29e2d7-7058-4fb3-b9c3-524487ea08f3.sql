-- Fix the admin_update_settings function to remove demo mode and actually save settings
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  p_referral_reward NUMERIC, 
  p_claim_cooldown_hours INTEGER, 
  p_min_withdrawal NUMERIC
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Check if user is admin (using existing is_admin function)
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;
  
  -- HARD UPDATE - Direct database modification, no demo mode
  UPDATE settings SET value = p_referral_reward::TEXT WHERE key = 'referral_bonus';
  UPDATE settings SET value = p_claim_cooldown_hours::TEXT WHERE key = 'claim_cooldown_hours';  
  UPDATE settings SET value = p_min_withdrawal::TEXT WHERE key = 'min_withdrawal_amount';
  
  -- Insert if settings don't exist
  INSERT INTO settings (key, value) VALUES ('referral_bonus', p_referral_reward::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_referral_reward::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('claim_cooldown_hours', p_claim_cooldown_hours::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_claim_cooldown_hours::TEXT;
  
  INSERT INTO settings (key, value) VALUES ('min_withdrawal_amount', p_min_withdrawal::TEXT)
  ON CONFLICT (key) DO UPDATE SET value = p_min_withdrawal::TEXT;
  
  RETURN json_build_object('status', 'success', 'message', 'Settings saved.');
END;
$function$

-- Create get_withdrawal_status function for withdrawal countdown
CREATE OR REPLACE FUNCTION public.get_withdrawal_status(p_wallet_address TEXT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  next_saturday TIMESTAMP WITH TIME ZONE;
  current_time TIMESTAMP WITH TIME ZONE;
  countdown_hours INTEGER;
  is_available BOOLEAN;
BEGIN
  current_time := NOW();
  
  -- Calculate next Saturday 00:00 UTC
  next_saturday := date_trunc('week', current_time) + INTERVAL '6 days';
  
  -- If current time is past this Saturday, move to next Saturday
  IF current_time >= next_saturday THEN
    next_saturday := next_saturday + INTERVAL '7 days';
  END IF;
  
  -- Calculate countdown hours
  countdown_hours := EXTRACT(EPOCH FROM (next_saturday - current_time)) / 3600;
  
  -- Check if withdrawal is available (within 1 hour window on Saturday)
  is_available := (current_time >= next_saturday AND current_time <= next_saturday + INTERVAL '1 hour');
  
  RETURN json_build_object(
    'next_available_date', next_saturday,
    'is_available', is_available,
    'countdown_hours', FLOOR(countdown_hours)
  );
END;
$function$