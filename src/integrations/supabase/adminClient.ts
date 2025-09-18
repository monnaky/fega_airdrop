// Supabase client separation for proper RLS enforcement
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = "https://idcfieikxrcopimxfxup.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkY2ZpZWlreHJjb3BpbXhmeHVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNjA4NDQsImV4cCI6MjA2OTkzNjg0NH0.8lUZwNVtb6iPmTxKcugofYLDVTyE4DB3Bqca76mAOwQ";
const SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkY2ZpZWlreHJjb3BpbXhmeHVwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDM2MDg0NCwiZXhwIjoyMDY5OTM2ODQ0fQ.4UMNZPOls1r_pnGv-EMJlRDDFGJ_gCZqGSgJoJOQ_HY";

// User client - anon key for normal user operations with RLS
export const supabaseUser = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});

// Admin client - service role key bypasses RLS for admin operations
export const supabaseAdmin = createClient<Database>(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: false,
    autoRefreshToken: false,
  }
});

// Debug function to get client type
export const getClientType = (isAdmin: boolean) => {
  return isAdmin ? 'service_role' : 'anon';
};