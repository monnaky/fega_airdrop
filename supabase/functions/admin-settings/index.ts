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

    if (req.method === 'GET') {
      // Get current settings
      const { data: settings } = await supabaseClient
        .from('admin_settings')
        .select('setting_key, setting_value')

      const settingsMap = settings?.reduce((acc, setting) => {
        acc[setting.setting_key] = setting.setting_value
        return acc
      }, {} as Record<string, string>) || {}

      return new Response(
        JSON.stringify({
          success: true,
          data: {
            referral_bonus: settingsMap.referral_bonus || '50',
            claim_cooldown_hours: settingsMap.claim_cooldown_hours || '24'
          }
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      )
    }

    if (req.method === 'POST') {
      const { setting_key, setting_value } = await req.json()

      // Update or insert setting
      const { error } = await supabaseClient
        .from('admin_settings')
        .upsert(
          { setting_key, setting_value },
          { onConflict: 'setting_key' }
        )

      if (error) {
        throw error
      }

      return new Response(
        JSON.stringify({ success: true, message: 'Setting updated successfully' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      )
    }

    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 405,
      },
    )
  } catch (error) {
    console.error('Error handling admin settings:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})