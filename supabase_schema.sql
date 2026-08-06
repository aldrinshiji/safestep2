-- SafeStep Production-Ready Supabase Database Schema

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. GUARDIANS TABLE
CREATE TABLE IF NOT EXISTS public.guardians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    relationship TEXT DEFAULT 'Emergency Contact',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. EMERGENCIES TABLE
CREATE TABLE IF NOT EXISTS public.emergencies (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_model TEXT,
    battery_percentage INT,
    internet_status TEXT,
    upload_status TEXT DEFAULT 'pending', -- 'pending', 'uploaded', 'failed'
    guardian_status TEXT DEFAULT 'pending', -- 'pending', 'sent', 'failed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. LOCATIONS TABLE
CREATE TABLE IF NOT EXISTS public.locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id TEXT NOT NULL REFERENCES public.emergencies(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    google_maps_url TEXT NOT NULL,
    captured_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. VIDEOS TABLE
CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id TEXT NOT NULL REFERENCES public.emergencies(id) ON DELETE CASCADE,
    public_url TEXT NOT NULL,
    local_path TEXT,
    storage_bucket TEXT DEFAULT 'emergency-videos',
    duration_seconds INT DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. NOTIFICATION_LOGS TABLE
CREATE TABLE IF NOT EXISTS public.notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id TEXT NOT NULL REFERENCES public.emergencies(id) ON DELETE CASCADE,
    guardian_name TEXT,
    guardian_email TEXT,
    guardian_mobile TEXT,
    status TEXT DEFAULT 'sent',
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- enable REALTIME for emergencies table
ALTER PUBLICATION supabase_realtime ADD TABLE public.emergencies;

-- ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Guardians Policies
CREATE POLICY "Users can manage own guardians" ON public.guardians FOR ALL USING (auth.uid() = user_id);

-- Emergencies Policies
CREATE POLICY "Allow authenticated or anonymous insert emergency" ON public.emergencies FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view own emergencies" ON public.emergencies FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

-- Locations Policies
CREATE POLICY "Allow location insert" ON public.locations FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view location details" ON public.locations FOR SELECT USING (true);

-- Videos Policies
CREATE POLICY "Allow video metadata insert" ON public.videos FOR INSERT WITH CHECK (true);
CREATE POLICY "Public video metadata read" ON public.videos FOR SELECT USING (true);

-- Notification Logs Policies
CREATE POLICY "Allow notification log insert" ON public.notification_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Read notification log" ON public.notification_logs FOR SELECT USING (true);

-- STORAGE BUCKET CREATION FOR EMERGENCY VIDEOS
INSERT INTO storage.buckets (id, name, public) 
VALUES ('emergency-videos', 'emergency-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
CREATE POLICY "Public Emergency Video Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'emergency-videos');
CREATE POLICY "Public Emergency Video Access" ON storage.objects FOR SELECT USING (bucket_id = 'emergency-videos');
