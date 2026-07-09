# Nigerian SME Design Patterns

## Context

Nigerian market traders (provisions, textiles, electronics) have distinct design needs:
- Bright sunlight readability (outdoor markets, open stalls)
- Budget Android devices (2GB RAM, slow CPUs, small screens)
- Unreliable power/internet (4-6 hours/day, generator costs)
- Low tech comfort (plain language, intuitive UI)
- Cultural familiarity (market aesthetics, trust signals)

## Apollonia's Design Tokens — Sani General Stores (Reference)

**Business:** Provisions (food & kitchen essentials)
**Location:** Balogun Market, Lagos Island
**Customers:** Housewives, small chop sellers, walk-in

### Colour Palette

| Role | Hex | Rationale |
|------|-----|-----------|
| Primary | `#047857` (Emerald Green) | Trust, stability, prosperity — culturally associated with growth in Nigerian markets. High contrast in bright sunlight. |
| Secondary | `#F59E0B` (Amber Gold) | Warmth, value, quality — like palm oil, grains. Visible on budget Android screens. Complements green without clashing. |
| Accent | `#1F2937` (Charcoal) | Text, borders, UI elements. Softer than pure black (battery saving on OLED). Professional, grounded. |
| Background | `#F9FAFB` (Light Gray) | Clean, readable in market light. Not pure white (reduces glare). |

### Typography

**Font:** Inter (system font stack)
- Pre-installed on Android, 0ms load time
- Highly legible at small sizes (quick glances in market noise)
- Performance: no font download needed

### Cultural Element

**Geometric market stall pattern** in header backgrounds:
- Inspired by Balogun Market's grid-like stall structure
- 10% opacity, monochrome charcoal on light gray
- Familiar without being nostalgic
- Not distracting during transactions

### Tone

**IS:** Trustworthy, Fast, Clear
**NOT:** Corporate, Complicated, Slow

### Dark Mode

**YES — Strongly Recommended**
- Battery conservation (4 hrs internet/day, generator costs)
- Eye strain reduction (dawn to dusk market hours)
- OLED savings: 30-60% on budget Android
- Implementation: Toggle in Settings, default to system preference

## Copy & Content Guidelines

### Language Choices

| Use | Avoid | Reason |
|-----|-------|--------|
| "Stock" | "Inventory" | Market language, everyday term |
| "Money In/Out" | "Revenue/Expenses" | Plain English, trader language |
| "My Shop" | "Dashboard" | Ownership, familiarity |
| "Saved" | "Success" | Action-oriented, not technical |
| "No internet. Your work is saved and will send when connection returns." | "Sync failed. Error code: 503" | Reassuring, actionable, friendly |

### Error Messages

- Plain English, no codes
- Actionable guidance
- Friendly tone (not childish)

### Success States

- Subtle (✓ Saved with green check)
- Not celebratory animations (wastes battery, unprofessional)

## Device Constraints

**Target:** Android budget (2GB RAM minimum)
- Samsung big screen (Mallam Sani) — likely 2-3GB RAM
- Tecno (Emeka) — likely 2GB RAM, slower CPU

**Optimizations:**
- App size: <50MB download
- No heavy animations
- No large image assets
- System fonts only (no custom font downloads)
- Dark mode for battery saving

## Connectivity Constraints

**Internet:** 4 hours/day (NEPA unreliable)
- Offline-first architecture required
- All writes go to local database first
- Background sync when connectivity detected
- No UI blocking during sync
- Clear sync status indicator

## Accessibility

- Large touch targets (market noise, quick glances)
- High contrast colours (sunlight readability)
- Clear labels (low tech comfort)
- Minimal training required (intuitive flow)

## Related

- coding-project skill: Section 2 (Design Language) requirements
- web-builder skill: frontend-design-guidelines
- ui-ux-design-intelligence skill: UX decisions
