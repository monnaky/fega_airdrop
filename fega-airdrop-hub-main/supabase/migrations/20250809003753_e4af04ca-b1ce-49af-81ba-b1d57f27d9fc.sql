BEGIN;

-- PROFILES policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;

CREATE POLICY "Profiles are viewable by everyone"
ON public.profiles FOR SELECT TO public
USING (true);

CREATE POLICY "Anyone can insert profiles"
ON public.profiles FOR INSERT TO public
WITH CHECK (true);

CREATE POLICY "Anyone can update profiles"
ON public.profiles FOR UPDATE TO public
USING (true) WITH CHECK (true);

-- Unique index for wallet address
CREATE UNIQUE INDEX IF NOT EXISTS profiles_wallet_address_unique ON public.profiles (lower(wallet_address));

-- TASK_COMPLETIONS
DROP POLICY IF EXISTS "Users can insert their own task completions" ON public.task_completions;
DROP POLICY IF EXISTS "Users can view their own task completions" ON public.task_completions;

CREATE POLICY "Task completions are viewable by everyone"
ON public.task_completions FOR SELECT TO public
USING (true);

CREATE POLICY "Anyone can insert task completions"
ON public.task_completions FOR INSERT TO public
WITH CHECK (true);

-- Unique to prevent duplicate same-day completions
CREATE UNIQUE INDEX IF NOT EXISTS task_completions_unique_per_day ON public.task_completions (user_id, task_id, completion_date);

-- CLAIMS
DROP POLICY IF EXISTS "Users can insert their own claims" ON public.claims;
DROP POLICY IF EXISTS "Users can view their own claims" ON public.claims;

CREATE POLICY "Claims are viewable by everyone"
ON public.claims FOR SELECT TO public
USING (true);

CREATE POLICY "Anyone can insert claims"
ON public.claims FOR INSERT TO public
WITH CHECK (true);

-- REFERRALS
DROP POLICY IF EXISTS "Users can insert referrals" ON public.referrals;
DROP POLICY IF EXISTS "Users can view their referrals" ON public.referrals;

CREATE POLICY "Referrals are viewable by everyone"
ON public.referrals FOR SELECT TO public
USING (true);

CREATE POLICY "Anyone can insert referrals"
ON public.referrals FOR INSERT TO public
WITH CHECK (true);

-- Unique to prevent duplicate referral pairs
CREATE UNIQUE INDEX IF NOT EXISTS referrals_unique_pair ON public.referrals (referrer_id, referred_id);

COMMIT;