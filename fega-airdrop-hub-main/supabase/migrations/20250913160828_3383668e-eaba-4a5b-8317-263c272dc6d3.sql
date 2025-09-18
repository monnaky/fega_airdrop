-- 1) CLEAR EVERYTHING AND SEED MINIMUM DATA (schema-aligned)
-- Truncate data-heavy tables and reset identities
TRUNCATE TABLE public.withdrawals, public.user_tasks, public.claims, public.referrals, public.users, public.tasks, public.settings, public.admins RESTART IDENTITY CASCADE;

-- Seed settings using key-value pairs expected by existing functions
INSERT INTO public.settings (key, value) VALUES
  ('referral_bonus', '50'),
  ('referral_reward', '50'), -- fallback key used in some functions
  ('claim_cooldown', '24'),
  ('min_withdrawal_amount', '1000'),
  ('claim_gas_fee', '0.001'),
  ('gas_fee_wallet_address', '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874');

-- Seed two starter tasks (align to columns: name, type, link, reward)
INSERT INTO public.tasks (name, type, link, reward) VALUES
  ('Follow FEGA on Twitter', 'social', 'https://twitter.com', 1000),
  ('Join FEGA Telegram', 'social', 'https://telegram.org', 1500);

-- 2) DEBUG LOG TABLE + POLICIES
CREATE TABLE IF NOT EXISTS public.debug_log (
  id BIGSERIAL PRIMARY KEY,
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.debug_log ENABLE ROW LEVEL SECURITY;

-- Anyone can read debug log for verification
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'debug_log' AND policyname = 'Anyone can read debug_log'
  ) THEN
    CREATE POLICY "Anyone can read debug_log" ON public.debug_log
    FOR SELECT USING (true);
  END IF;
END $$;

-- Service role can manage (optional)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'debug_log' AND policyname = 'Service role can manage debug_log'
  ) THEN
    CREATE POLICY "Service role can manage debug_log" ON public.debug_log
    FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');
  END IF;
END $$;

-- 3) RECREATE REFERRAL TRIGGER WITH LOGGING (schema uses referrer_wallet)
DROP TRIGGER IF EXISTS on_user_referral ON public.users;

CREATE OR REPLACE FUNCTION public.process_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bonus INTEGER;
BEGIN
  INSERT INTO public.debug_log (message)
  VALUES ('Trigger fired for new user: ' || COALESCE(NEW.wallet_address, '<null>'));

  IF NEW.referrer_wallet IS NOT NULL THEN
    INSERT INTO public.debug_log (message)
    VALUES ('User has referrer_wallet: ' || NEW.referrer_wallet);

    -- Load referral bonus (prefer 'referral_bonus', fallback to 'referral_reward', default 50)
    SELECT COALESCE(
      (SELECT value::INTEGER FROM public.settings WHERE key = 'referral_bonus' LIMIT 1),
      (SELECT value::INTEGER FROM public.settings WHERE key = 'referral_reward' LIMIT 1),
      50
    ) INTO v_bonus;

    UPDATE public.users
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + v_bonus,
      balance = balance + v_bonus
    WHERE wallet_address = NEW.referrer_wallet;

    INSERT INTO public.debug_log (message)
    VALUES ('Referrer stats updated for wallet: ' || NEW.referrer_wallet || ' with bonus ' || v_bonus::text);
  ELSE
    INSERT INTO public.debug_log (message)
    VALUES ('No referrer found for new user.');
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_user_referral
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.process_referral();

-- 4) TEST: simulate referral (User A refers User B)
INSERT INTO public.users (wallet_address) VALUES ('0xAAA0000000000000000000000000000000000001');
INSERT INTO public.users (wallet_address, referrer_wallet) VALUES ('0xBBB0000000000000000000000000000000000002', '0xAAA0000000000000000000000000000000000001');
