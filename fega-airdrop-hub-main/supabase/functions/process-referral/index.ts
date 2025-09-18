import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { referrerId, userId } = await req.json();
    
    if (!referrerId || !userId) {
      return new Response(
        JSON.stringify({ error: 'Missing referrerId or userId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('Processing referral:', { referrerId, userId });

    // Get referrer profile by user_id (handle both full ID and shortened ID)
    let { data: referrerProfile, error: referrerError } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', referrerId)
      .single();

    // If not found with full ID, try to find by matching partial ID
    if (referrerError && referrerError.code === 'PGRST116') {
      const { data: profiles, error: searchError } = await supabase
        .from('profiles')
        .select('*')
        .like('user_id', `${referrerId}%`)
        .limit(1);
      
      if (!searchError && profiles && profiles.length > 0) {
        referrerProfile = profiles[0];
        referrerError = null;
      }
    }

    if (referrerError || !referrerProfile) {
      console.error('Referrer not found:', referrerError);
      return new Response(
        JSON.stringify({ error: 'Referrer not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get or create referred user profile
    let { data: referredProfile, error: referredError } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    // Create profile if it doesn't exist
    if (referredError && referredError.code === 'PGRST116') {
      const { data: newProfile, error: createError } = await supabase
        .from('profiles')
        .insert({
          user_id: userId,
          wallet_address: userId, // Temporary fallback
          referred_by: referrerProfile.id
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating profile:', createError);
        return new Response(
          JSON.stringify({ error: 'Failed to create user profile' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      referredProfile = newProfile;
    } else if (referredError) {
      console.error('Error fetching referred profile:', referredError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch user profile' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if user already has a referrer
    if (referredProfile.referred_by) {
      console.log('User already has a referrer');
      return new Response(
        JSON.stringify({ message: 'User already has a referrer' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate referral creation using our secure function
    const { data: isValid, error: validationError } = await supabase
      .rpc('validate_referral_creation', {
        p_referrer_id: referrerProfile.id,
        p_referred_id: referredProfile.id
      });

    if (validationError || !isValid) {
      console.error('Referral validation failed:', validationError);
      return new Response(
        JSON.stringify({ error: 'Invalid referral' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Update referred user's profile to include referrer
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ referred_by: referrerProfile.id })
      .eq('id', referredProfile.id);

    if (updateError) {
      console.error('Error updating profile:', updateError);
      return new Response(
        JSON.stringify({ error: 'Failed to update profile' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create referral record
    const { error: referralError } = await supabase
      .from('referrals')
      .insert({
        referrer_id: referrerProfile.id,
        referred_id: referredProfile.id,
        tokens_earned: 50
      });

    if (referralError) {
      console.error('Error creating referral:', referralError);
      return new Response(
        JSON.stringify({ error: 'Failed to create referral record' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Update referrer's stats
    const { error: statsError } = await supabase
      .from('profiles')
      .update({
        referral_count: referrerProfile.referral_count + 1,
        total_tokens_earned: referrerProfile.total_tokens_earned + 50
      })
      .eq('id', referrerProfile.id);

    if (statsError) {
      console.error('Error updating referrer stats:', statsError);
    }

    console.log('Referral processed successfully');
    return new Response(
      JSON.stringify({ success: true, message: 'Referral processed successfully' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in process-referral function:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});