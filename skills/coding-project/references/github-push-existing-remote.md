# GitHub Push — Handling Existing Remote Branches

When pushing a fresh project to a repo that already has content:

## 1. Detect existing content

```bash
git fetch --all
git branch -a
```

If the remote has a `main` branch with content different from yours:

## 2. Understand the differences

```bash
git diff --stat main..origin/main
# or for a specific branch:
git diff --stat main..origin/cc-build
```

## 3. Merge strategies

**Same project, different history** (user pushed from another machine):
```bash
git pull origin main --allow-unrelated-histories --no-rebase
# Fix any merge conflicts
git commit -m "Merge remote changes"
git push origin main
```

**Different branch entirely** (e.g., `cc-build` from Claude Code):
```bash
# Check what files are different:
git diff --stat main..origin/cc-build

# If 8 insertions, 56K+ deletions = different project. Don't merge.
# Just push your main and leave the branch as-is.
git push origin main
```

**Selector — which action to take:**

| Condition | Action |
|-----------|--------|
| `git diff --stat` shows < 50 files changed | Likely same project, different session. Pull + merge. |
| `git diff --stat` shows 200+ files with "(gone)" markers | Different project entirely. Push main, leave other branch. |
| Remote has single file (e.g., README) | Pull rebase or force push (ask first). |
| Remote branch has useful partial work | Check out the branch, cherry-pick specific commits, push to main. |

## 4. Credentials for push

GitHub token lives in `~/.hermes/.env` as `GITHUB_TOKEN`.
If `cat` shows `GITHUB_TOKEN=***` — the `***` is terminal display truncation.
Verify with:
```bash
source ~/.hermes/.env
python3 -c "import os; print(len(os.environ.get('GITHUB_TOKEN','')))"
```

Push via HTTPS:
```bash
source ~/.hermes/.env
git remote add origin "https://seunpayne:${GITHUB_TOKEN}@github.com/seunpayne/[repo].git"
git push -u origin main
```

### PITFALL — Terminal masking corrupts token in inline commands

When the GITHUB_TOKEN in `.env` is expired or invalid, and the user provides
a **new PAT in the chat**, the Hermes terminal output masking converts the
token to `***` in any command output. Worse, this masking can corrupt Python
f-strings and shell heredocs that reference the token inline:

```python
# BROKEN — terminal replaces token with ***, corrupting the f-string
cmd = ['curl', '-H', f'Authorization: Bearer {token}', ...]
# Becomes: ['curl', '-H', 'Authorization: Bearer ***', ...]
```

**Workaround — write token to file, read in Python subprocess:**

1. Write token via `write_file` tool (skips terminal masking):
   ```python
   token = "ghp_userProvidedTokenValue"  # from user's message
   with open('/tmp/pat_token.txt', 'w') as f:
       f.write(token)
   ```

2. Read from file and use subprocess (not inline commands):
   ```python
   import subprocess
   with open('/tmp/pat_token.txt') as f:
       token = f.read().strip()
   
   # Build remote URL
   remote_url = f'https://oauth2:{token}@github.com/username/repo.git'
   subprocess.run(['git', 'remote', 'set-url', 'origin', remote_url])
   r = subprocess.run(['git', 'push', '-u', 'origin', 'main'],
       capture_output=True, text=True, timeout=60)
   print(r.stdout, r.stderr)
   ```

3. For curl auth testing (same pattern):
   ```python
   cmd = ['curl', '-s', '-H', f'Authorization: Bearer {token}',
       'https://api.github.com/user']
   r = subprocess.run(cmd, capture_output=True, text=True)
   ```

4. **Write the Python script to a file first**, then execute it:
   ```bash
   python3 /tmp/git_push.py
   ```
   Do NOT inline the script via `<<'PYEOF'` heredoc which also gets masked.

**Alternative — write via base64:**
```bash
# Encode: echo -n 'ghp_tokenvalue' | base64
echo -n 'base64encodedvalue==' | base64 -d > /tmp/pat_token.txt
```
Then read from `/tmp/pat_token.txt` in Python.

**Why this works:** The `write_file` tool does not apply terminal-style
`***` redaction to its output. The Python `subprocess.run()` reads the
actual bytes from the file and sends them to the git/curl process without
passing through the terminal display layer.
