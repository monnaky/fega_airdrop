-- Fix the get_settings function to return correct field names for frontend
CREATE OR REPLACE FUNCTION public.get_settings()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  result JSON;
BEGIN
  -- Return settings with field names that match frontend expectations
  SELECT json_build_object(
    'referral_reward', referral_bonus,
    'claim_cooldown', claim_cooldown_hours,
    'min_withdrawal_amount', min_withdrawal,
    'claim_gas_fee', claim_gas_fee,
    'gas_fee_wallet', gas_fee_wallet_address
  ) INTO result
  FROM settings 
  WHERE id = 1;
  
  RETURN COALESCE(result, json_build_object(
    'referral_reward', 50,
    'claim_cooldown', 24,
    'min_withdrawal_amount', 1000,
    'claim_gas_fee', 0.001,
    'gas_fee_wallet', '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874'
  ));
END;
$function$;