-- ============================================
-- VouchSA Database Schema
-- ============================================
-- This file creates all the database tables for VouchSA.
--
-- HOW TO USE THIS:
-- 1. Go to your Supabase dashboard (app.supabase.com)
-- 2. Click "SQL Editor" in the left sidebar
-- 3. Paste this entire file
-- 4. Click "Run"
--
-- WHAT IS A TABLE?
-- Think of a table like a spreadsheet. Each table stores one type of thing
-- (users, bookings, vouches, etc). Each row is one record. Each column is
-- one piece of information about that record.
--
-- WHAT IS A UUID?
-- A unique ID that looks like: 550e8400-e29b-41d4-a716-446655440000
-- It's generated automatically so every record has a unique identifier.
--
-- WHAT IS A FOREIGN KEY (REFERENCES)?
-- It's a link between tables. For example, a booking REFERENCES a user,
-- meaning it stores the user's ID to connect the booking to that user.
-- ============================================

-- Enable the UUID extension (needed to auto-generate unique IDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for geographic/location queries (distance calculations)
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- USERS & AUTHENTICATION
-- ============================================
-- This is the core user table. Every person who uses VouchSA has a row here.
-- Whether they're a service provider (pro) or a client, they start here.

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- Unique ID, auto-generated
  phone_number VARCHAR(15) UNIQUE NOT NULL,         -- SA phone number (e.g., +27821234567)
  id_number_hash VARCHAR(255),                      -- SA ID number, encrypted for security
  user_type VARCHAR(20) NOT NULL                    -- 'pro', 'client', or 'both'
    CHECK (user_type IN ('pro', 'client', 'both')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),-- When they signed up
  last_active TIMESTAMP WITH TIME ZONE,             -- Last time they used the app
  is_verified BOOLEAN DEFAULT FALSE,                -- Have they verified their phone?
  is_banned BOOLEAN DEFAULT FALSE                   -- Has admin banned them?
);

-- ============================================
-- PROFILES
-- ============================================
-- Extra info about the user: name, photo, bio, etc.
-- Separated from users table to keep things organized.
-- Every user has exactly one profile (one-to-one relationship).

CREATE TABLE profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name VARCHAR(100) NOT NULL,               -- The name shown in the app
  bio TEXT,                                         -- Short description about themselves
  profile_photo_url TEXT,                           -- Link to their profile photo in storage
  voice_intro_url TEXT,                             -- 30-second audio intro (trust builder!)
  video_intro_url TEXT,                             -- Alternative: 30-second video intro
  address TEXT,                                     -- For clients: their home address
  latitude DECIMAL(10, 8),                          -- GPS latitude of home address
  longitude DECIMAL(11, 8),                         -- GPS longitude of home address
  emergency_contact_phone VARCHAR(15),              -- Who to alert during a job
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PRO-SPECIFIC DATA
-- ============================================
-- Extra data only for service providers.
-- Stores their services, pricing, availability, earnings, etc.

CREATE TABLE pro_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  service_categories TEXT[],                        -- Array like ['barber', 'nail_tech']
  hourly_rate DECIMAL(10, 2),                       -- Default hourly rate in Rands
  service_radius_km INTEGER DEFAULT 10,             -- How far they'll travel (in km)

  -- Bank details for payouts
  bank_account_number VARCHAR(50),
  bank_name VARCHAR(100),
  bank_branch_code VARCHAR(20),

  -- Availability
  is_available_now BOOLEAN DEFAULT FALSE,           -- The "Available Now" toggle
  available_until TIMESTAMP WITH TIME ZONE,         -- Auto-toggle off at this time

  -- Stats (updated automatically)
  total_jobs_completed INTEGER DEFAULT 0,
  total_earnings DECIMAL(10, 2) DEFAULT 0,
  vouch_count INTEGER DEFAULT 0,
  vouch_rate DECIMAL(5, 2) DEFAULT 0,               -- Percentage of jobs that got vouched

  -- Trust level
  certification_status VARCHAR(20) DEFAULT 'new'
    CHECK (certification_status IN ('new', 'trusted', 'certified')),

  -- Subscription (Phase 3, but column ready)
  subscription_tier VARCHAR(20) DEFAULT 'free'
    CHECK (subscription_tier IN ('free', 'pro_plus')),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PRO SERVICES (The Menu)
