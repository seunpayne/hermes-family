# Slack Delivery Setup for Hermes WebUI

Full walkthrough for adding Slack as a delivery channel for cron jobs and notifications in the Hermes WebUI environment.

## Prerequisites

- Slack workspace with permission to install apps
- Slack API dashboard access at https://api.slack.com/apps

## Step-by-Step

### 1. Generate the App Manifest

```bash
hermes slack manifest --write
```

Writes a complete manifest with all slash commands, OAuth scopes, and event subscriptions to `~/.hermes/slack-manifest.json`.

### 2. Create the Slack App

1. Go to https://api.slack.com/apps → **Create New App** → **From an app manifest**
2. Paste the generated manifest content
3. Save → Slack will validate and prompt to install

### 3. Install & Collect Tokens

| Token | Prefix | Where to Find It |
|-------|--------|-----------------|
| **Bot Token** | `xoxb-...` | OAuth & Permissions → Bot User OAuth Token (appears after Install to Workspace) |
| **App-Level Token** | `xapp-...` | Settings → Socket Mode → Generate (scope must include `connections:write`) |

### 4. Get Your Slack Member ID

Right-click your name in Slack → **Copy member ID** — looks like `U01ABC2DEF3`.

### 5. Configure Hermes

Add to `~/.hermes/.env`:

```env
# Slack
SLACK_BOT_TOKEN=***
SLACK_APP_TOKEN=***
SLACK_ALLOWED_USERS=U01ABC2DEF3       # comma-separated for multiple users
SLACK_HOME_CHANNEL_NAME=general       # or SLACK_HOME_CHANNEL=D0B910UR2SV
```

**About `SLACK_HOME_CHANNEL` vs `SLACK_HOME_CHANNEL_NAME`:**
- `SLACK_HOME_CHANNEL_NAME` = human-readable channel name (e.g., `general`). The gateway resolves it at startup.
- `SLACK_HOME_CHANNEL` = raw channel ID (e.g., `D0B910UR2SV`). Use this if the name-based lookup fails.
- The home channel is where `deliver=origin` cron jobs land in WebUI mode.

### 6. Restart Gateway

```bash
hermes gateway restart
```

Wait ~30s then verify:

```bash
hermes gateway status
grep -i slack ~/.hermes/logs/agent.log | tail -5
```

**Expected signals in agent.log:**
```
[Slack] Authenticated as @hermes in workspace Your Workspace (team: T0XXXXXX)
[Slack] Socket Mode connected (1 workspace(s))
✓ slack connected
⚡️ Bolt app is running!
```

### 7. Invite Bot to Channel

The bot **does not auto-join**. In each channel where it should respond:

```
/invite @hermes
```

After inviting, the channel appears in `send_message(action='list')` output.

## WebUI-Specific Patterns

### Cron Delivery in WebUI

In Hermes WebUI mode, `deliver=origin` does NOT resolve to any platform by default. The fix:

1. Connect Slack (steps 1-7 above)
2. Set `SLACK_HOME_CHANNEL` or `SLACK_HOME_CHANNEL_NAME` in `.env`
3. Invite `@hermes` to the home channel
4. Set cron jobs to `deliver=origin` — the scheduler will log:
   ```
   Job has deliver=origin but no origin; falling back to slack home channel
   ```

### Stale Platform Token Cleanup

If a previous platform's bot token is stale/invalid (e.g., a Telegram token that was revoked), its connection retries spam the logs every 5 minutes. Clean it up:

1. Remove the stale token from `~/.hermes/.env`
2. Restart gateway: `hermes gateway restart`
3. Verify: the stale retries stop

The token typically appears as `PLATFORM_BOT_TOKEN` (e.g., `TELEGRAM_BOT_TOKEN`).

## Diagnostics

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `No messaging platforms connected` in `send_message list` | Bot not invited to any channel | `/invite @hermes` and DM the bot |
| Bot works in DMs but not channels | Missing `message.channels` event in app config | Reinstall app after adding event subscription |
| `Slack channel not found` | Home channel name is wrong or bot isn't invited there | Verify channel exists, invite bot |
| Gateway won't start after adding Slack tokens | Token format invalid or missing scope | Check token prefixes (`xoxb-` for bot, `xapp-` for app-level) |
| Old platform retry loop (Telegram, etc.) | Stale bot token in .env | Remove stale token, restart gateway |
| Cron jobs show `deliver=origin but no origin` | WebUI has no native origin platform | Set SLACK_HOME_CHANNEL and invite bot there |

## Verification

After setup, confirm delivery works end-to-end:

1. **DM test:** Run a cron job with `deliver=origin` or use `send_message` to `slack:D0B....`
2. **Cron job test:** `cronjob(action='run', job_id='...')` then check agent.log for delivery confirmation
3. **Channel test:** @mention `@hermes` in a public channel — should reply in thread
