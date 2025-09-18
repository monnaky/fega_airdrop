import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-api-key',
};

const handler = async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify admin API key
    const adminApiKey = req.headers.get('x-admin-api-key');
    const expectedAdminKey = Deno.env.get('ADMIN_API_KEY');
    
    if (!adminApiKey || adminApiKey !== expectedAdminKey) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }), 
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { action } = await req.json();

    if (action === 'cleanup') {
      // Clean up all user data while preserving schema
      const results = {
        task_completions: 0,
        claims: 0,
        referrals: 0,
        profiles: 0
      };

      // Delete task completions
      const { count: taskCount } = await supabase
        .from('user_tasks')
        .delete()
        .neq('id', 'placeholder'); // Delete all records
      results.task_completions = taskCount || 0;

      // Delete claims
      const { count: claimCount } = await supabase
        .from('claims')
        .delete()
        .neq('id', 'placeholder');
      results.claims = claimCount || 0;

      // Delete referrals
      const { count: referralCount } = await supabase
        .from('referrals')
        .delete()
        .neq('id', 'placeholder');
      results.referrals = referralCount || 0;

      // Delete users (profiles)
      const { count: profileCount } = await supabase
        .from('users')
        .delete()
        .neq('id', 'placeholder');
      results.profiles = profileCount || 0;

      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Database cleanup completed',
          results 
        }),
        { 
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    } else {
      return new Response(
        JSON.stringify({ error: 'Invalid action' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

  } catch (error) {
    console.error('Database cleanup error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
};

serve(handler);