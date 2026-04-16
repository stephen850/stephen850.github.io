-- ═══════════════════════════════════════════════════════════════
-- Deepbloe CRM — RBAC Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ═══════════════════════════════════════════════════════════════

-- 1) ROLES TABLE
-- Pre-seeded with owner / manager / agent / finance / readonly
CREATE TABLE IF NOT EXISTS roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE,          -- e.g. 'owner', 'manager', 'agent'
  label       TEXT NOT NULL,                 -- display name: 'Owner', 'Manager'
  description TEXT DEFAULT '',
  is_system   BOOLEAN DEFAULT false,         -- system roles can't be deleted
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- System roles
INSERT INTO roles (name, label, description, is_system, sort_order) VALUES
  ('owner',    'Owner',    'Full access. Cannot be restricted or removed.',                    true, 0),
  ('manager',  'Manager',  'Can manage artists, bookings, contracts, invoices and team.',      true, 1),
  ('agent',    'Agent',    'Can view and manage bookings for assigned artists only.',           true, 2),
  ('finance',  'Finance',  'Access to finance, invoices, settlements. Read-only elsewhere.',   true, 3),
  ('readonly', 'Read Only','View-only access across all panels. Cannot edit or create.',       true, 4)
ON CONFLICT (name) DO NOTHING;


-- 2) ROLE PERMISSIONS TABLE
-- Each row grants a role access to a specific CRM panel
CREATE TABLE IF NOT EXISTS role_permissions (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id   UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  panel     TEXT NOT NULL,    -- matches panel IDs: 'dashboard','contacts','artists', etc.
  can_view  BOOLEAN DEFAULT true,
  can_edit  BOOLEAN DEFAULT false,
  UNIQUE(role_id, panel)
);

-- Helper: seed permissions for a role
-- Panels: dashboard, contacts, venues, artists, bookings, contracts, invoices, advancing, finance, calendar, reminders, tours, pipeline, import, settings
DO $$
DECLARE
  r_owner    UUID; r_manager UUID; r_agent UUID; r_finance UUID; r_readonly UUID;
  all_panels TEXT[] := ARRAY['dashboard','contacts','venues','artists','bookings','contracts','invoices','advancing','finance','calendar','reminders','tours','pipeline','import','settings'];
  p TEXT;
BEGIN
  SELECT id INTO r_owner    FROM roles WHERE name = 'owner';
  SELECT id INTO r_manager  FROM roles WHERE name = 'manager';
  SELECT id INTO r_agent    FROM roles WHERE name = 'agent';
  SELECT id INTO r_finance  FROM roles WHERE name = 'finance';
  SELECT id INTO r_readonly FROM roles WHERE name = 'readonly';

  -- Owner: full access everywhere
  FOREACH p IN ARRAY all_panels LOOP
    INSERT INTO role_permissions (role_id, panel, can_view, can_edit)
    VALUES (r_owner, p, true, true)
    ON CONFLICT (role_id, panel) DO NOTHING;
  END LOOP;

  -- Manager: everything except settings (view-only on settings)
  FOREACH p IN ARRAY all_panels LOOP
    INSERT INTO role_permissions (role_id, panel, can_view, can_edit)
    VALUES (r_manager, p, true, CASE WHEN p = 'settings' THEN false ELSE true END)
    ON CONFLICT (role_id, panel) DO NOTHING;
  END LOOP;

  -- Agent: limited panels
  FOREACH p IN ARRAY ARRAY['dashboard','artists','bookings','contracts','advancing','calendar','reminders','tours','pipeline'] LOOP
    INSERT INTO role_permissions (role_id, panel, can_view, can_edit)
    VALUES (r_agent, p, true, CASE WHEN p IN ('dashboard','calendar') THEN false ELSE true END)
    ON CONFLICT (role_id, panel) DO NOTHING;
  END LOOP;

  -- Finance: finance-heavy panels
  FOREACH p IN ARRAY ARRAY['dashboard','invoices','finance','contracts','bookings'] LOOP
    INSERT INTO role_permissions (role_id, panel, can_view, can_edit)
    VALUES (r_finance, p, true, CASE WHEN p IN ('invoices','finance') THEN true ELSE false END)
    ON CONFLICT (role_id, panel) DO NOTHING;
  END LOOP;

  -- Readonly: view everything, edit nothing
  FOREACH p IN ARRAY all_panels LOOP
    INSERT INTO role_permissions (role_id, panel, can_view, can_edit)
    VALUES (r_readonly, p, true, false)
    ON CONFLICT (role_id, panel) DO NOTHING;
  END LOOP;
END $$;


-- 3) TEAM MEMBERS TABLE
-- Links Supabase auth users to a CRM role
CREATE TABLE IF NOT EXISTS team_members (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL UNIQUE,            -- references auth.users(id)
  email      TEXT NOT NULL,
  full_name  TEXT DEFAULT '',
  role_id    UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  is_active  BOOLEAN DEFAULT true,
  invited_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookup by user_id
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);


-- 4) ARTIST ASSIGNMENTS TABLE
-- Which team member is responsible for which artist
-- Agents only see bookings/data for their assigned artists
CREATE TABLE IF NOT EXISTS artist_assignments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  artist_id   UUID NOT NULL REFERENCES artists(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(member_id, artist_id)
);


-- 5) RLS POLICIES
-- Enable RLS on the new tables
ALTER TABLE roles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members       ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_assignments ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read roles + permissions (needed for UI)
CREATE POLICY "Authenticated users can read roles"
  ON roles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can read role_permissions"
  ON role_permissions FOR SELECT TO authenticated USING (true);

-- Team members: all authenticated can read; only owners can insert/update/delete
CREATE POLICY "Authenticated users can read team_members"
  ON team_members FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners can manage team_members"
  ON team_members FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );

-- Artist assignments: all authenticated can read; owners + managers can manage
CREATE POLICY "Authenticated users can read artist_assignments"
  ON artist_assignments FOR SELECT TO authenticated USING (true);

CREATE POLICY "Owners and managers can manage artist_assignments"
  ON artist_assignments FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name IN ('owner', 'manager')
    )
  );

-- Owners can manage roles + role_permissions
CREATE POLICY "Owners can manage roles"
  ON roles FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );

CREATE POLICY "Owners can manage role_permissions"
  ON role_permissions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );


-- 6) AUTO-REGISTER FIRST USER AS OWNER
-- If team_members is empty, the first user to log in becomes owner.
-- This is handled in JS (startApp) so no trigger needed.

-- Done! After running this, deploy the updated crm.html.
