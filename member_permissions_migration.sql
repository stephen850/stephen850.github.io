-- ═══════════════════════════════════════════════════════════════
-- Deepbloe CRM — Member-level Permissions Migration
-- Adds per-member permission overrides
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS member_permissions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id  UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  panel      TEXT NOT NULL,
  can_view   BOOLEAN DEFAULT true,
  can_edit   BOOLEAN DEFAULT false,
  UNIQUE(member_id, panel)
);

ALTER TABLE member_permissions ENABLE ROW LEVEL SECURITY;

-- All authenticated can read
CREATE POLICY "Authenticated users can read member_permissions"
  ON member_permissions FOR SELECT TO authenticated USING (true);

-- Owners can write
CREATE POLICY "Owners can insert member_permissions"
  ON member_permissions FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );

CREATE POLICY "Owners can update member_permissions"
  ON member_permissions FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );

CREATE POLICY "Owners can delete member_permissions"
  ON member_permissions FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN roles r ON r.id = tm.role_id
      WHERE tm.user_id = auth.uid() AND r.name = 'owner'
    )
  );

-- Seed: give current owner (first team member) full permissions
INSERT INTO member_permissions (member_id, panel, can_view, can_edit)
SELECT tm.id, p.panel, true, true
FROM team_members tm
JOIN roles r ON r.id = tm.role_id
CROSS JOIN (VALUES 
  ('dashboard'),('contacts'),('venues'),('artists'),('bookings'),
  ('contracts'),('invoices'),('advancing'),('finance'),('calendar'),
  ('reminders'),('tours'),('pipeline'),('import'),('settings')
) AS p(panel)
WHERE r.name = 'owner'
ON CONFLICT (member_id, panel) DO NOTHING;
