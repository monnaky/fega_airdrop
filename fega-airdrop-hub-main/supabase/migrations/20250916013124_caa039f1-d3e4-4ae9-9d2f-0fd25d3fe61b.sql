-- FORCE CREATE TRIGGER - Previous attempts failed silently
-- Using different approach to ensure trigger creation

-- Drop existing items
DROP TRIGGER IF EXISTS on_user_referral ON users;
DROP FUNCTION IF EXISTS process_referral();

-- Create function with explicit search path  
CREATE OR REPLACE FUNCTION process_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  referral_bonus_amount INTEGER;
BEGIN
  -- Check if the new user has a referrer ID
  IF NEW.referrer_id IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT referral_bonus INTO referral_bonus_amount FROM settings WHERE id = 1;
    IF referral_bonus_amount IS NULL THEN
      referral_bonus_amount := 50;  -- fallback
    END IF;

    -- Update the referrer's stats
    UPDATE users 
    SET 
        referrals_count = referrals_count + 1,
        referral_earnings = referral_earnings + referral_bonus_amount,
        balance = balance + referral_bonus_amount
    WHERE id = NEW.referrer_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Force trigger creation
CREATE TRIGGER on_user_referral
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION process_referral();