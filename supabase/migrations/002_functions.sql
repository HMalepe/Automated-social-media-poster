-- ============================================
-- VouchSA Database Functions
-- ============================================
-- These are reusable pieces of logic that run INSIDE the database.
-- Think of them like formulas in a spreadsheet — they do calculations
-- and updates automatically.
--
-- WHY USE FUNCTIONS?
-- Instead of writing complex logic in the app, we put it in the database.
-- This is faster, safer, and means the app code stays simple.
-- ============================================

-- ============================================
-- FUNCTION: Find nearby available pros
-- ============================================
-- Given a client's location, find all pros who are:
-- 1. Currently available (toggled ON)
-- 2. Within their stated service radius
--
-- HOW DISTANCE CALCULATION WORKS:
-- Uses the Haversine formula (fancy math that calculates distance
-- between two GPS coordinates on a sphere — the Earth).

CREATE OR REPLACE FUNCTION find_nearby_pros(
  client_lat DECIMAL,
  client_lng DECIMAL,
  max_distance_km INTEGER DEFAULT 15
)
RETURNS TABLE (
  user_id UUID,
  display_name VARCHAR,
  profile_photo_url TEXT,
  service_categories TEXT[],
  hourly_rate DECIMAL,
  vouch_count INTEGER,
  certification_status VARCHAR,
  latitude DECIMAL,
  longitude DECIMAL,
  distance_km DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS user_id,
    p.display_name,
    p.profile_photo_url,
    pp.service_categories,
    pp.hourly_rate,
    pp.vouch_count,
    pp.certification_status,
    pl.latitude,
    pl.longitude,
    -- Haversine formula to calculate distance in km
    ROUND(
      (6371 * acos(
        cos(radians(client_lat)) * cos(radians(pl.latitude)) *
        cos(radians(pl.longitude) - radians(client_lng)) +
        sin(radians(client_lat)) * sin(radians(pl.latitude))
      ))::DECIMAL, 1
    ) AS distance_km
  FROM users u
  JOIN profiles p ON p.user_id = u.id
  JOIN pro_profiles pp ON pp.user_id = u.id
  JOIN pro_locations pl ON pl.pro_id = u.id
  WHERE pp.is_available_now = TRUE          -- Only available pros
    AND u.is_banned = FALSE                 -- Not banned
    AND u.is_verified = TRUE                -- Phone verified
  HAVING
    -- Only include pros within the requested distance
    ROUND(
      (6371 * acos(
        cos(radians(client_lat)) * cos(radians(pl.latitude)) *
        cos(radians(pl.longitude) - radians(client_lng)) +
        sin(radians(client_lat)) * sin(radians(pl.latitude))
      ))::DECIMAL, 1
    ) <= LEAST(max_distance_km, pp.service_radius_km)
  ORDER BY distance_km ASC;  -- Closest first
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Calculate booking total
-- ============================================
-- Given a service price, calculates the total the client pays.
-- service_price + R10 booking fee + 10% commission = total

CREATE OR REPLACE FUNCTION calculate_booking_total(
  service_price DECIMAL,
  booking_fee DECIMAL DEFAULT 10.00,
  commission_rate DECIMAL DEFAULT 10.00
)
RETURNS TABLE (
  total_amount DECIMAL,
  pro_payout DECIMAL,
  platform_commission DECIMAL,
  fee DECIMAL
) AS $$
BEGIN
  RETURN QUERY SELECT
    ROUND(service_price + booking_fee + (service_price * commission_rate / 100), 2) AS total_amount,
    service_price AS pro_payout,
    ROUND(service_price * commission_rate / 100, 2) AS platform_commission,
    booking_fee AS fee;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Update vouch stats
-- ============================================
-- After a new vouch is created, update the pro's vouch count and rate.
-- This runs automatically (triggered by INSERT on vouches table).

CREATE OR REPLACE FUNCTION update_vouch_stats()
RETURNS TRIGGER AS $$
DECLARE
  total_bookings INTEGER;
  total_vouches INTEGER;
BEGIN
  -- Count total completed bookings for this pro
  SELECT COUNT(*) INTO total_bookings
  FROM bookings
  WHERE pro_id = NEW.vouchee_id AND status = 'completed';

  -- Count total vouches for this pro
  SELECT COUNT(*) INTO total_vouches
  FROM vouches
  WHERE vouchee_id = NEW.vouchee_id;

  -- Update the pro's profile stats
  UPDATE pro_profiles
  SET
    vouch_count = total_vouches,
    vouch_rate = CASE
      WHEN total_bookings > 0 THEN ROUND((total_vouches::DECIMAL / total_bookings) * 100, 1)
      ELSE 0
    END,
    -- Auto-upgrade certification status based on vouches
    certification_status = CASE
      WHEN total_vouches >= 25 AND (total_vouches::DECIMAL / GREATEST(total_bookings, 1)) >= 0.90
        THEN 'certified'
      WHEN total_vouches >= 10 AND (total_vouches::DECIMAL / GREATEST(total_bookings, 1)) >= 0.85
        THEN 'trusted'
      ELSE 'new'
    END
  WHERE user_id = NEW.vouchee_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: run update_vouch_stats automatically after every new vouch
CREATE TRIGGER on_new_vouch
  AFTER INSERT ON vouches
  FOR EACH ROW
  EXECUTE FUNCTION update_vouch_stats();

-- ============================================
-- FUNCTION: Update job completion stats
-- ============================================
-- When a booking is completed, update the pro's stats.

CREATE OR REPLACE FUNCTION update_job_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Only run when status changes to 'completed'
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE pro_profiles
    SET
      total_jobs_completed = total_jobs_completed + 1,
      total_earnings = total_earnings + NEW.service_price
    WHERE user_id = NEW.pro_id;

    -- Update favorite's booking count if exists
    UPDATE client_favorites
    SET
      total_bookings = total_bookings + 1,
      last_booked = NOW()
    WHERE client_id = NEW.client_id AND pro_id = NEW.pro_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_booking_completed
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_job_stats();

-- ============================================
-- FUNCTION: Auto-expire availability
-- ============================================
-- Turns off "Available Now" when available_until time is reached.
-- This would be called by a Supabase cron job (pg_cron) every minute.

CREATE OR REPLACE FUNCTION expire_availability()
RETURNS void AS $$
BEGIN
  UPDATE pro_profiles
  SET is_available_now = FALSE
  WHERE is_available_now = TRUE
    AND available_until IS NOT NULL
    AND available_until <= NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Get pro profile with stats
-- ============================================
-- Gets everything about a pro in one query (instead of multiple).
-- Used when a client taps on a pro's profile.

CREATE OR REPLACE FUNCTION get_pro_profile(pro_user_id UUID)
RETURNS TABLE (
  user_id UUID,
  display_name VARCHAR,
  bio TEXT,
  profile_photo_url TEXT,
  voice_intro_url TEXT,
  video_intro_url TEXT,
  service_categories TEXT[],
  hourly_rate DECIMAL,
  service_radius_km INTEGER,
  is_available_now BOOLEAN,
  total_jobs_completed INTEGER,
  vouch_count INTEGER,
  vouch_rate DECIMAL,
  certification_status VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    p.display_name,
    p.bio,
    p.profile_photo_url,
    p.voice_intro_url,
    p.video_intro_url,
    pp.service_categories,
    pp.hourly_rate,
    pp.service_radius_km,
    pp.is_available_now,
    pp.total_jobs_completed,
    pp.vouch_count,
    pp.vouch_rate,
    pp.certification_status
  FROM users u
  JOIN profiles p ON p.user_id = u.id
  JOIN pro_profiles pp ON pp.user_id = u.id
  WHERE u.id = pro_user_id
    AND u.is_banned = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