-- ============================================
-- Each pro lists their specific services with prices.
-- Example: "Men's Haircut - 45 min - R150"
-- A pro can have many services (one-to-many relationship).

CREATE TABLE pro_services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_name VARCHAR(100) NOT NULL,               -- e.g., "Men's Haircut"
  description TEXT,                                 -- e.g., "Includes wash and style"
  duration_minutes INTEGER NOT NULL,                -- How long it takes
  price DECIMAL(10, 2) NOT NULL,                    -- Price in Rands
  is_active BOOLEAN DEFAULT TRUE,                   -- Can be turned off without deleting
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PRO PORTFOLIO (Work Samples)
-- ============================================
-- Photos of their work. Clients can verify photos after a job.

CREATE TABLE pro_portfolio (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,                          -- Link to image in storage
  caption TEXT,                                     -- Description of the work
  is_verified BOOLEAN DEFAULT FALSE,                -- Has a client confirmed this is real?
  verified_by_client_id UUID REFERENCES users(id),  -- Which client verified it
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PRO AVAILABILITY SCHEDULE
-- ============================================
-- Recurring weekly schedule. Example: "Every Monday 9am-5pm"
-- This is separate from the "Available Now" toggle.

CREATE TABLE pro_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 1=Monday, etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_recurring BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- LOCATION TRACKING
-- ============================================
-- Stores the CURRENT location of each pro.
-- Updated every 30 seconds when they're "Available Now".
-- Only one row per pro (UNIQUE constraint) — it gets updated, not inserted.

CREATE TABLE pro_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(10, 2),                          -- GPS accuracy in meters
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Only one location per pro (gets updated, not duplicated)
  CONSTRAINT unique_pro_location UNIQUE (pro_id)
);

-- Index for fast location lookups (finding nearby pros)
CREATE INDEX idx_pro_locations_coords ON pro_locations(latitude, longitude);

-- ============================================
-- BOOKINGS & JOBS
-- ============================================
-- The heart of the app. Every time a client books a pro, a row is created here.
-- Tracks the entire lifecycle: pending -> accepted -> in_progress -> completed

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES users(id) ON DELETE SET NULL,
  pro_id UUID REFERENCES users(id) ON DELETE SET NULL,
  service_id UUID REFERENCES pro_services(id),

  -- Booking type: "instant" (Book Now) or "scheduled" (pick a date/time)
  booking_type VARCHAR(20) CHECK (booking_type IN ('instant', 'scheduled')),

  -- Status tracks where the job is in its lifecycle
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed')),

  -- Where the service happens
  service_address TEXT NOT NULL,
  service_latitude DECIMAL(10, 8),
  service_longitude DECIMAL(11, 8),

  -- When the service happens
  scheduled_start TIMESTAMP WITH TIME ZONE,         -- For scheduled bookings
  actual_start TIMESTAMP WITH TIME ZONE,            -- When pro tapped "Start Job"
  actual_end TIMESTAMP WITH TIME ZONE,              -- When pro tapped "Complete Job"
  duration_minutes INTEGER,                         -- Actual duration

  -- Money
  service_price DECIMAL(10, 2) NOT NULL,            -- The pro's price
  booking_fee DECIMAL(10, 2) DEFAULT 10.00,         -- R10 flat fee
  commission_rate DECIMAL(5, 2) DEFAULT 10.00,      -- 10% commission
  total_amount DECIMAL(10, 2) NOT NULL,             -- What client pays in total

  -- Notes
  client_notes TEXT,                                -- Special requests

  -- Safety features
  emergency_contact_notified BOOLEAN DEFAULT FALSE,
  tracking_link_sent BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fast lookups (finding bookings by client, pro, or status)
