# FEGA AIRDROP - FULL-STACK VALIDATION CHECKLIST

## Database Reset Completed Successfully ✅
- **Status:** Database purged and reset to known good state
- **Settings loaded:** 5 core platform settings
- **Tasks loaded:** 5 sample social media tasks 
- **Error logging:** Enabled with `log_error()` function

---

## 🧪 COMPREHENSIVE TEST PROTOCOL

### 1. INITIALIZATION & WALLET CONNECTION
**Action:** Connect a wallet and verify user creation
- [ ] **Pass Criteria:** 
  - New row appears in `users` table with connected wallet address
  - UI shows balance of 0
  - No console errors during connection
- [ ] **SQL Verification:** `SELECT * FROM users WHERE wallet_address = 'YOUR_WALLET_ADDRESS';`

### 2. TASK COMPLETION & BALANCE UPDATE  
**Action:** Complete a task and verify rewards
- [ ] **Step 2a:** Click "Visit" button on any task
- [ ] **Step 2b:** Return to app and click "Complete Task"
- [ ] **Pass Criteria:**
  - `user_tasks` table shows completed entry for user/task
  - User's `balance` increases by exact task reward amount (100-200 tokens)
  - UI updates balance display in real-time
  - Success toast notification appears
- [ ] **SQL Verification:** `SELECT balance FROM users WHERE wallet_address = 'YOUR_WALLET';`

### 3. REFERRAL SYSTEM TEST (CRITICAL)
**Action:** Test referral bonus system with two wallets
- [ ] **Step 3a:** Copy referral link from User A's dashboard  
- [ ] **Step 3b:** Open incognito browser, paste link, connect different wallet (User B)
- [ ] **Step 3c:** User B completes first task to trigger referral bonus
- [ ] **Pass Criteria:**
  - User B created with `referrer_wallet` = User A's address
  - User A's `referrals_count` increases by 1
  - User A's `balance` increases by 50 tokens (referral bonus)
  - User A's `referral_earnings` increases by 50
  - Referral entry created in `referrals` table
- [ ] **SQL Verification:** 
  ```sql
  SELECT referrals_count, referral_earnings, balance FROM users WHERE wallet_address = 'USER_A_WALLET';
  SELECT * FROM referrals WHERE referrer_wallet = 'USER_A_WALLET';
  ```

### 4. DAILY CLAIM FUNCTION
**Action:** Test the daily claim button
- [ ] **Step 4a:** Click "Claim Daily Bonus" button
- [ ] **Pass Criteria:**
  - User's `balance` increases by 100 tokens (weekly_claim_amount)
  - `weekly_claim_last` timestamp updated to current time
  - Button becomes disabled with countdown timer
  - Success message displays amount claimed
- [ ] **Step 4b:** Try claiming again immediately
- [ ] **Pass Criteria:** Error message about 24-hour wait period
- [ ] **SQL Verification:** `SELECT balance, weekly_claim_last FROM users WHERE wallet_address = 'YOUR_WALLET';`

### 5. ADMIN SETTINGS UPDATE (NO DEMO MODE)
**Action:** Test admin panel settings modification
- [ ] **Step 5a:** Navigate to admin panel
- [ ] **Step 5b:** Change referral_bonus from 50 to 75 and save
- [ ] **Pass Criteria:**
  - `settings` table reflects new value: `value = '75' WHERE key = 'referral_bonus'`
  - Success message appears with "Settings permanently updated - PRODUCTION MODE"
  - **CRITICAL:** NO mention of "demo mode" anywhere
  - Changes persist after page refresh
- [ ] **SQL Verification:** `SELECT key, value FROM settings WHERE key = 'referral_bonus';`

### 6. WITHDRAWAL PROCESS
**Action:** Test token withdrawal functionality
- [ ] **Step 6a:** Ensure balance > 1000 tokens (minimum withdrawal)
- [ ] **Step 6b:** Enter withdrawal amount and submit
- [ ] **Pass Criteria:**
  - User's `balance` deducted by withdrawal amount
  - New record in `withdrawals` table with status 'pending'
  - Transaction hash displayed (simulated)
  - Remaining balance shows correctly
- [ ] **Step 6c:** Test minimum withdrawal validation
- [ ] **Pass Criteria:** Error for amounts < 1000 tokens
- [ ] **SQL Verification:** 
  ```sql
  SELECT balance FROM users WHERE wallet_address = 'YOUR_WALLET';
  SELECT * FROM withdrawals ORDER BY created_at DESC LIMIT 1;
  ```

---

## 🚨 FAILURE SCENARIOS & ERROR LOGGING

### If Any Test Fails:
1. **Check Error Logs:** `SELECT * FROM error_logs ORDER BY created_at DESC;`
2. **Verify Function Status:** All RPC functions should return JSON with `success: true/false`
3. **Console Inspection:** Check browser developer tools for JavaScript errors
4. **Database Integrity:** Run `SELECT public.validate_reset();` to verify core data

### Common Failure Points:
- **Referral System:** Most complex - check trigger function execution
- **Balance Updates:** Ensure all functions properly increment/decrement
- **Admin Panel:** Verify "demo mode" text completely eliminated
- **RLS Policies:** Ensure proper data access permissions

---

## ✅ PASS/FAIL CRITERIA SUMMARY

| Test | Critical? | Expected Result |
|------|-----------|----------------|
| Wallet Connection | Yes | User created in DB |
| Task Completion | Yes | Balance increases by task reward |
| Referral System | **CRITICAL** | Referrer gets 50 token bonus |
| Daily Claim | Yes | 100 tokens added, timer activated |
| Admin Settings | **CRITICAL** | No "demo mode", real DB updates |
| Withdrawal | Yes | Balance deducted, withdrawal logged |

**OVERALL PASS REQUIREMENT:** All 6 tests must pass with NO "demo mode" references anywhere in the system.

---

## 🔧 DEBUGGING COMMANDS

```sql
-- Reset validation
SELECT public.validate_reset();

-- Check all settings
SELECT * FROM settings;

-- View recent user activity  
SELECT u.wallet_address, u.balance, u.referrals_count, u.created_at 
FROM users u ORDER BY u.created_at DESC;

-- Check task completions
SELECT ut.*, t.name, t.reward 
FROM user_tasks ut 
JOIN tasks t ON ut.task_id = t.id 
ORDER BY ut.completed_at DESC;

-- Review error logs
SELECT * FROM error_logs ORDER BY created_at DESC LIMIT 10;
```