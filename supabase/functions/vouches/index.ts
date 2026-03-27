// ============================================
// VouchSA - Vouch System Edge Functions
// ============================================
//
// The vouch system is VouchSA's competitive advantage.
// Unlike star ratings (which everyone ignores), a vouch is a
// binary endorsement: "I trust this person with my home."
//
// This is what makes VouchSA different from Gumtree, Facebook
// Marketplace, or any other platform.
// ============================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const url = new URL(req.url);
    const path = url.pathname.split("/").filter(Boolean);
    const action = path[1] || "";

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();

    if (!user) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ============================================
    // POST /vouches - Create a vouch
    // ============================================
    // Client vouches for a pro after a completed job.
    // Body: { booking_id, vouch_text? }
    //
    // Note: "Not this time" option simply means the client
    // doesn't call this endpoint. No negative consequence.
    if (req.method === "POST" && !action) {
      const { booking_id, vouch_text } = await req.json();

      // Verify the booking exists and belongs to this client
      const { data: booking, error: bookingError } = await supabaseClient
        .from("bookings")
        .select("*")
        .eq("id", booking_id)
        .eq("client_id", user.id)
        .eq("status", "completed")
        .single();

      if (bookingError || !booking) {
        return new Response(
          JSON.stringify({
            error: "Booking not found or not completed yet",
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Create the vouch
      // The database trigger (update_vouch_stats) will automatically
      // update the pro's vouch count, rate, and certification status
      const { data: vouch, error: vouchError } = await supabaseClient
        .from("vouches")
        .insert({
          voucher_id: user.id,
          vouchee_id: booking.pro_id,
          booking_id,
          vouch_text: vouch_text || null,
          is_public: true,
        })
        .select()
        .single();

      if (vouchError) {
        // Check if it's a duplicate vouch
        if (vouchError.code === "23505") {
          return new Response(
            JSON.stringify({
              error: "You've already vouched for this booking",
            }),
            {
              status: 409,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
        throw vouchError;
      }

      return new Response(
        JSON.stringify({
          success: true,
          vouch,
          message: "Thank you for vouching! This helps build trust in your community.",
        }),
        {
          status: 201,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ============================================
    // GET /vouches/pro/:id - Get vouches for a pro
    // ============================================
    // Returns public vouches with voucher info.
    // Includes proximity data if client's location is provided.
    if (req.method === "GET" && action === "pro") {
      const proId = path[2];
      const clientLat = parseFloat(url.searchParams.get("lat") || "0");
      const clientLng = parseFloat(url.searchParams.get("lng") || "0");
      const page = parseInt(url.searchParams.get("page") || "1");
      const limit = parseInt(url.searchParams.get("limit") || "20");
      const offset = (page - 1) * limit;

      // Get vouches with voucher's profile info
      const { data: vouches, error, count } = await supabaseClient
        .from("vouches")
        .select(
          `
          id,
          vouch_text,
          created_at,
          voucher:voucher_id (
            user_id,
            display_name,
            profile_photo_url,
            latitude,
            longitude
          )
        `,
          { count: "exact" }
        )
        .eq("vouchee_id", proId)
        .eq("is_public", true)
        .order("created_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) throw error;

      // If client provided their location, calculate distance to each voucher
      // This powers: "Vouched by Sarah L. (0.4km from you)"
      const vouchesWithDistance = (vouches || []).map((vouch: any) => {
        let distance_km = null;
        if (
          clientLat !== 0 &&
          clientLng !== 0 &&
          vouch.voucher?.latitude &&
          vouch.voucher?.longitude
        ) {
          // Haversine formula (same as in database function)
          const R = 6371;
          const dLat = ((vouch.voucher.latitude - clientLat) * Math.PI) / 180;
          const dLng = ((vouch.voucher.longitude - clientLng) * Math.PI) / 180;
          const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos((clientLat * Math.PI) / 180) *
              Math.cos((vouch.voucher.latitude * Math.PI) / 180) *
              Math.sin(dLng / 2) *
              Math.sin(dLng / 2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          distance_km = Math.round(R * c * 10) / 10;
        }

        return {
          id: vouch.id,
          vouch_text: vouch.vouch_text,
          created_at: vouch.created_at,
          voucher_name: vouch.voucher?.display_name,
          voucher_photo: vouch.voucher?.profile_photo_url,
          distance_km, // null if location not provided
        };
      });

      return new Response(
        JSON.stringify({
          vouches: vouchesWithDistance,
          total: count,
          page,
          limit,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify({ error: "Not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
