# VouchSA MVP Roadmap

## What is VouchSA?
A hyper-local, trust-based marketplace connecting suburban residents in South Africa
with mobile service professionals (barbers, nail techs, gardeners, cleaners, handymen).

Think "Uber for Services" built for South African suburbs, with social proof ("vouches")
at its core.

---

## MVP Scope (Phase 1 Only)

We are building ONLY the following features for launch. Everything else waits.

### Sprint 1: Foundation (Weeks 1-2)
- [ ] Set up Supabase project (database, auth, storage)
- [ ] Create database tables (users, profiles, pro_profiles, pro_services)
- [ ] Phone number registration with OTP
- [ ] Basic user profile creation (name, photo, user type)
- [ ] Pro profile creation (services, pricing, service radius)

### Sprint 2: The Map (Weeks 3-4)
- [ ] Google Maps integration in Flutter
- [ ] Pro availability toggle (Available Now / Unavailable)
- [ ] GPS location tracking for available pros
- [ ] Display pro pins on map (color-coded by category)
- [ ] Tap pin to see pro preview card

### Sprint 3: Booking (Weeks 5-6)
- [ ] "Book Now" instant booking flow
- [ ] "Schedule Booking" advance booking flow
- [ ] Booking notifications (push + SMS fallback)
- [ ] Job lifecycle (Start Job -> Complete Job)
- [ ] In-app chat (text only, booking-linked)

### Sprint 4: Trust & Payment (Weeks 7-8)
- [ ] Vouch system (post-job prompt)
- [ ] Trust badges (New Pro, Trusted, Certified)
- [ ] Payment integration (Yoco or PayFast)
- [ ] Escrow flow (authorize -> capture -> payout)
- [ ] "My Pros" favorites feature

---

## Tech Stack
- **Mobile App:** Flutter (Dart) - works on Android + iOS from one codebase
- **Backend:** Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)
- **Maps:** Google Maps Flutter plugin
- **Payments:** Yoco API (South Africa focused)
- **Push Notifications:** Firebase Cloud Messaging (free)

---

## What Each Piece Does (Beginner Explanation)

### Flutter (The App)
- This is the "front end" - what users see and tap on their phones
- Written in a language called Dart
- One codebase makes both Android and iPhone apps
- Think of it as the "face" of your app

### Supabase (The Brain)
- This is the "back end" - where all data lives
- It's a database (PostgreSQL) that stores users, bookings, vouches, etc.
- It handles login/registration (Auth)
- It stores photos and videos (Storage)
- It sends live updates to the app (Realtime) - like showing a pro moving on the map
- It runs background code (Edge Functions) - like processing payments

### Google Maps API (The Map)
- Shows the interactive map in the app
- Displays pro locations as pins
- Calculates distances between clients and pros

### Yoco (The Money)
- South African payment processor
- Handles card payments and EFT
- Takes 2.95% per transaction
- You hold money in escrow until job is done

