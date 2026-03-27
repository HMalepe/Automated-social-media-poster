// ============================================
// VouchSA Auth Edge Function
// ============================================
// Handles phone authentication with OTP via Twilio.
//
// ENDPOINTS:
// POST /auth/send-otp    - Send OTP to phone number
// POST /auth/verify-otp  - Verify OTP code
// POST /auth/register    - Create user profile after verification
//
// EXTERNAL SERVICE: Twilio (for SMS)
// ============================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const body = await req.json();

    // Create Supabase admin client (for operations that bypass RLS)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // ============================================
    // SEND OTP
    // ============================================
    // Uses Supabase's built-in phone auth (which uses Twilio under the hood).
    // You configure Twilio in: Supabase Dashboard → Authentication → Providers → Phone
    if (url.pathname.endsWith('/send-otp')) {
      const { phone } = body;

      if (!phone || !phone.startsWith('+27')) {
        return new Response(
          JSON.stringify({ error: 'Valid SA phone number required (+27...)' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      // Supabase handles OTP generation and Twilio SMS delivery
      const { error } = await supabaseAdmin.auth.signInWithOtp({
        phone: phone,
      });

      if (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      return new Response(
        JSON.stringify({ message: 'OTP sent successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ============================================
    // VERIFY OTP
    // ============================================
    // Checks if the code the user entered matches.
    // If valid, returns a session (JWT token) for the user.
    if (url.pathname.endsWith('/verify-otp')) {
      const { phone, code } = body;

      if (!phone || !code) {
        return new Response(
          JSON.stringify({ error: 'Phone and code required' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const { data, error } = await supabaseAdmin.auth.verifyOtp({
        phone: phone,
        token: code,
        type: 'sms',
      });

      if (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      // Check if user already has a profile (existing user vs new signup)
      const userId = data.user?.id;
      let isNewUser = false;

      if (userId) {
        const { data: profile } = await supabaseAdmin
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

        isNewUser = !profile;
      }

      return new Response(
        JSON.stringify({
          session: data.session,
          user: data.user,
          isNewUser: isNewUser,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ============================================
    // REGISTER (Create Profile)
    // ============================================
    // After OTP verification, new users set up their profile.
    if (url.pathname.endsWith('/register')) {
      const authHeader = req.headers.get('Authorization');
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: 'Authorization required' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      // Verify the user's JWT token
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: authHeader } } },
      );

      const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: 'Invalid token' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const { displayName, userType, bio } = body;

      // Create user record
      await supabaseAdmin.from('users').upsert({
        id: user.id,
        phone_number: user.phone,
        user_type: userType || 'client',
        is_verified: true,
      });

      // Create profile
      await supabaseAdmin.from('profiles').upsert({
        user_id: user.id,
        display_name: displayName,
        bio: bio || null,
      });

      // If pro, create pro profile
      if (userType === 'pro' || userType === 'both') {
        await supabaseAdmin.from('pro_profiles').upsert({
          user_id: user.id,
          service_categories: [],
          is_available_now: false,
        });
      }

      return new Response(
        JSON.stringify({ message: 'Profile created', userId: user.id }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ error: 'Unknown endpoint' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
