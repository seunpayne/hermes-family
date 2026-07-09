INSERT INTO skills_manifest
  (name, version, source, file_path, status, notes)
VALUES
  ('task-management', '1.0', 'custom',
   '~/.hermes/skills/openclaw-imports/task-management/SKILL.md',
   'active',
   'Task lifecycle, escalation timers, stall protocol,
    Symphony specification, retry rules, morning briefing.
    Extracted from SOUL.md v1 during surgery May 2026.'),
  ('emergency-hotfix', '1.0', 'custom',
   '~/.hermes/skills/openclaw-imports/emergency-hotfix/SKILL.md',
   'active',
   'Emergency production hotfix. Revert only. Fredo scan
    required. Load when production is broken and Seun
    is unreachable. Extracted from SOUL.md v1.')
ON CONFLICT (name) DO UPDATE SET
  version = EXCLUDED.version,
  updated_at = now();
