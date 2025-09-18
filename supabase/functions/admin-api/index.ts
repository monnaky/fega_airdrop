import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.53.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const adminKey = Deno.env.get('ADMIN_API_KEY')!;

    // Verify admin key
    const adminKeyHeader = req.headers.get('x-admin-key');
    if (!adminKeyHeader || adminKeyHeader !== adminKey) {
      console.log('❌ Unauthorized admin access attempt');
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Create admin client with service role key
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);
    console.log('✅ Admin client initialized with service_role key');

    const { action, data } = await req.json();
    console.log(`🔍 Admin API called with action: ${action}`);

    switch (action) {
      case 'getTasks': {
        const { data: tasks, error } = await supabase
          .from('tasks')
          .select('*')
          .order('created_at', { ascending: false });
          
        if (error) throw error;
        console.log(`✅ Fetched ${tasks?.length || 0} tasks`);
        
        return new Response(
          JSON.stringify({ success: true, data: tasks }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'createTask': {
        const { name, link, reward, type } = data;
        const { data: task, error } = await supabase
          .from('tasks')
          .insert({
            name,
            link,
            reward_amount: parseInt(reward),
            type
          })
          .select()
          .single();
          
        if (error) throw error;
        console.log('✅ Task created successfully:', task.id);
        
        return new Response(
          JSON.stringify({ success: true, data: task }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'updateTask': {
        const { id, name, link, reward, type } = data;
        const { data: task, error } = await supabase
          .from('tasks')
          .update({
            name,
            link,
            reward_amount: parseInt(reward),
            type
          })
          .eq('id', id)
          .select()
          .single();
          
        if (error) throw error;
        console.log('✅ Task updated successfully:', id);
        
        return new Response(
          JSON.stringify({ success: true, data: task }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'deleteTask': {
        const { id } = data;
        const { error } = await supabase
          .from('tasks')
          .delete()
          .eq('id', id);
          
        if (error) throw error;
        console.log('✅ Task deleted successfully:', id);
        
        return new Response(
          JSON.stringify({ success: true }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'getUsers': {
        const { data: users, error } = await supabase
          .from('users')
          .select('*')
          .order('created_at', { ascending: false });
          
        if (error) throw error;
        console.log(`✅ Fetched ${users?.length || 0} users`);
        
        return new Response(
          JSON.stringify({ success: true, data: users }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'getStats': {
        // Get total users
        const { count: totalUsers, error: usersError } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true });
          
        if (usersError) throw usersError;

        // Get total tokens distributed
        const { data: usersWithBalances, error: balanceError } = await supabase
          .from('users')
          .select('balance');
          
        if (balanceError) throw balanceError;
        
        const totalTokens = usersWithBalances?.reduce((sum, user) => sum + (user.balance || 0), 0) || 0;

        // Get total referrals - sum of referrals_count from users table
        const { data: referralData, error: referralsError } = await supabase
          .from('users')
          .select('referrals_count');
          
        if (referralsError) throw referralsError;
        
        const totalReferrals = referralData?.reduce((sum, user) => sum + (user.referrals_count || 0), 0) || 0;

        const stats = {
          total_users: totalUsers || 0,
          total_tokens_distributed: totalTokens,
          total_referrals: totalReferrals || 0
        };
        
        console.log('✅ Stats fetched successfully:', stats);
        
        return new Response(
          JSON.stringify({ success: true, data: stats }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'resetData': {
        // Reset all user data but keep tasks
        await supabase.from('user_tasks').delete().neq('id', '00000000-0000-0000-0000-000000000000');
        await supabase.from('referrals').delete().neq('id', '00000000-0000-0000-0000-000000000000');
        await supabase.from('users').update({ balance: 0 }).neq('id', '00000000-0000-0000-0000-000000000000');
        
        console.log('✅ Data reset successfully');
        
        return new Response(
          JSON.stringify({ success: true, message: 'Data reset successfully' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ success: false, error: `Unknown action: ${action}` }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
    }
  } catch (error) {
    console.error('❌ Admin API error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
