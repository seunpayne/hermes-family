# GitHub Repo Access Diagnostics

When `git clone` fails on a GitHub URL, don't retry blindly.
Run this diagnostic chain in order to isolate the cause:

## Diagnostic Sequence

```
1. web_extract on the repo URL
   → 404 with "page not found" = repo doesn't exist OR is private
   → Returns content = repo is public

2. browser_navigate to the repo URL
   → "Page not found" (GitHub's 404 page) = definitively doesn't exist
   → Shows sign-in prompt = private repo, need auth
   → Shows repo contents = public and accessible

3. Check auth in the shell:
   env | grep -iE 'github|token|gh_'
   git config --global --list | grep credential
   ls ~/.ssh/
   which gh && gh auth status

4. If GITHUB_TOKEN exists in agent env but NOT in shell:
   → Write a script that reads os.environ at runtime, not inline
   → printf '#!/bin/bash\ntoken="$GITHUB_TOKEN"\ngit clone "https://x-access-token:${token}@github.com/..."' > /tmp/clone.sh
   → bash /tmp/clone.sh

5. If all auth checks fail + browser shows private:
   → Ask user to make repo public, provide a token, or confirm the URL
```

## Common Pitfalls

- **GIT_TERMINAL_PROMPT=0** disables interactive credential prompts but doesn't inject tokens
- **Hermes redaction**: env vars containing "TOKEN" may show as `***` in output but still exist
- **Shell vs agent env**: `terminal()` may not inherit all env vars from the agent process
- **404 ≠ auth failure**: GitHub returns 404 (not 403) for private repos you can't see, to avoid leaking existence
