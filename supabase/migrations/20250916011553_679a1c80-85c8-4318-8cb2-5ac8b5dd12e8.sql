-- 1. Remove the broken trigger and function
DROP TRIGGER IF EXISTS on_user_referral ON users CASCADE;
DROP FUNCTION IF EXISTS process_referral() CASCADE;

-- 2. Create a new, foolproof function
CREATE OR REPLACE FUNCTION process_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the new user has a referrer ID
  IF NEW.referrer_id IS NOT NULL THEN
    -- Update the referrer's stats: add 1 to count and add bonus to balance
    UPDATE users 
    SET 
        referrals_count = referrals_count + 1,
        referral_earnings = referral_earnings + (SELECT referral_bonus FROM settings WHERE id = 1),
        balance = balance + (SELECT referral_bonus FROM settings WHERE id = 1)
    WHERE id = NEW.referrer_id;
  END IF;
  RETURN NEW;
END;
$$;

-- 3. Create the trigger to fire AFTER a new user is inserted
CREATE TRIGGER on_user_referral
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION process_referral();