-- =========================================================================
-- ShowUp Supabase Database Setup Schema (Phase 1)
-- =========================================================================
-- How to use:
-- 1. Create a free project at https://supabase.com
-- 2. Go to the "SQL Editor" in the left sidebar of your Supabase dashboard.
-- 3. Click "New Query", paste this entire script, and click "Run".
-- 4. In your Supabase settings (API section), copy your Project URL and Anon API Key.
-- 5. Paste them at the top of your `index.html` file in the CONFIG variables.
-- =========================================================================

-- 1. Create Groups Table
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Members Table
CREATE TABLE members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create Checkins Table
CREATE TABLE checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  logged_date DATE NOT NULL, -- Stored as YYYY-MM-DD to avoid timezone shifting
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  -- Prevent the same user from logging multiple workouts on the same day
  CONSTRAINT unique_member_logged_date UNIQUE (member_id, logged_date)
);

-- 5. Create Support Tickets Table (for feedback popup logs)
CREATE TABLE support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID REFERENCES members(id) ON DELETE SET NULL,
  group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('bug', 'feature', 'other')),
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Enable Real-time Replication for Collaborative Live Updates
-- This pushes data modifications to any connected user's screen instantly.
ALTER PUBLICATION supabase_realtime ADD TABLE members;
ALTER PUBLICATION supabase_realtime ADD TABLE checkins;

-- 7. Add sample indexes for performance optimization
CREATE INDEX idx_members_group ON members(group_id);
CREATE INDEX idx_checkins_member ON checkins(member_id);
CREATE INDEX idx_tickets_group ON support_tickets(group_id);

-- 8. Row Level Security (RLS) — Supabase blocks all access without this!
-- Since ShowUp uses no auth (anonymous users), we allow public read/write.
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on groups" ON groups FOR SELECT USING (true);
CREATE POLICY "Allow public insert on groups" ON groups FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read on members" ON members FOR SELECT USING (true);
CREATE POLICY "Allow public insert on members" ON members FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read on checkins" ON checkins FOR SELECT USING (true);
CREATE POLICY "Allow public insert on checkins" ON checkins FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public insert on support_tickets" ON support_tickets FOR INSERT WITH CHECK (true);