CREATE INDEX idx_bookings_client ON bookings(client_id);
CREATE INDEX idx_bookings_pro ON bookings(pro_id);
CREATE INDEX idx_bookings_status ON bookings(status);

-- ============================================
-- VOUCHES (The Trust System - Your Competitive Advantage!)
-- ============================================
-- After a job, the client can "vouch" for the pro.
-- This is NOT a star rating — it's a binary endorsement ("I trust this person").
-- This is what makes VouchSA different from Gumtree or Facebook groups.

CREATE TABLE vouches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  voucher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- Client who vouches
  vouchee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- Pro being vouched for
  booking_id UUID REFERENCES bookings(id),          -- Which job this vouch is for

  vouch_text TEXT,                                  -- Optional comment with the vouch
  is_public BOOLEAN DEFAULT TRUE,                   -- Show on pro's profile?

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- One vouch per booking (can't vouch twice for the same job)
  CONSTRAINT unique_vouch_per_booking UNIQUE (voucher_id, booking_id)
);

CREATE INDEX idx_vouches_vouchee ON vouches(vouchee_id);

-- ============================================
-- PAYMENTS & TRANSACTIONS
-- ============================================
-- Tracks every money movement: authorization, capture, payout, refund.
-- Connected to bookings — every booking generates transactions.

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID REFERENCES bookings(id),

  -- What type of money movement
  transaction_type VARCHAR(20)
    CHECK (transaction_type IN ('authorization', 'capture', 'payout', 'refund')),

  amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),

  -- Reference to the payment provider (Yoco/PayFast)
  payment_provider VARCHAR(50),
  payment_provider_ref TEXT,                        -- Their transaction ID

  pro_payout_amount DECIMAL(10, 2),                 -- What the pro gets (90%)
  commission_amount DECIMAL(10, 2),                 -- What VouchSA keeps (10%)

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- PRO PAYOUTS
-- ============================================
-- When a pro requests their earnings to be sent to their bank account.

CREATE TABLE pro_payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  amount DECIMAL(10, 2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

  bank_account_number VARCHAR(50),
  payment_reference TEXT,

  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- CHAT / MESSAGING
-- ============================================
-- Simple text chat between client and pro, tied to a booking.
-- Auto-expires 48 hours after job completion for privacy.

CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id),
  pro_id UUID NOT NULL REFERENCES users(id),

  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMP WITH TIME ZONE,              -- 48hrs after job ends

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),

  message_text TEXT NOT NULL,                       -- Text only (no photos for safety)
  is_read BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);

-- ============================================
-- FAVORITES ("My Pros")
-- ============================================
-- Clients save their favorite pros for easy rebooking.

CREATE TABLE client_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pro_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_booked TIMESTAMP WITH TIME ZONE,
  total_bookings INTEGER DEFAULT 0,                 -- How many times they've booked this pro

  CONSTRAINT unique_favorite UNIQUE (client_id, pro_id)
);

-- ============================================
-- NOTIFICATIONS
-- ============================================
-- In-app notifications (separate from push notifications).
-- Push notifications are sent via Firebase Cloud Messaging.
-- This table stores the notification so users can see history.

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  notification_type VARCHAR(50) NOT NULL,            -- 'new_booking', 'job_completed', etc.
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,

  related_booking_id UUID REFERENCES bookings(id),
  action_url TEXT,                                  -- Deep link to app screen

  is_read BOOLEAN DEFAULT FALSE,
  is_pushed BOOLEAN DEFAULT FALSE,                  -- Has push notification been sent?

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);

-- ============================================
-- REPORTS & MODERATION
-- ============================================
-- When something goes wrong: safety concerns, fraud, bad behavior.

CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  reported_user_id UUID NOT NULL REFERENCES users(id),
  booking_id UUID REFERENCES bookings(id),

  report_type VARCHAR(50),                          -- 'safety_concern', 'fraud', etc.
  description TEXT NOT NULL,

  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),

  admin_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ANALYTICS EVENTS
-- ============================================
-- Tracks what users do in the app (for understanding usage patterns).
-- JSONB is a flexible format that can store any key-value data.

