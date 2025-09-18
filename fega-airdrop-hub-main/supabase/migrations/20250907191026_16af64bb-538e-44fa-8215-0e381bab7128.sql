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