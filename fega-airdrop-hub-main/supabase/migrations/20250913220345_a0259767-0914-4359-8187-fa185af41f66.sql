-- NUCLEAR RESET: Drop all objects and recreate cleanly
DROP TABLE IF EXISTS 
    public.withdrawals, 
    public.user_tasks, 
    public.claims,
    public.referrals,
    public.users, 
    public.tasks, 
    public.settings, 
    public.admins, 
    public.debug_log,
    public.error_logs
CASCADE;

-- Drop all conflicting functions
DROP FUNCTION IF EXISTS public.process_referral CASCADE;
DROP FUNCTION IF EXISTS public.admin_update_settings CASCADE;
DROP FUNCTION IF EXISTS public.on_new_user_referral CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_referral CASCADE;
DROP FUNCTION IF EXISTS public.process_new_user_referral CASCADE;
DROP FUNCTION IF EXISTS public.update_referral_stats CASCADE;
DROP FUNCTION IF EXISTS public.process_referral_trigger CASCADE;

-- Recreate core tables with clean schema
CREATE TABLE public.settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    referral_bonus NUMERIC DEFAULT 50,
    claim_cooldown_hours INTEGER DEFAULT 24,
    min_withdrawal NUMERIC DEFAULT 1000,
    claim_gas_fee NUMERIC DEFAULT 0.001,
    gas_fee_wallet_address TEXT DEFAULT '0x19d9Edb0D6B6635bB24062537d6478CedF6a0874',
    admin_password TEXT DEFAULT 'admin123'
);

CREATE TABLE public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_address TEXT UNIQUE NOT NULL,
    balance NUMERIC DEFAULT 0,
    referrals_count INTEGER DEFAULT 0,
    referral_earnings NUMERIC DEFAULT 0,
    referrer_id UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    reward_amount NUMERIC DEFAULT 0,
    link TEXT NOT NULL,
    type TEXT DEFAULT 'social',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.user_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    task_id UUID REFERENCES public.tasks(id),
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, task_id)
);

CREATE TABLE public.withdrawals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending',
    tx_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.debug_log (
    id BIGSERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debug_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can read settings" ON public.settings FOR SELECT USING (true);
CREATE POLICY "Service role manages settings" ON public.settings FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Anyone can read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Service role manages users" ON public.users FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Anyone can read tasks" ON public.tasks FOR SELECT USING (true);
CREATE POLICY "Service role manages tasks" ON public.tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Anyone can read user_tasks" ON public.user_tasks FOR SELECT USING (true);
CREATE POLICY "Service role manages user_tasks" ON public.user_tasks FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role manages withdrawals" ON public.withdrawals FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Anyone can read debug_log" ON public.debug_log FOR SELECT USING (true);
CREATE POLICY "Service role manages debug_log" ON public.debug_log FOR ALL USING (auth.role() = 'service_role') WITH CHECK (auth.role() = 'service_role');

-- Insert default data
INSERT INTO public.settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.tasks (name, reward_amount, link, type) VALUES 
('Follow FEGA on Twitter', 1000, 'https://twitter.com', 'social'),
('Join FEGA Telegram', 1500, 'https://telegram.org', 'social')
ON CONFLICT DO NOTHING;

-- Create the WORKING referral trigger
CREATE OR REPLACE FUNCTION public.process_referral()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bonus NUMERIC;
BEGIN
  INSERT INTO public.debug_log (message)
  VALUES ('🔥 TRIGGER FIRED: New user ' || COALESCE(NEW.wallet_address, '<null>') || ' with referrer_id ' || COALESCE(NEW.referrer_id::text, 'NULL'));

  IF NEW.referrer_id IS NOT NULL THEN
    INSERT INTO public.debug_log (message)
    VALUES ('✅ PROCESSING REFERRAL: referrer_id = ' || NEW.referrer_id::text);

    -- Get referral bonus from settings
    SELECT referral_bonus INTO v_bonus FROM public.settings WHERE id = 1;
    
    INSERT INTO public.debug_log (message)
    VALUES ('💰 REFERRAL BONUS: ' || v_bonus::text);

    -- Update referrer's stats
    UPDATE public.users
    SET 
      referrals_count = referrals_count + 1,
      referral_earnings = referral_earnings + v_bonus,
      balance = balance + v_bonus
    WHERE id = NEW.referrer_id;

    INSERT INTO public.debug_log (message)
    VALUES ('✅ REFERRER UPDATED: Added ' || v_bonus::text || ' tokens to referrer_id ' || NEW.referrer_id::text);
  ELSE
    INSERT INTO public.debug_log (message)
    VALUES ('❌ NO REFERRER: User has no referrer_id');
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_user_referral
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.process_referral();

-- TEST THE SYSTEM: Create referrer and referee
DO $$
DECLARE
  referrer_id UUID;
BEGIN
  -- Insert User A (referrer)
  INSERT INTO public.users (wallet_address) 
  VALUES ('0xAAA0000000000000000000000000000000000001')
  RETURNING id INTO referrer_id;
  
  INSERT INTO public.debug_log (message)
  VALUES ('TEST: Created User A with id ' || referrer_id::text);
  
  -- Insert User B (referred by A)
  INSERT INTO public.users (wallet_address, referrer_id) 
  VALUES ('0xBBB0000000000000000000000000000000000002', referrer_id);
  
  INSERT INTO public.debug_log (message)
  VALUES ('TEST: Created User B with referrer_id ' || referrer_id::text);
END $$;

-- Create single admin function to avoid conflicts
CREATE OR REPLACE FUNCTION public.admin_update_settings(
  p_referral_bonus NUMERIC,
  p_claim_cooldown_hours INTEGER,
  p_min_withdrawal NUMERIC
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.settings
  SET 
    referral_bonus = p_referral_bonus,
    claim_cooldown_hours = p_claim_cooldown_hours,
    min_withdrawal = p_min_withdrawal
  WHERE id = 1;
  
  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;