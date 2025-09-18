-- Drop existing trigger and function if present
DROP TRIGGER IF EXISTS on_user_referral ON public.users;
DROP FUNCTION IF EXISTS public.process_referral_trigger();

-- Create a simple, reliable trigger function aligned with current schema
CREATE OR REPLACE FUNCTION public.process_referral_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bonus INTEGER;
BEGIN
  -- If the new user has a referrer wallet, credit the referrer
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Load referral bonus from settings (prefer 'referral_bonus', fallback to 'referral_reward', default 50)
    SELECT COALESCE(
      (SELECT value::INTEGER FROM settings WHERE key = 'referral_bonus' LIMIT 1),
      (SELECT value::INTEGER FROM settings WHERE key = 'referral_reward' LIMIT 1),
      50
    ) INTO v_bonus;

    UPDATE users
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + v_bonus,
      balance = balance + v_bonus
    WHERE wallet_address = NEW.referrer_wallet;
  END IF;
  RETURN NEW;
END;
$$;

-- Create the trigger to fire after insert on users
CREATE TRIGGER on_user_referral
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.process_referral_trigger();

-- Manual test: insert a referrer (User A) and a referred user (User B)
INSERT INTO public.users (wallet_address) VALUES ('0xabcde0000000000000000000000000000000001');
INSERT INTO public.users (wallet_address, referrer_wallet) VALUES ('0xabcde0000000000000000000000000000000002', '0xabcde0000000000000000000000000000000001');