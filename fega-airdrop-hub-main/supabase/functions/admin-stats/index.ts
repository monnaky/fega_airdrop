import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Use service role key for admin operations to bypass RLS
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

  // Get total users
  const { count: totalUsers } = await supabaseClient
    .from('users')
    .select('*', { count: 'exact', head: true })

  // Get total tokens distributed using SUM aggregation
  const { data: tokenSumData } = await supabaseClient
    .rpc('exec_sql', { sql: 'SELECT COALESCE(SUM(balance), 0) as total FROM users' })

  const totalTokensDistributed = tokenSumData?.total || 0

    // Get total referrals - sum of referrals_count from users table
    const { data: referralData } = await supabaseClient
      .from('users')
      .select('referrals_count')
    
    const totalReferrals = referralData?.reduce((sum, user) => sum + (user.referrals_count || 0), 0) || 0

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          total_users: totalUsers || 0,
          total_tokens_distributed: totalTokensDistributed,
          total_referrals: totalReferrals || 0
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error fetching admin stats:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})