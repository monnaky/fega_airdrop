// Supabase client separation for proper RLS enforcement
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/integrations/supabase/types';

const SUPABASE_URL = "https://idcfieikxrcopimxfxup.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkY2ZpZWlreHJjb3BpbXhmeHVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNjA4NDQsImV4cCI6MjA2OTkzNjg0NH0.8lUZwNVtb6iPmTxKcugofYLDVTyE4DB3Bqca76mAOwQ";
const SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkY2ZpZWlreHJjb3BpbXhmeHVwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDM2MDg0NCwiZXhwIjoyMDY5OTM2ODQ0fQ.4UMNZPOls1r_pnGv-EMJlRDDFGJ_gCZqGSgJoJOQ_HY";

// User client - anon key for normal user operations with RLS enforcement
export const supabaseUser = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});

// Admin client - service role key bypasses RLS for admin operations
// ⚠️ CRITICAL: This should ONLY be used server-side or in admin-only contexts
export const supabaseAdmin = createClient<Database>(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: false,
    autoRefreshToken: false,
  }
});

// Debug function to get client type for logging
export const getClientType = (isAdmin: boolean) => {
  return isAdmin ? 'service_role' : 'anon';
};

// Helper function to validate admin access
export const validateAdminAccess = () => {
  const adminKey = localStorage.getItem('isAdmin');
  return adminKey === 'true';
};

// Admin API client - calls backend with service_role key
export const adminAPI = {
  async callAdminFunction(action: string, data?: any) {
    const adminKey = 'fegaadmin@11111'; // Admin key for secure backend access
    
    try {
      const response = await fetch(`https://idcfieikxrcopimxfxup.supabase.co/functions/v1/admin-api`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': adminKey,
        },
        body: JSON.stringify({ action, data }),
      });

      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.error || `HTTP ${response.status}`);
      }

      return result;
    } catch (error) {
      console.error(`❌ Admin API call failed (${action}):`, error);
      throw error;
    }
  },

  // Convenience methods
  async getTasks() {
    return this.callAdminFunction('getTasks');
  },

  async createTask(taskData: any) {
    return this.callAdminFunction('createTask', taskData);
  },

  async updateTask(taskData: any) {
    return this.callAdminFunction('updateTask', taskData);
  },

  async deleteTask(id: string) {
    return this.callAdminFunction('deleteTask', { id });
  },

  async getUsers() {
    return this.callAdminFunction('getUsers');
  },

  async getStats() {
    return this.callAdminFunction('getStats');
  },

  async resetData() {
    return this.callAdminFunction('resetData');
  }
};