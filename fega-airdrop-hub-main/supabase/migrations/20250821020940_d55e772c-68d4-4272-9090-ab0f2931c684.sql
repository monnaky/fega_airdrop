-- Enable RLS on all tables and create proper policies

-- TASKS table policies
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public read on tasks" ON tasks;
DROP POLICY IF EXISTS "Allow service_role insert on tasks" ON tasks;
DROP POLICY IF EXISTS "Allow service_role update on tasks" ON tasks;
DROP POLICY IF EXISTS "Allow service_role delete on tasks" ON tasks;
DROP POLICY IF EXISTS "Tasks are viewable by everyone" ON tasks;

-- Create new task policies
CREATE POLICY "Users can only view tasks"
ON tasks FOR SELECT
USING (true);

CREATE POLICY "Only service_role can manage tasks"
ON tasks FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- USERS table policies  
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admin full access users" ON users;
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;

-- Create new user policies
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (wallet_address = (auth.uid())::text);

CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (wallet_address = (auth.uid())::text)
WITH CHECK (wallet_address = (auth.uid())::text);

CREATE POLICY "Users can insert their own profile"
ON users FOR INSERT
WITH CHECK (wallet_address = (auth.uid())::text);

CREATE POLICY "Service role has full access to users"
ON users FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- USER_TASKS table policies
ALTER TABLE user_tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own task progress" ON user_tasks;
DROP POLICY IF EXISTS "Users can insert own task progress" ON user_tasks;
DROP POLICY IF EXISTS "Admin full access user_tasks" ON user_tasks;
DROP POLICY IF EXISTS "Users can view all task completions" ON user_tasks;
DROP POLICY IF EXISTS "Users can create task completions" ON user_tasks;

-- Create new user_tasks policies
CREATE POLICY "Users can insert their own task"
ON user_tasks FOR INSERT
WITH CHECK (user_wallet = (auth.uid())::text);

CREATE POLICY "Users can view their own tasks"
ON user_tasks FOR SELECT
USING (user_wallet = (auth.uid())::text);

CREATE POLICY "Users can update their own task"
ON user_tasks FOR UPDATE
USING (user_wallet = (auth.uid())::text)
WITH CHECK (user_wallet = (auth.uid())::text);

CREATE POLICY "Service role has full access to user_tasks"
ON user_tasks FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- REFERRALS table policies
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own referrals" ON referrals;
DROP POLICY IF EXISTS "Admin full access referrals" ON referrals;
DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
DROP POLICY IF EXISTS "Referrals can be created" ON referrals;

-- Create new referral policies
CREATE POLICY "Users can view their own referrals"
ON referrals FOR SELECT
USING (referrer_wallet = (auth.uid())::text OR referee_wallet = (auth.uid())::text);

CREATE POLICY "Users can create referrals"
ON referrals FOR INSERT
WITH CHECK (true);

CREATE POLICY "Service role has full access to referrals"
ON referrals FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');