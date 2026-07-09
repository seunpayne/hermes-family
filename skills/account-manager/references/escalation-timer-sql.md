# Escalation Timer SQL Patterns

Reference queries for the Account Manager escalation monitoring system.
Use these patterns when implementing or debugging the 30-minute watchdog.

---

## 4-Hour Review Reminder (One-Time)

```sql
SELECT
  t.id,
  t.title,
  t.status,
  t.updated_at,
  p.name as project_name,
  c.name as client_name
FROM tasks t
JOIN projects p ON p.id = t.project_id
JOIN clients c ON c.id = p.client_id
WHERE t.status = 'review'
  AND t.updated_at < now() - interval '4 hours'
  AND (t.sent_4hr_reminder IS NULL OR t.sent_4hr_reminder = false)
ORDER BY t.updated_at ASC;
```

**After sending reminder:**
```sql
UPDATE tasks
SET sent_4hr_reminder = true
WHERE id = [task_id];
```

---

## 24-Hour Review Pending (Daily)

```sql
SELECT
  t.id,
  t.title,
  t.status,
  t.updated_at,
  p.name as project_name,
  c.name as client_name,
  EXTRACT(DAY FROM now() - t.updated_at) as days_waiting
FROM tasks t
JOIN projects p ON p.id = t.project_id
JOIN clients c ON c.id = p.client_id
WHERE t.status = 'review'
  AND t.updated_at < now() - interval '24 hours'
ORDER BY t.updated_at ASC;
```

**Log to escalations table on first trigger:**
```sql
INSERT INTO escalations (
  project_id,
  task_id,
  escalation_type,
  reason,
  status,
  created_at
) VALUES (
  [project_id],
  [task_id],
  'review_timeout_24h',
  'Task in REVIEW state for more than 24 hours',
  'open',
  now()
)
ON CONFLICT (task_id, escalation_type) DO NOTHING;
```

---

## 2-Hour Blocked Alert (Immediate + Repeating)

```sql
SELECT
  t.id,
  t.title,
  t.agent,
  t.status,
  t.updated_at,
  t.blocked_by,
  p.name as project_name,
  c.name as client_name
FROM tasks t
JOIN projects p ON p.id = t.project_id
JOIN clients c ON c.id = p.client_id
WHERE t.status = 'blocked'
  AND t.updated_at < now() - interval '2 hours'
ORDER BY t.updated_at ASC;
```

**Telegram message format:**
```
BLOCKED — [task name] — [agent] — 
[what is blocking] — Action required.
```

---

## Sent Reminders Tracking

Add to tasks table schema:
```sql
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS sent_4hr_reminder BOOLEAN DEFAULT false;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS sent_24hr_reminder_at TIMESTAMPTZ;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS sent_blocked_alert_at TIMESTAMPTZ;
```

**Update after sending 24-hour reminder:**
```sql
UPDATE tasks
SET sent_24hr_reminder_at = now()
WHERE id = [task_id];
```

**Update after sending blocked alert:**
```sql
UPDATE tasks
SET sent_blocked_alert_at = now()
WHERE id = [task_id];
```

---

## Combined Monitoring Query (Single Pass)

For efficient 30-minute watchdog runs:

```sql
SELECT
  t.id,
  t.title,
  t.status,
  t.agent,
  t.updated_at,
  t.blocked_by,
  p.name as project_name,
  c.name as client_name,
  CASE
    WHEN t.status = 'review' AND t.updated_at < now() - interval '24 hours' THEN 'review_24h'
    WHEN t.status = 'review' AND t.updated_at < now() - interval '4 hours' AND (t.sent_4hr_reminder IS NULL OR t.sent_4hr_reminder = false) THEN 'review_4h'
    WHEN t.status = 'blocked' AND t.updated_at < now() - interval '2 hours' THEN 'blocked_2h'
    ELSE NULL
  END as alert_type,
  CASE
    WHEN t.status = 'review' THEN EXTRACT(DAY FROM now() - t.updated_at)::integer
    WHEN t.status = 'blocked' THEN EXTRACT(HOUR FROM now() - t.updated_at)::integer
    ELSE NULL
  END as wait_time
FROM tasks t
JOIN projects p ON p.id = t.project_id
JOIN clients c ON c.id = p.client_id
WHERE t.status IN ('review', 'blocked')
  AND (
    (t.status = 'review' AND t.updated_at < now() - interval '4 hours')
    OR (t.status = 'blocked' AND t.updated_at < now() - interval '2 hours')
  )
ORDER BY 
  CASE alert_type
    WHEN 'blocked_2h' THEN 1
    WHEN 'review_24h' THEN 2
    WHEN 'review_4h' THEN 3
    ELSE 4
  END,
  t.updated_at ASC;
```

**Process logic:**
1. Group results by `alert_type`
2. For `review_4h`: send once, set `sent_4hr_reminder = true`
3. For `review_24h`: send daily, log to escalations on first occurrence
4. For `blocked_2h`: send immediately every check until resolved

---

## Pitfalls

| Issue | Symptom | Fix |
|-------|---------|-----|
| Duplicate 4-hour reminders | `sent_4hr_reminder` not updated after send | Always update flag immediately after sending |
| Missing 24-hour escalation log | Escalation not in table after 24h | Use `ON CONFLICT DO NOTHING` to avoid duplicates |
| Blocked alerts spamming | Alert sent every 30min without rate limit | This is intentional for blocked tasks — they need immediate attention |
| Timezone mismatch | Reminders fire at wrong times | Ensure Supabase session timezone matches Africa/Lagos |
| Null `updated_at` | Task never triggers alert | Set `updated_at` on task creation and every status change |

---

## Testing

**Simulate a 4-hour overdue task:**
```sql
UPDATE tasks
SET updated_at = now() - interval '5 hours',
    status = 'review'
WHERE id = [test_task_id];
```

**Verify query catches it:**
```sql
-- Run the 4-hour query above
-- Should return the test task
```

**Reset after testing:**
```sql
UPDATE tasks
SET updated_at = now(),
    sent_4hr_reminder = false
WHERE id = [test_task_id];
```
