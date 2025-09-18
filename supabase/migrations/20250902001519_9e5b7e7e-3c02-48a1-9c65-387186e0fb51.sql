-- 02_fix_referral_system.sql - Add Referral Tracking and Automation

-- Create trigger function to update referral stats automatically
CREATE OR REPLACE FUNCTION public.update_referral_stats()
RETURNS TRIGGER
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
    
    -- Update referrer's stats
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

-- Create trigger that fires after user insert
DROP TRIGGER IF EXISTS trigger_update_referral_stats ON users;
CREATE TRIGGER trigger_update_referral_stats
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_referral_stats();

-- Create function to get referral stats for dashboard
CREATE OR REPLACE FUNCTION public.get_referral_stats(p_wallet_address TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'referrals_count', COALESCE(referrals_count, 0),
    'referral_earnings', COALESCE(referral_earnings, 0),
    'recent_referrals', (
      SELECT json_agg(
        json_build_object(
          'referee_wallet', referee_wallet,
          'reward', reward,
          'created_at', created_at
        )
      )
      FROM (
        SELECT referee_wallet, reward, created_at
        FROM referrals 
        WHERE referrer_wallet = p_wallet_address
        ORDER BY created_at DESC
        LIMIT 10
      ) recent
    )
  ) INTO result
  FROM users 
  WHERE wallet_address = p_wallet_address;
  
  RETURN COALESCE(result, json_build_object(
    'referrals_count', 0,
    'referral_earnings', 0,
    'recent_referrals', '[]'::json
  ));
END;
$$;