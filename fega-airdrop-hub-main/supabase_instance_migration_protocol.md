# **SUPABASE INSTANCE MIGRATION PROTOCOL**
## Critical Steps to Bypass Database Limits

### **STEP 1: CREATE NEW SUPABASE PROJECT**
1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Choose organization: Select your organization
4. Project name: `fega-airdrop-production`
5. Database password: Generate a strong password (save it securely)
6. Region: Choose closest to your users (recommend US East or EU West)
7. Pricing plan: **Select Pro Plan** ($25/month) - Critical for production traffic
8. Click "Create new project"
9. **WAIT** for initialization (5-10 minutes) - Do NOT proceed until status shows "Active"

### **STEP 2: EXECUTE DATABASE BUNDLE**
1. In your NEW Supabase project, go to "SQL Editor"
2. Click "New query"
3. Copy the ENTIRE contents of `fega_airdrop_final_bundle.sql` 
4. Paste into the SQL Editor
5. Click "Run" (this may take 2-3 minutes)
6. Verify success: Check for green "Success" message
7. **CRITICAL**: Verify tables exist by going to "Table Editor" - you should see 8 tables

### **STEP 3: GET NEW PROJECT CREDENTIALS**
1. In your new project, go to "Settings" > "API"
2. Copy these values:
   - **Project URL** (format: `https://[project-ref].supabase.co`)
   - **anon public key** (starts with `eyJ...`)
   - **service_role key** (starts with `eyJ...` - KEEP SECRET!)

### **STEP 4: UPDATE LOVABLE PROJECT SECRETS**
**CRITICAL**: In your Lovable project, update these secrets:
1. `SUPABASE_URL` = Your new Project URL
2. `SUPABASE_ANON_KEY` = Your new anon public key
3. `SUPABASE_SERVICE_ROLE_KEY` = Your new service_role key (if used in edge functions)

### **STEP 5: UPDATE CLIENT CONFIGURATION**
Update `src/integrations/supabase/client.ts`:
```typescript
const SUPABASE_URL = "YOUR_NEW_PROJECT_URL";
const SUPABASE_PUBLISHABLE_KEY = "YOUR_NEW_ANON_KEY";
```

### **STEP 6: VERIFICATION CHECKLIST**
- [ ] New project shows "Active" status
- [ ] All 8 tables created successfully 
- [ ] Settings table has 7 default entries
- [ ] Tasks table has 5 default tasks
- [ ] All RLS policies are active
- [ ] Lovable project connects without errors
- [ ] Test wallet connection works

### **MIGRATION ROLLBACK PLAN**
If issues occur:
1. Keep old project credentials backed up
2. Revert Lovable secrets to old values
3. Debug new instance separately
4. Only switch when 100% confident

### **POST-MIGRATION MONITORING**
- Monitor Supabase dashboard for errors
- Check edge function logs for connectivity
- Verify user registrations work
- Test all core functions (tasks, referrals, withdrawals)

**ESTIMATED MIGRATION TIME**: 30-45 minutes
**DOWNTIME WINDOW**: 5-10 minutes (during credential swap)