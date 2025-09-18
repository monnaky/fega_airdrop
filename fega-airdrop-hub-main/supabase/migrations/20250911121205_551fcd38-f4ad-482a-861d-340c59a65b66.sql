-- Add gas fee wallet address setting
INSERT INTO settings (key, value) 
VALUES ('gas_fee_wallet', '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874')
ON CONFLICT (key) DO UPDATE SET value = '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874';

-- Create referral trigger function that fires when new user is created with referrer
CREATE OR REPLACE FUNCTION public.handle_new_user_referral()
RETURNS TRIGGER AS $$
DECLARE
  referral_bonus INTEGER;
BEGIN
  -- Only process if new user has a referrer_wallet
  IF NEW.referrer_wallet IS NOT NULL THEN
    -- Get referral bonus from settings
    SELECT value::INTEGER INTO referral_bonus 
    FROM settings WHERE key = 'referral_reward';
    
    IF referral_bonus IS NULL THEN
      referral_bonus := 50; -- Default fallback
    END IF;
    
    -- Update referrer's stats and balance
    UPDATE users 
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + referral_bonus,
      balance = balance + referral_bonus
    WHERE wallet_address = NEW.referrer_wallet;
    
    -- Create referral record
    INSERT INTO referrals (referrer_wallet, referee_wallet, reward)
    VALUES (NEW.referrer_wallet, NEW.wallet_address, referral_bonus);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger on users table
DROP TRIGGER IF EXISTS on_new_user_referral ON users;
CREATE TRIGGER on_new_user_referral
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_referral();