@@ .. @@
 -- Drop existing policies if they exist
 DROP POLICY IF EXISTS "Users can read own profile" ON users;
 DROP POLICY IF EXISTS "Users can update own profile" ON users;
 DROP POLICY IF EXISTS "Admin full access users" ON users;
 DROP POLICY IF EXISTS "Users can view all profiles" ON users;
 DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
 DROP POLICY IF EXISTS "Users can update their own profile" ON users;
+DROP POLICY IF EXISTS "Users can view own profile" ON users;
+DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
 
--- Create new user policies
-CREATE POLICY "Users can view own profile"
-ON users FOR SELECT
-USING (wallet_address = (auth.uid())::text);
-
-CREATE POLICY "Users can update own profile"
-ON users FOR UPDATE
-USING (wallet_address = (auth.uid())::text)
-WITH CHECK (wallet_address = (auth.uid())::text);
-
-CREATE POLICY "Users can insert their own profile"
-ON users FOR INSERT
-WITH CHECK (wallet_address = (auth.uid())::text);
+-- Create new user policies - prevent direct client access, use RPC functions instead
+CREATE POLICY "No direct user select on profiles"
+ON users FOR SELECT
+USING (false);
+
+CREATE POLICY "No direct user insert on profiles"
+ON users FOR INSERT
+WITH CHECK (false);
+
+CREATE POLICY "No direct user update on profiles"
+ON users FOR UPDATE
+USING (false)
+WITH CHECK (false);
 
 CREATE POLICY "Service role has full access to users"
 ON users FOR ALL
 USING (auth.role() = 'service_role')
 WITH CHECK (auth.role() = 'service_role');