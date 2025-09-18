# **FINAL PRODUCTION SMOKE TEST**
## Complete System Validation Protocol

### **🎯 PRE-TEST SETUP**
**Before starting, ensure:**
- [ ] New Supabase instance is active
- [ ] All environment variables are set
- [ ] Lovable project is deployed
- [ ] Admin wallet has sufficient BNB for gas fees
- [ ] FEGA contract has tokens for distribution

---

## **TEST 1: USER REGISTRATION & WALLET CONNECTION**
**Objective**: Verify new users can register and connect wallets

### **Steps:**
1. Navigate to production URL
2. Click "Connect Wallet" 
3. Connect with MetaMask/WalletConnect
4. Verify wallet address appears in UI

### **Expected Results:**
- [ ] Wallet connects successfully
- [ ] User balance shows 0 FEGA initially
- [ ] Dashboard loads without errors

### **Database Verification:**
```sql
-- Check in new Supabase SQL Editor:
SELECT * FROM users ORDER BY created_at DESC LIMIT 1;
```
**Expected**: New row with your wallet address, balance = 0

---

## **TEST 2: TASK COMPLETION & REWARD SYSTEM**
**Objective**: Verify task completion increases user balance

### **Steps:**
1. Navigate to "Tasks" section
2. Click "Complete" on "Follow FEGA on Twitter" task
3. Confirm completion in modal
4. Check balance update in UI

### **Expected Results:**
- [ ] Task shows as "Completed" 
- [ ] Balance increases by task reward (50 FEGA)
- [ ] Success toast notification appears

### **Database Verification:**
```sql
-- Check task completion:
SELECT ut.*, t.name, t.reward 
FROM user_tasks ut 
JOIN tasks t ON ut.task_id = t.id 
ORDER BY ut.completed_at DESC LIMIT 1;

-- Check balance update:
SELECT wallet_address, balance FROM users WHERE wallet_address = 'YOUR_WALLET';
```
**Expected**: Task record exists, user balance = 50

---

## **TEST 3: REFERRAL SYSTEM**
**Objective**: Verify referral links generate rewards

### **Steps:**
1. Copy referral link from dashboard
2. Open incognito browser window
3. Visit referral link
4. Connect different wallet address
5. Complete one task with new wallet
6. Check original user's referral stats

### **Expected Results:**
- [ ] Referral link contains wallet parameter
- [ ] New user registers with referrer set
- [ ] Original user's referral count increases
- [ ] Referrer balance increases by referral bonus

### **Database Verification:**
```sql
-- Check referral relationship:
SELECT * FROM referrals ORDER BY created_at DESC LIMIT 1;

-- Check referrer reward:
SELECT wallet_address, balance, referral_count 
FROM users WHERE wallet_address = 'REFERRER_WALLET';
```
**Expected**: Referral record exists, referrer balance increased

---

## **TEST 4: DAILY CLAIM SYSTEM**
**Objective**: Verify daily bonus claims work

### **Steps:**
1. Navigate to "Claim Daily Bonus" section
2. Click "Claim Now" button
3. Wait for transaction confirmation
4. Verify 24-hour cooldown starts

### **Expected Results:**
- [ ] Claim succeeds with success message
- [ ] Balance increases by daily amount (100 FEGA)
- [ ] Timer shows next claim availability
- [ ] Second claim attempt fails with cooldown message

### **Database Verification:**
```sql
-- Check claim timestamp:
SELECT wallet_address, balance, weekly_claim_last 
FROM users WHERE wallet_address = 'YOUR_WALLET';
```
**Expected**: weekly_claim_last updated to current timestamp

---

## **TEST 5: WITHDRAWAL SYSTEM & SMART CONTRACT**
**Objective**: Verify withdrawal requests process blockchain transactions

### **Steps:**
1. Ensure balance ≥ 1000 FEGA (minimum withdrawal)
2. Navigate to "Withdraw" section
3. Enter withdrawal amount (e.g., 1000)
4. Click "Withdraw Tokens"
5. Check wallet for incoming FEGA tokens
6. Monitor transaction on BSCScan

### **Expected Results:**
- [ ] Withdrawal request accepts valid amount
- [ ] Database balance decreases immediately
- [ ] Blockchain transaction initiates
- [ ] FEGA tokens arrive in user wallet
- [ ] Transaction appears on BSCScan

### **Database Verification:**
```sql
-- Check withdrawal record:
SELECT w.*, u.wallet_address 
FROM withdrawals w 
JOIN users u ON w.user_id = u.id 
ORDER BY w.created_at DESC LIMIT 1;

-- Check balance deduction:
SELECT wallet_address, balance FROM users WHERE wallet_address = 'YOUR_WALLET';
```
**Expected**: Withdrawal record created, user balance reduced

### **Blockchain Verification:**
1. Check BSCScan for transaction hash
2. Verify FEGA contract interaction
3. Confirm token transfer to user wallet

---

## **TEST 6: ADMIN PANEL ACCESS**
**Objective**: Verify admin functions work

### **Steps:**
1. Navigate to `/admin` route
2. Login with admin credentials
3. Check user statistics
4. View withdrawal requests
5. Test settings updates

### **Expected Results:**
- [ ] Admin login succeeds
- [ ] User stats display correctly
- [ ] Withdrawal queue shows pending requests
- [ ] Settings can be updated
- [ ] Changes reflect in database

---

## **🔥 CRITICAL FAILURE SCENARIOS**
**If any test fails:**

### **Database Connection Issues:**
- Verify SUPABASE_URL is correct
- Check SUPABASE_ANON_KEY validity
- Confirm RLS policies are active

### **Blockchain Transaction Failures:**
- Verify ADMIN_PRIVATE_KEY has BNB for gas
- Check BSC_RPC_URL connectivity
- Confirm FEGA_CONTRACT_ADDRESS is correct

### **Authentication Problems:**
- Clear browser cache and cookies
- Try different wallet (MetaMask vs WalletConnect)
- Check browser console for errors

---

## **✅ SUCCESS CRITERIA**
**All systems operational when:**
- [ ] User registration: 100% success rate
- [ ] Task completion: Rewards credited instantly
- [ ] Referrals: Bonuses distributed automatically
- [ ] Daily claims: 24h cooldown enforced
- [ ] Withdrawals: Tokens delivered within 5 minutes
- [ ] Admin panel: Full functionality accessible

**🚀 PRODUCTION READY**: Only proceed to public launch when ALL tests pass

**⚠️ ROLLBACK TRIGGER**: If >50% of tests fail, revert to previous configuration and investigate

**📊 MONITORING**: Continue running these tests daily during launch week