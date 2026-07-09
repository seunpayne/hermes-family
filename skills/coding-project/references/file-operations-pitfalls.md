# File I/O Pitfalls

## Embedded Line Numbers When Using read_file + write_file

**THE BUG:** When you use `read_file` output directly as input to `write_file`, the file content includes line number prefixes (e.g., `1|content` → `1|1|content`). This corrupts the file, especially for CSS, TSX, and SQL files.

**How it happens:**
```python
# In execute_code
content = read_file("globals.css")['content']  # Returns "1|/* comment */\n2|..."
write_file("globals.css", modified_content)     # Writes line numbers back into file
```

Result: `1|1|/* comment */` instead of `/* comment */`

**Fix:** Never use `read_file` content directly in `write_file`. Instead:
1. Use `patch` for targeted edits
2. Use terminal `cat >> file << 'EOF'` for appending
3. For large rewrites, use `delegate_task` with `tool="write_file"` which handles content correctly

**Safe pattern for appending to a file:**
```bash
cat >> frontend/src/app/globals.css << 'CSSEOF'
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
CSSEOF
```

**Safe pattern for targeted edits:**
```python
# In execute_code, use patch(), never write_file() with read_file() output
from hermes_tools import patch
patch("file.tsx", old_string="old code", new_string="new code")
```

## Delegate Task File Corruption

Sub-agents (delegate_task) have a separate filesystem view. If a sub-agent modifies a file and the parent session's cached view doesn't refresh, subsequent patches may conflict. Always verify file freshness before editing files a sub-agent touched.

## Globals.css Merging

When adding CSS to an existing globals.css:
1. Never replace the entire file
2. Always append to the end
3. Check for existing class name conflicts (`.sw-card`, `.sw-btn-*`)
4. Use terminal `cat >>` for the append, not write_file
