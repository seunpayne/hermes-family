# Slack Delivery Setup for Cron Jobs

## When to Use This

Hermes is running in WebUI mode with no messaging platform connected. Cron jobs
fail with `Broken pipe` and `no delivery target resolved` because there's no
platform to deliver to. Setting up Slack creates a delivery channel.

## Prerequisites

- Slack workspace where you can create apps
- Admin rights to install apps to workspace
- Gateway must be running (check with `hermes gateway status`)

## Step-by-Step

### 1. Generate the App Manifest

```bash
hermes slack manifest --write
# Writes to ~/.hermes/slack-manifest.json
```

This includes all Hermes slash commands, OAuth scopes, and event subscriptions.

### 2. Create the Slack App

1. Go to https://api.slack.com/apps
2. Click **Create New App** → **From an app manifest**
3. Select your workspace
4. Paste the contents of `~/.hermes/slack-manifest.json`
5. Click **Create**

### 3. Configure Bot Token Scopes

Verify these scopes are set under **OAuth & Permissions → Bot Token Scopes**:

| Scope | Why |
|-------|-----|
| `chat:write` | Send messages |
| `app_mentions:read` | Detect @mentions |
| `channels:history` | Read public channel messages (critical) |
| `channels:read` | List public channels |
| `im:history` | Read DM history |
| `users:read` | Look up user info |
| `files:read` | Read attachments (images, voice notes) |
| `files:write` | Upload files |

**Without `channels:history`**, bot only works in DMs.

### 4. Enable Socket Mode

- **Settings → Socket Mode** → Enable
- Generate an **App-Level Token** (starts with `xapp-`)
- Scope must include `connections:write`

### 5. Subscribe to Events

Under **Event Subscriptions → Subscribe to bot events**:

| Event | Required? |
|-------|-----------|
| `message.im` | Yes |
| `message.channels` | Yes (without it, channel messages never arrive) |
| `app_mention` | Yes |

### 6. Enable Messages Tab

**App Home → Show Tabs → Messages Tab** → Enable.

Without this, users see "Sending messages to this app has been turned off."

### 7. Install App to Workspace

**Settings → Install App** → Install to Workspace.
Copy the **Bot Token** (starts with `xoxb-`).

### 8. Configure Hermes Environment

Add to `~/.env.hermes`:

```env
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_APP_TOKEN=xapp-your-app-token-here
SLACK_ALLOWED_USERS=U01ABC2DEF3    # Your Slack member ID
```

Optional — sets a default channel for cron delivery:
```env
SLACK_HOME_CHANNEL=C01234567890    # Channel ID
# or
SLACK_HOME_CHANNEL_NAME=general    # Human-readable name
```

### 9. Find Your Slack Member ID

- Click your profile pic → **Profile** → **More** → **Copy member ID**
- Looks like `U01ABC2DEF3`

### 10. Restart Gateway

```bash
hermes gateway restart
```

### 11. Invite Bot to Channels

Bot must be invited: `/invite @Hermes Agent` in each channel.

## Delivery Targets After Setup

Once Slack is connected and a home channel is set:

| Target | Result |
|--------|--------|
| `deliver=origin` | Delivers to Slack home channel |
| `deliver=slack` | Delivers to Slack (uses home channel) |
| `deliver=local` | Saves to disk, no delivery |

## Updating Failing Cron Jobs

```bash
# List current jobs to get job IDs
cronjob action=list

# Update a failing job's delivery target
cronjob action=update job_id=<id> deliver=origin
# or
cronjob action=update job_id=<id> deliver=slack
```

## Troubleshooting

| Symptom | Likely Cause |
|---------|-------------|
| Bot works in DMs but not channels | Missing `channels:history` scope + `message.channels` event. Reinstall app after fixing. |
| Users can't DM the bot | Messages Tab not enabled (Step 6) |
| Slash commands don't work | Manifest not applied or app not reinstalled after manifest change |
| `no delivery target resolved` after Slack setup | `SLACK_HOME_CHANNEL` not set. Set it or use `deliver=slack` explicitly. |
