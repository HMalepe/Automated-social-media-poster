// ============================================
// VouchSA - Pro Management Edge Functions
// ============================================
//
// WHAT IS AN EDGE FUNCTION?
// It's code that runs on Supabase's servers (not on the user's phone).
// When the app needs to do something (like find nearby pros), it sends
// a request to this function, which talks to the database and sends
// back the result.
//
// WHY NOT JUST TALK TO THE DATABASE DIRECTLY?
// Some operations need extra logic (like calculating distances,
// sending notifications, or validating data). Edge Functions handle
// that logic in a secure place.
//
// LANGUAGE: TypeScript (Deno runtime)
// This runs on Supabase's servers using Deno (a JavaScript runtime).
// ============================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Standard response headers (allows the app to talk to this function)
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight requests (browser security thing)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Create a connection to Supabase using the request's auth token
    // This means the function runs as the logged-in user (respects RLS policies)
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Parse the URL to determine which action to perform
    const url = new URL(req.url);
    const path = url.pathname.split("/").filter(Boolean);
    // path looks like: ["pros", "available"] or ["pros", "toggle-availability"]

    const action = path[1] || ""; // The second part of the URL

    // ============================================
    // GET /pros/available - Find nearby available pros
    // ============================================
    // Called when a client opens the map.
    // Requires: latitude, longitude as query parameters
    // Returns: List of available pros sorted by distance
    if (req.method === "GET" && action === "available") {
      const lat = parseFloat(url.searchParams.get("lat") || "0");
      const lng = parseFloat(url.searchParams.get("lng") || "0");
      const maxDistance = parseInt(
        url.searchParams.get("max_distance") || "15"
      );

      // Validate that we got real coordinates
      if (lat === 0 || lng === 0) {
        return new Response(
          JSON.stringify({ error: "latitude and longitude are required" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Call our database function that finds nearby pros
      const { data, error } = await supabaseClient.rpc("find_nearby_pros", {
        client_lat: lat,
        client_lng: lng,
        max_distance_km: maxDistance,
      });

      if (error) throw error;

      return new Response(JSON.stringify({ pros: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ============================================
    // GET /pros/:id - Get a specific pro's profile
    // ============================================
    // Called when a client taps on a pro's pin or profile.
    if (req.method === "GET" && action && action !== "available") {
      const proId = action; // The pro's user ID

      // Get the full pro profile using our database function
      const { data, error } = await supabaseClient.rpc("get_pro_profile", {
        pro_user_id: proId,
      });

      if (error) throw error;

      if (!data || data.length === 0) {
        return new Response(
          JSON.stringify({ error: "Pro not found" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Also fetch their services menu
      const { data: services } = await supabaseClient
        .from("pro_services")
        .select("*")
        .eq("pro_id", proId)
        .eq("is_active", true);

      // And their portfolio images
      const { data: portfolio } = await supabaseClient
        .from("pro_portfolio")
        .select("*")
        .eq("pro_id", proId)
        .order("created_at", { ascending: false });

      // And their vouches
      const { data: vouches } = await supabaseClient
        .from("vouches")
        .select(
          `
          id,
          vouch_text,
          created_at,
          voucher:voucher_id (
            display_name,
            profile_photo_url
          )
        `
        )
        .eq("vouchee_id", proId)
        .eq("is_public", true)
        .order("created_at", { ascending: false })
        .limit(20);

      return new Response(
        JSON.stringify({
          profile: data[0],
          services: services || [],
          portfolio: portfolio || [],
          vouches: vouches || [],
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ============================================
    // POST /pros/toggle-availability
    // ============================================
    // Called when a pro taps the "Available Now" toggle.
    // Body: { is_available: true/false, available_until?: "2024-01-15T17:00:00" }
    if (req.method === "POST" && action === "toggle-availability") {
      const { is_available, available_until } = await req.json();

      // Get the current user's ID
      const {
        data: { user },
      } = await supabaseClient.auth.getUser();

      if (!user) {
        return new Response(
          JSON.stringify({ error: "Not authenticated" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Update their availability
      const { error } = await supabaseClient
        .from("pro_profiles")
        .update({
          is_available_now: is_available,
          available_until: available_until || null,
        })
        .eq("user_id", user.id);

      if (error) throw error;

      return new Response(
        JSON.stringify({
          success: true,
          is_available,
          message: is_available
            ? "You are now visible on the map!"
            : "You are now hidden from the map.",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ============================================
    // PUT /pros/location - Update pro's GPS location
    // ============================================
    // Called every 30 seconds when a pro is "Available Now".
    // Body: { latitude: -26.1234, longitude: 28.0456, accuracy: 10.5 }
    if (req.method === "PUT" && action === "location") {
      const { latitude, longitude, accuracy } = await req.json();

      const {
        data: { user },
      } = await supabaseClient.auth.getUser();

      if (!user) {
        return new Response(
          JSON.stringify({ error: "Not authenticated" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Upsert = Update if exists, Insert if doesn't
      // This means we always have ONE location per pro (not a history)
      const { error } = await supabaseClient.from("pro_locations").upsert(
        {
          pro_id: user.id,
          latitude,
          longitude,
          accuracy,
          last_updated: new Date().toISOString(),
        },
        { onConflict: "pro_id" }
      );

      if (error) throw error;

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // If we get here, the URL didn't match any of our handlers
    return new Response(JSON.stringify({ error: "Not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    // Something went wrong — return the error
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
