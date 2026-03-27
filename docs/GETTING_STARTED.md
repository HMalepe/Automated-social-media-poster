# VouchSA - Getting Started Guide (For Absolute Beginners)

This guide assumes you've never written code before. Every step is explained.

---

## What You'll Need

Before we start, you need a few things installed on your computer:

### 1. A Computer
- Windows 10+, macOS, or Linux
- At least 8GB RAM (16GB is better)
- At least 20GB free disk space

### 2. An Android Phone (for testing)
- OR an iPhone (but Android is easier to test with)
- You can also use an emulator (a fake phone on your computer)

---

## Step 1: Create Your Supabase Project (The Database)

**What is Supabase?**
It's where all your app's data lives — users, bookings, vouches, everything.
Think of it as a giant spreadsheet in the cloud that your app reads and writes to.

**How to set it up:**

1. Go to [app.supabase.com](https://app.supabase.com)
2. Click "Sign Up" (use your Google or GitHub account)
3. Click "New Project"
4. Fill in:
   - **Name:** VouchSA
   - **Database Password:** Choose something strong (save it somewhere!)
   - **Region:** Choose "South Africa" or the closest option
5. Click "Create new project"
6. Wait 2-3 minutes for it to set up

**After it's ready:**

7. Click "Settings" in the left sidebar
8. Click "API"
9. You'll see two important values:
   - **Project URL:** Something like `https://abcdef.supabase.co`
   - **anon/public key:** A long string starting with `eyJ...`
10. **Copy both of these** — you'll need them later

**Now create the database tables:**

11. Click "SQL Editor" in the left sidebar
12. Click "New query"
13. Open the file `supabase/migrations/001_initial_schema.sql` from this project
14. Copy ALL the contents and paste into the SQL editor
15. Click "Run" (the green play button)
16. You should see "Success" at the bottom
17. Repeat with `supabase/migrations/002_functions.sql`

**Enable Phone Auth (for OTP login):**

18. Click "Authentication" in the left sidebar
19. Click "Providers"
20. Find "Phone" and toggle it ON
21. You'll need a Twilio account for SMS (see Step 4)

**Create Storage Buckets (for photos/videos):**

22. Click "Storage" in the left sidebar
23. Click "New bucket" and create these:
    - `profile-photos` (toggle "Public" ON)
    - `voice-intros` (toggle "Public" ON)
    - `video-intros` (toggle "Public" ON)
    - `portfolio-images` (toggle "Public" ON)

---

## Step 2: Install Flutter (The App Framework)

**What is Flutter?**
It's a toolkit from Google that lets you build apps for Android AND iPhone
from one set of code. Instead of building two separate apps, you build one.

**Install Flutter:**

### On macOS:
```bash
# Open Terminal (search "Terminal" in Spotlight)
# Install Homebrew first (a package manager for Mac):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter:
brew install flutter

# Verify it worked:
flutter doctor
```

### On Windows:
1. Go to [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
2. Download the Flutter SDK zip file
3. Extract it to `C:\flutter`
4. Add `C:\flutter\bin` to your system PATH:
   - Search "Environment Variables" in Windows Settings
   - Under "System variables", find "Path"
   - Click "Edit" → "New" → type `C:\flutter\bin`
5. Open Command Prompt and run: `flutter doctor`

### On Linux:
```bash
sudo snap install flutter --classic
flutter doctor
```

**`flutter doctor` will tell you what else you need.** Follow its instructions.
Common things it asks for:
- **Android Studio** (needed for Android emulator)
- **Xcode** (needed for iPhone, Mac only)
- **Chrome** (for web testing)

---

## Step 3: Install an IDE (Code Editor)

**What is an IDE?**
It's a special text editor designed for writing code. It highlights syntax,
catches errors, and has tools that make coding easier.

**Recommended: VS Code (free)**

1. Download from [code.visualstudio.com](https://code.visualstudio.com)
2. Install it
3. Open VS Code
4. Install these extensions (click the puzzle piece icon in the left sidebar):
   - **Flutter** (by Dart Code) — THE most important one
   - **Dart** (by Dart Code) — language support

**Alternative: Cursor AI ($20/month)**
- Same as VS Code but with AI built in
- You can type instructions in plain English
- It writes code for you
- Great for beginners — highly recommended if you can afford it

---

## Step 4: Set Up Twilio (for SMS/OTP)

**What is Twilio?**
A service that sends SMS messages. You need it so users can verify their
phone numbers with a one-time code.

1. Go to [twilio.com](https://www.twilio.com) and sign up
2. You get free trial credits (~$15)
3. Get a phone number (Twilio gives you one)
4. Find your:
   - **Account SID** (in the dashboard)
   - **Auth Token** (in the dashboard)
5. In your Supabase dashboard:
   - Go to Authentication → Providers → Phone
   - Enter your Twilio Account SID, Auth Token, and phone number

**Cost:** About R0.08 per SMS. For testing, the free tier is enough.

---

## Step 5: Get a Google Maps API Key

**Why?**
The map in your app needs permission from Google to show.

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project called "VouchSA"
3. Enable these APIs (search for them):
   - "Maps SDK for Android"
   - "Maps SDK for iOS"
   - "Geocoding API" (converts addresses to coordinates)
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy the API key

**Cost:** Google gives you $200/month free. That's ~28,000 map loads.
More than enough for development and early launch.

---

## Step 6: Set Up the Flutter Project

Now let's connect everything:

```bash
# Open Terminal/Command Prompt

# Navigate to where you downloaded this project
cd path/to/vouchsa/flutter_app

# Install all the packages listed in pubspec.yaml
flutter pub get

# This downloads all the tools your app needs (maps, auth, etc.)
```

**Connect to Supabase:**

Open `lib/utils/constants.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
static const String supabaseAnonKey = 'eyJ...YOUR-KEY-HERE';
static const String googleMapsApiKey = 'AIza...YOUR-KEY-HERE';
```

**Add Google Maps API Key to Android:**

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

---

## Step 7: Run the App!

```bash
# Connect your Android phone via USB
# OR start an emulator from Android Studio

# Run the app:
flutter run

# The first build takes 2-5 minutes. After that, it's much faster.
```

**What you should see:**
1. The VouchSA login screen with a phone number input
2. You won't be able to log in yet until Twilio is set up

**For testing without Twilio:**
In your Supabase dashboard, go to Authentication → Users → "Add User"
to manually create test accounts.

---

## Step 8: What to Build Next

Now that everything is set up, here's the order to build features:

### Week 1-2: Authentication (Login flow)
- ✅ Phone number input screen (already created)
- ✅ OTP verification screen (already created)
- ✅ Profile setup screen (already created)
- [ ] Profile photo upload
- [ ] Pro service setup (pick categories, set prices)

### Week 3-4: The Map
- [ ] Show Google Map on main screen
- [ ] Load available pros as pins
- [ ] Color-code pins by category
- [ ] Tap pin to see pro preview card
- [ ] Pro availability toggle (go live / go offline)

### Week 5-6: Booking
- [ ] "Book Now" flow (select service → confirm → pay)
- [ ] "Schedule" flow (pick date/time)
- [ ] Booking notifications
- [ ] Job start/complete flow

### Week 7-8: Trust & Payment
- [ ] Vouch prompt after job completion
- [ ] Trust badges on profiles
- [ ] Yoco payment integration
- [ ] "My Pros" favorites

---

## How to Use Claude Code to Help You Build

You're already using it! Here are tips for getting the most out of it:

### Good prompts:
- "Create the Google Maps widget for the map screen that shows pro location pins"
- "Build the booking flow screen where a client selects a service and confirms"
- "Write the Supabase query to find all available pros within 10km of my location"
- "I'm getting this error: [paste error]. How do I fix it?"

### Bad prompts:
- "Build VouchSA" (too vague)
- "Make it work" (need specifics)
- "Do everything" (break it into pieces)

### The key principle:
**Build ONE small thing at a time. Test it. Then move to the next thing.**

Don't try to build the entire app at once. That's how projects fail.

---

## Common Problems & Solutions

### "flutter doctor shows issues"
Run `flutter doctor -v` for detailed info. It usually needs:
- Android Studio (even if you use VS Code)
- Android SDK licenses: run `flutter doctor --android-licenses`

### "Build failed"
- Run `flutter clean` then `flutter pub get` then `flutter run`
- Check the error message — it usually says what's wrong

### "Supabase connection failed"
- Double-check your URL and anon key in constants.dart
- Make sure your Supabase project is running (green status)
- Check that RLS policies were created (run the SQL file again)

### "Map shows blank/grey"
- Check your Google Maps API key
- Make sure you enabled "Maps SDK for Android" in Google Cloud Console
- Check the AndroidManifest.xml has the key

---

## Monthly Costs Estimate

| Service | Free Tier | After Free Tier |
|---------|-----------|-----------------|
| Supabase | 50,000 MAU, 500MB storage | R350/month |
| Google Maps | $200/month credit (28K loads) | Pay per load |
| Twilio SMS | ~$15 trial credit | R0.08 per SMS |
| Firebase (notifications) | Free for push | Free |
| Google Play Store | Once-off R400 | - |
| Apple App Store | R1,600/year | R1,600/year |

**Total to get started: R0-R400** (if you skip Apple initially)
**Monthly after launch: ~R500-R1,000** (depending on users)
