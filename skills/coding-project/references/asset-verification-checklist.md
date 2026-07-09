# Asset Verification Checklist

When the user uploads image files, icons, screenshots, or other visual assets for a project:

## 1. Copy assets to the project
```bash
mkdir -p frontend/public/images/icons
cp /path/to/attachments/*.png frontend/public/images/
```

## 2. Cross-reference every asset
After sub-agent migration completes (or after any page rebuild), verify EVERY user-provided asset is referenced in the code:

```bash
# List provided assets
ls frontend/public/images/icons/
ls frontend/public/images/*.png

# Check which are referenced in the page
grep -oP "src=\"/images/[^\"]+" page.tsx | sort -u
grep -oP "'/images/[^']+" page.tsx | sort -u
```

## 3. Common missing assets
- `streetwise.png` (logo) → must appear in nav and footer
- `screenshot-admin-dashboard.png` → must appear in screenshot showcase or hero
- `security-illustration.png` → must appear in security/pillars section
- `hero-illustration.png` → must appear in hero section
- Icon PNGs (12 in `/images/icons/`) → must replace emoji in feature pills grid

## 4. Verify assets are tracked in git
Before push:
```bash
git ls-files frontend/public/images/
```
Any untracked assets won't deploy.

## 5. Verify assets are accessible on deployment
Middleware's `isPublicRoute` matcher must include `/images(.*)` or assets will be redirected to sign-in.
Check reference: `middleware-static-assets.md`
