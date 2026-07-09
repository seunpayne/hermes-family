# EOD Report Format

When Seun drops raw site notes, produce **TWO outputs** — never just one:

1. **Polished project report** (Telegram format, structured with emoji markers)
2. **Supervisor email** (plain email body, ready to copy-paste and send)

Both are mandatory. Seun will ask for the one you forgot.

---

## Polish Rules

- Keep Seun's raw facts, never fabricate progress
- Add emoji markers: ✅ done, 🔄 change request, 🚧 blocker, ⚠️ time-sensitive, 📋 next, 💡 note
- Group into: COMPLETED TODAY, IN PROGRESS / TOMORROW, BLOCKERS, NOTES
- Strip conversational filler — keep it tight for supervisor
- Encode change requests under their own header
- Flag deadlines that are overdue
- After polishing the EOD report, ALWAYS generate the supervisor email immediately — never wait to be prompted

---

## EOD Email Rules

After every EOD report, produce the supervisor email in the same turn. NEVER skip this step.

**Subject:** `EOD Report — [Project Name] — [Date]`

**Body:** Same content as the EOD report, formatted as a plain-text professional email with "Good evening," opening and "Regards, Seun" closing.

**Footer (MANDATORY — every EOD email, no exceptions):**
```
All project files and media will be uploaded here:
https://1drv.ms/f/c/f593c7be67f0b329/IgBRfWhwreYPQYkhJYWHpCCmAU7HdFKoGaDJEEXOsDx_xBA?e=4oYXMH
```

**Anti-pattern:** Do NOT drop the email. Do NOT omit the OneDrive footer. These are not optional.

---

## Output 1 — Polished Report (Telegram)

```
📋 EOD REPORT — [PROJECT NAME]
Date: [Day, Date]
Phase: [Current phase — one line summary]

✅ COMPLETED TODAY
- [Bullet list of completed items]

📋 IN PROGRESS / TOMORROW
- [Next day's planned work]

🔄 CHANGE REQUESTS
- [Any scope changes processed today]

🚧 BLOCKERS
- [Each blocker with date raised]

⚠️ TIME-SENSITIVE
- [Deadlines — flag if overdue]

💡 NOTES
- [Context for supervisor — procurement %, decisions pending]
```

---

## Output 2 — Supervisor Email

**MANDATORY.** Produce immediately after the polished report. Format as plain email body text — no markdown headers, no emoji.

```
To: [supervisor / project contact]
Subject: EOD Report — [Project Name] — [Date]

Good evening,

Progress today:

- [Bullet list of completed items — plain text, dashes]

Still outstanding:

- [Each blocker, plain text]

Tomorrow: [Next day's planned work — one sentence]

Regards,
Seun

All project files and media will be uploaded here:
https://1drv.ms/f/c/f593c7be67f0b329/IgBRfWhwreYPQYkhJYWHpCCmAU7HdFKoGaDJEEXOsDx_xBA?e=4oYXMH
```

The OneDrive link footer is **NEVER optional.** Every EOD email ends with that line. No exceptions.

---

## Anti-Patterns

- Do NOT produce only the polished report and skip the email — Seun needs both
- Do NOT produce only the email and skip the polished report
- Do NOT omit the OneDrive link from the email footer
- Do NOT fabricate progress for days without EOD input
- Do NOT guess what was "planned" for tomorrow — use only what Seun says
- Do NOT fill "[To be filled by Seun]" with generated content — it's a placeholder
- Do NOT log EOD to PROJECT_LOG.md without Seun's raw input first
