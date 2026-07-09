# Config YAML Canonicalization

How to strip a bloated backup config.yaml down to only the non-default
customizations. The agent already assumes sensible defaults for every
key — keeping them in the file adds noise without changing behavior.

## Technique

1. **Load the backup** and count lines. A large config (450+ lines) is
   almost entirely defaults.

2. **Group keys into three buckets:**

   | Bucket | What | Action |
   |--------|------|--------|
   | **Real config** | Custom values the user deliberately set (model, provider, timeouts, enabled features) | KEEP |
   | **Explicit defaults** | Keys that match the agent's hardcoded default — `providers: {}`, `fallback_providers: []`, `terminal.backend: local`, `display.compact: false` | DROP |
   | **Dead config** | Sections for platforms/services not in use (slack/discord/telegram when using WebUI only; MCP servers with plaintext tokens; delegation requiring env vars not set) | DROP |

3. **Real config to keep** — typically only 20-40 lines:
   ```yaml
   model:
     default: <model-name>
     provider: <provider>
     base_url: <url>
   
   agent:
     max_turns: <custom-limit>
     gateway_timeout: <custom-seconds>
     clarify_timeout: <custom-seconds>
   
   compression:
     enabled: true
     threshold: <0.0-1.0>
     target_ratio: <0.0-1.0>
     protect_last_n: <N>
   
   memory:
     memory_enabled: true
     user_profile_enabled: true
     memory_char_limit: <N>
     user_char_limit: <N>
   
   display:
     show_cost: true
     language: <code>
   
   approvals:
     mode: manual
     cron_mode: deny
   
   cron:
     wrap_response: true
   
   skills:
     disabled: []
   ```

4. **Default values that need explicit mention** (only include if the
   user's preference differs from the Hermes default):
   - `agent.max_turns` — Hermes default is 90; explicit only if user
     wants a different limit
   - `compression.threshold` — Hermes default is 0.7; set to 0.5 if
     user wants more aggressive compression
   - `display.show_cost` — default is false; keep if user wants cost
     visible
   - `approvals.cron_mode` — default is "deny"; keep if user wants
     explicit denial

5. **Verify the slim config is loadable:**
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"
   echo "Config parse OK"
   ```

6. **Check the agent starts correctly:**
   ```bash
   hermes doctor
   ```

## Signals that trigger this

- User drops a 400+ line `config.yaml` backup and says "review this"
- User says "migrate my Hermes"
- User shows you a config with `_config_version: N` surrounded by
  300 lines of default values
- User has platform sections (slack, discord, telegram, whatsapp,
  matrix, mattermost) but no gateway running

## Pitfalls

- **Secrets in config.yaml** are the #1 danger. Any `api_key`,
  `Authorization: Bearer ...`, or raw token in config must be moved to
  `.env` and referenced by env-var name. Config files end up in git repos,
  backups, and transfer packages — plaintext secrets there stay there.
- **Platform sections with no running gateway** are noise. The agent
  ignores them when the gateway isn't enabled, but they add 60+ lines
  of config that make the real settings harder to find.
- **MCP servers with hardcoded tokens** (`headers.Authorization: Bearer`)
  create the same problem as secrets in config. Use `token_env` and
  reference the `.env` var instead.
- **`_config_version`** is informational — the agent handles upgrades
  automatically. No need to pin it.
- **`delegation.*` with `api_key: ''`** indicates the user tried to
  configure delegation but hasn't provided the key. Silent dead config
  until the env var is set.
