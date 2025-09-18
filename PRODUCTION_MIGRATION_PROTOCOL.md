# 🚨 PRODUCTION MIGRATION & SMOKE TEST PROTOCOL
## Complete System Overhaul - Final Production Deployment

### **STEP 1: CREATE NEW SUPABASE PROJECT**
1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. **Project name:** `fega-airdrop-production-final`
4. **Pricing:** **PRO PLAN ($25/month)** - MANDATORY for production traffic
5. **Region:** US East (Ohio) or EU West (Ireland)
6. Generate strong password and **SAVE IT SECURELY**
7. Click "Create new project"
8. **WAIT** until status shows "Active" (5-10 minutes)

### **STEP 2: EXECUTE FINAL SQL BUNDLE**
1. In new Supabase project → "SQL Editor"
2. Click "New query" 
3. Copy **ENTIRE** contents of `fega_airdrop_final_bundle.sql`
4. Paste and click "Run"
5. **VERIFY:** Check "Table Editor" - must see 8 tables
6. **VERIFY:** Functions created (admin_update_settings, claim_daily_bonus, etc.)

### **STEP 3: UPDATE LOVABLE SECRETS**
**CRITICAL:** Replace ALL Supabase credentials in Lovable project:
```
SUPABASE_URL = https://[NEW-PROJECT-REF].supabase.co
SUPABASE_ANON_KEY = eyJ[NEW-ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY = eyJ[NEW-SERVICE-ROLE-KEY] 
```

### **STEP 4: SMOKE TESTS - EXECUTE IN ORDER**

#### **TEST 1: Admin Settings (Eliminate Demo Mode)**
1. Navigate to `/admin` in production app
2. Login with admin credentials  
3. Update settings:
   - Weekly Claim Amount: 150
   - Referral Bonus: 75
   - Min Withdrawal: 500
4. Click "Save"
5. **VERIFY:** Success message shows "Settings permanently updated - PRODUCTION MODE"
6. **DATABASE CHECK:** Run in Supabase SQL Editor:
   ```sql
   SELECT key, value FROM settings WHERE key IN ('weekly_claim_amount', 'referral_bonus', 'min_withdrawal_amount');
   ```
   **EXPECTED:** Values should be 150, 75, 500 (NOT demo mode placeholders)

#### **TEST 2: Referral System (Database Triggers)**
1. Copy referral link from dashboard: `https://[app-url]/?ref=[WALLET_ADDRESS]`
2. Open incognito browser window
3. Visit referral link and connect different wallet
4. **IMMEDIATE DATABASE CHECK:** Run in Supabase SQL Editor:
   ```sql
   SELECT wallet_address, referrals_count, referral_earnings, balance 
   FROM users WHERE wallet_address = '[REFERRER_WALLET]';
   ```
   **EXPECTED:** `referrals_count = 1`, `referral_earnings = 75`, `balance` increased by 75
5. **VERIFY:** `referrals` table has new entry:
   ```sql  
   SELECT * FROM referrals ORDER BY created_at DESC LIMIT 1;
   ```

#### **TEST 3: Daily Claim System**
1. Navigate to "Daily Claim" section
2. Click "Claim 100 FEGA"
3. **VERIFY:** Success message shows "Daily bonus claimed successfully - PRODUCTION MODE"
4. **DATABASE CHECK:**
   ```sql
   SELECT wallet_address, balance, weekly_claim_last 
   FROM users WHERE wallet_address = '[USER_WALLET]';
   ```
   **EXPECTED:** Balance increased by 150 (from settings), `weekly_claim_last` updated
5. **VERIFY:** Second claim attempt shows "Must wait 24 hours"

#### **TEST 4: Production Data Integrity**
1. **User Count Check:**
   ```sql
   SELECT COUNT(*) as total_users FROM users;
   ```
2. **Settings Integrity:**
   ```sql
   SELECT * FROM settings ORDER BY key;
   ```
3. **Referrals Functioning:**
   ```sql
   SELECT COUNT(*) as total_referrals FROM referrals;
   ```
4. **No Demo Mode Remnants:**
   Search all function responses for "demo" - MUST return 0 results

### **STEP 5: PRODUCTION FAILURE SCENARIOS**
**If ANY test fails:**

#### **Scenario A: Database Connection Issues**
- Verify `SUPABASE_URL` format: `https://[project-ref].supabase.co`
- Check `SUPABASE_ANON_KEY` validity (starts with `eyJ`)
- Confirm RLS policies active in Table Editor

#### **Scenario B: Function Errors**
- Check Supabase Function logs for errors
- Verify all database functions exist:
  ```sql
  SELECT proname FROM pg_proc WHERE pronamespace = 'public'::regnamespace;
  ```

#### **Scenario C: Demo Mode Still Appears**
- **ROLLBACK IMMEDIATELY** 
- Re-run SQL bundle from scratch
- Verify functions replaced (not updated)

### **✅ SUCCESS CRITERIA - ALL MUST PASS**
- [ ] Admin settings update with "PRODUCTION MODE" message
- [ ] Referrals trigger automatically (database increase)  
- [ ] Claims modify database balance (not localStorage)
- [ ] NO "demo mode" text anywhere in application
- [ ] Database functions return production messages
- [ ] All triggers firing correctly

### **🚀 PRODUCTION LAUNCH CHECKLIST**
- [ ] All smoke tests passed 100%
- [ ] Demo mode completely eliminated
- [ ] Database triggers operational
- [ ] Admin functions working
- [ ] Production environment variables set
- [ ] Error logging enabled

**ESTIMATED MIGRATION TIME:** 45-60 minutes
**ZERO TOLERANCE:** Any demo mode detection = immediate rollback