CREATE TABLE app_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),

  event_type VARCHAR(100) NOT NULL,                 -- 'profile_viewed', 'booking_created'
  event_data JSONB,                                 -- Flexible metadata

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_app_events_type ON app_events(event_type);
CREATE INDEX idx_app_events_user ON app_events(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
-- This is Supabase's way of protecting data.
-- It means: "Users can only see/edit THEIR OWN data"
-- Without this, anyone could read anyone's data!

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE vouches ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_events ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================
-- These rules define WHO can do WHAT with each table.

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Profiles are publicly readable (so clients can see pro profiles)
CREATE POLICY "Profiles are publicly readable" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile data" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Pro profiles are publicly readable
CREATE POLICY "Pro profiles are publicly readable" ON pro_profiles
  FOR SELECT USING (true);

CREATE POLICY "Pros can update own pro profile" ON pro_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Pros can insert own pro profile" ON pro_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Pro services are publicly readable
CREATE POLICY "Pro services are publicly readable" ON pro_services
  FOR SELECT USING (true);

CREATE POLICY "Pros can manage own services" ON pro_services
  FOR ALL USING (auth.uid() = pro_id);

-- Pro locations are publicly readable (for the map)
CREATE POLICY "Pro locations are publicly readable" ON pro_locations
  FOR SELECT USING (true);

CREATE POLICY "Pros can update own location" ON pro_locations
  FOR ALL USING (auth.uid() = pro_id);

-- Bookings: both client and pro can view their own bookings
CREATE POLICY "Users can view own bookings" ON bookings
  FOR SELECT USING (auth.uid() = client_id OR auth.uid() = pro_id);

CREATE POLICY "Clients can create bookings" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Booking participants can update" ON bookings
  FOR UPDATE USING (auth.uid() = client_id OR auth.uid() = pro_id);

-- Vouches are publicly readable (trust is public!)
CREATE POLICY "Vouches are publicly readable" ON vouches
  FOR SELECT USING (true);

CREATE POLICY "Clients can create vouches" ON vouches
  FOR INSERT WITH CHECK (auth.uid() = voucher_id);

-- Notifications: users see only their own
CREATE POLICY "Users see own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Messages: only conversation participants can see
CREATE POLICY "Conversation participants can view messages" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND (conversations.client_id = auth.uid() OR conversations.pro_id = auth.uid())
    )
  );

CREATE POLICY "Conversation participants can send messages" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Favorites: users manage their own
CREATE POLICY "Users manage own favorites" ON client_favorites
  FOR ALL USING (auth.uid() = client_id);

-- Portfolio: publicly readable, pros manage their own
CREATE POLICY "Portfolio is publicly readable" ON pro_portfolio
  FOR SELECT USING (true);

CREATE POLICY "Pros manage own portfolio" ON pro_portfolio
  FOR ALL USING (auth.uid() = pro_id);

-- Pro availability: publicly readable, pros manage their own
CREATE POLICY "Availability is publicly readable" ON pro_availability
  FOR SELECT USING (true);

CREATE POLICY "Pros manage own availability" ON pro_availability
  FOR ALL USING (auth.uid() = pro_id);

-- Conversations: participants only
CREATE POLICY "Conversation participants can view" ON conversations
  FOR SELECT USING (auth.uid() = client_id OR auth.uid() = pro_id);

-- Transactions: booking participants can view
CREATE POLICY "Booking participants can view transactions" ON transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = transactions.booking_id
      AND (bookings.client_id = auth.uid() OR bookings.pro_id = auth.uid())
    )
  );

-- Payouts: pros see their own
CREATE POLICY "Pros see own payouts" ON pro_payouts
  FOR SELECT USING (auth.uid() = pro_id);

CREATE POLICY "Pros can request payouts" ON pro_payouts
  FOR INSERT WITH CHECK (auth.uid() = pro_id);

-- Reports: users can create, only see their own
CREATE POLICY "Users can create reports" ON reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports" ON reports
  FOR SELECT USING (auth.uid() = reporter_id);
