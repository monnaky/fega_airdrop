# **FINAL ENVIRONMENT VARIABLES CHECKLIST**
## Complete Production Setup Requirements

### **🔒 SUPABASE CREDENTIALS** (CRITICAL - New Instance)
- [ ] `SUPABASE_URL` 
  - **Format**: `https://[your-new-project-ref].supabase.co`
  - **Source**: New Supabase project Settings > API
  - **Required for**: Database connections, auth, all backend operations

- [ ] `SUPABASE_ANON_KEY`
  - **Format**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
  - **Source**: New Supabase project Settings > API > anon public
  - **Required for**: Frontend database calls, user auth

- [ ] `SUPABASE_SERVICE_ROLE_KEY`
  - **Format**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
  - **Source**: New Supabase project Settings > API > service_role
  - **Required for**: Edge functions with admin privileges
  - **⚠️ CRITICAL**: Keep this secret! Full database access

### **⛓️ BLOCKCHAIN INTEGRATION** (Production Smart Contracts)
- [ ] `ADMIN_PRIVATE_KEY`
  - **Format**: `0x1234567890abcdef...` (64 character hex)
  - **Source**: Your funded admin wallet private key
  - **Required for**: Signing withdrawal transactions
  - **⚠️ ULTRA-CRITICAL**: Never expose! Contains real funds

- [ ] `BSC_RPC_URL`
  - **Recommended**: `https://bsc-dataseed1.binance.org`
  - **Alternatives**: 
    - `https://bsc-dataseed2.binance.org`
    - `https://bsc-dataseed3.binance.org`
  - **Required for**: Blockchain transaction submission

- [ ] `FEGA_CONTRACT_ADDRESS`
  - **Production**: `0x53f0d9770e97618EFE053A3Ec8A9cf30c736C090`
  - **Network**: Binance Smart Chain (BSC)
  - **Required for**: Token transfer operations

### **📧 EMAIL NOTIFICATIONS** (Optional but Recommended)
- [ ] `RESEND_API_KEY`
  - **Format**: `re_xxxxxxxxxx`
  - **Source**: Resend.com dashboard
  - **Required for**: Admin withdrawal notifications
  - **Note**: Optional - withdrawals work without email

### **🛡️ SECURITY & ADMIN**
- [ ] `ADMIN_API_KEY`
  - **Format**: Custom secure string (32+ characters)
  - **Purpose**: Admin panel authentication
  - **Required for**: Admin dashboard access

### **✅ VALIDATION CHECKLIST**
Before going live, verify ALL secrets are:
- [ ] Set in Lovable project secrets (not in code)
- [ ] Using production values (not test/demo)
- [ ] Properly formatted (no extra spaces/characters)
- [ ] Working (test each integration)

### **🚨 SECURITY REMINDERS**
- **NEVER** commit private keys to code
- **NEVER** share service role keys
- **ALWAYS** use HTTPS endpoints
- **REGULARLY** rotate API keys
- **MONITOR** for unauthorized usage

### **📊 POST-SETUP VERIFICATION**
Test each secret:
1. **Database**: Can connect and query users table
2. **Blockchain**: Can read FEGA contract balance
3. **Admin**: Can access withdrawal processing
4. **Email**: Can send test notification (if enabled)

**TOTAL REQUIRED SECRETS**: 5 critical, 2 optional
**SETUP TIME**: 15-20 minutes
**VALIDATION TIME**: 10-15 minutes