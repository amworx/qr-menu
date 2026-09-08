# ASSISTANT PROMPT — QR Menu (Judy Joy / جودي جوي)

> Paste this whole file into a new AI coding assistant to bring it up to speed.
> It is intentionally self-contained; open the files it points to for deep dives.
> Repo: https://github.com/amworx/qr-menu · Live menu: https://amworx.github.io/qr-menu/ · Admin: https://amworx.github.io/qr-menu/admin.html

---

You are now the senior engineer for **QR Menu (Judy Joy / جودي جوي)** — a digital QR
menu + WhatsApp ordering system for cafés & restaurants, Arabic-first (EN/AR, RTL).
Before writing any code, read `AGENTS.md`, `memory/` (events/lessons/patterns/decisions/playbooks),
and `docs/schema.sql` — they contain architecture, hard-won gotchas, and the deploy workflow.

## What the product does
Customers scan a QR code → browse a bilingual menu → add items AND offers to the cart →
review the order (subtotal → per-offer discounts → total) → send it to the shop's WhatsApp.
Each order gets a sequential number (#N) and is stored in Supabase. The admin dashboard
manages shop profile, categories, items, prices, and 5 offer types. Admin login is
email-only (no password, no OTP — SMTP not configured).

## Stack & runtime facts (NO build step)
- **Files**: `index.html` (public menu + cart + order flow), `admin.html` (dashboard),
  `config.js` (Supabase URL + anon key). Vanilla HTML/CSS/JS, supabase-js v2 UMD from CDN.
- **Backend**: Supabase Postgres + Auth + one Edge Function (`supabase/functions/admin-login-gate`).
- **Hosting**: GitHub Pages. `.nojekyll` is REQUIRED at root (repo contains `.ts`).

## Folder map
| Path | Role |
|---|---|
| `index.html` | Public menu + cart + order flow |
| `admin.html` | Admin dashboard |
| `config.js` | Supabase URL + anon key (PUBLISHABLE) |
| `docs/schema.sql` | Canonical schema + RLS (source of truth) |
| `supabase/functions/admin-login-gate/index.ts` | Email-only login edge function |
| `memory/` | events/lessons/patterns/decisions/playbooks + `credentials.md` (GITIGNORED secrets) |
| `AGENTS.md` | Agent rules (read first) |
| `ASSISTANT_PROMPT.md` | This file |
| `README.md` | Human overview |

## Data model (details in docs/schema.sql)
- `shops`, `categories`, `items`, `item_prices` (multi-currency), `deals`, `orders`.
- `deals.deal_type`: `percent` | `fixed` | `bogo` | `bundle` | `min_order`, with per-type
  nullable fields (`applies_to` item/category/all, `item_id`, `buy_qty/get_qty`, `min_total`,
  `reward_type`, `bundle_price`, `bundle_items jsonb`).
- `orders`: bigserial `id` = the customer-facing "Order #N"; jsonb payloads
  (`items`, `offers`, `discount_lines`), `subtotal`/`discount`/`total`, `note`, `created_at`.
- **RLS**: public SELECT on active shops/categories/items/item_prices/deals; anon INSERT
  on `orders` only; owners manage everything via `shop_id in (select id from shops where owner_email = auth.email())`.

## Secrets & DB access (CRITICAL)
- `config.js` anon key is publishable — fine to read/commit.
- `memory/credentials.md` (gitignored) holds: project id `pxgwxcurhzphmtvowdri`,
  service-role key, DB password, Management API PAT. **Never commit it; never paste the
  PAT or service-role key into chat.**
- The Postgres host is **IPv6-only** from this machine, so run SQL via the Management API:
  ```powershell
  Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/pxgwxcurhzphmtvowdri/database/query" `
    -Headers @{Authorization="Bearer <PAT from memory/credentials.md>"} -ContentType "application/json" `
    -Body (@{query=$sql} | ConvertTo-Json -Compress)
  ```
- Existing data (live): shop id `dfaab348-7fa3-46ba-b6cf-721b0b97ff55`, owner `amworxx@gmail.com`,
  currencies SYP/USD/TRY (default SYP); 3 live offers (BOGO Cheese Manakish buy2get1, 10% off all,
  100 SYP off all); 9 items with SYP prices.

## Architecture essentials
- **i18n**: default Arabic, RTL. Public `lang` = `window.location.hash` (`#ar`/`#en`) else
  `localStorage 'qm-lang'`; admin uses `qm-admin-lang`. Localize ALL UI (labels, toasts, confirms).
- **Cart**: `cart = { itemId: qty }` + `cartOffers = { dealId: 1 }` (offers have no qty).
- **Pricing**: ONE `computeOrder()` snapshot → itemsList, offers (with `savings`), `subtotal`,
  `discountLines`, `discount`, `total`; it feeds the FAB, the order sheet, and the WhatsApp
  message so all three agree. Discounts are additive, capped at `subtotal`; per-type math in
  `dealSavings()` (percent/fixed on scope subtotal; BOGO needs the item in cart with
  qty ≥ buy+get; bundle needs ALL items present; min_order past threshold). Money-valued
  deals (fixed/bundle/min-fixed) apply only in the deal's own currency.
- **Order flow**: send → `insert` into `orders` (anon OK) → get `id` → WhatsApp message
  opens with `*New Order #<id>*` + items + per-offer savings + subtotal + total; fallback
  `T<epoch-tail>` number if the insert fails (order must never break).
- **WhatsApp text**: strip surrogate pairs (`.replace(/[\uD800-\uDFFF]/g,'')`) and use
  `★` markers, NOT `🎁` — the wa.me → api.whatsapp.com redirect replaces non-BMP emoji with `�`.

## Rules
- Arabic-first with full EN parity; test BOTH languages and RTL; test mobile 375px.
- Never commit `memory/credentials.md` or any secret. Never `Set-Content`/`Out-File` on
  repo files (mojibake) — use edit tools only.
- Commit ONLY when asked; small `fix:`/`feat:`/`docs:` commits matching the git log style.
- `create policy if not exists` is invalid SQL — use DO blocks guarded by `pg_policies`.
- PowerShell SQL here-strings: use single-quoted `@'...'@` when the SQL contains `$$`.

## Local test + deploy
1. Serve the folder statically → `http://localhost:8088` (e.g. `node C:\Users\HP\AppData\Local\Temp\opencode\server.js`).
2. `git push origin main` → GitHub Pages auto-builds (~20–60s).
3. Poll: `gh api repos/amworx/qr-menu/pages/builds --jq '.[0] | {status, commit: .commit[0:7]}'` until `built`.
4. Verify raw + live with a cache-buster, end-to-end in a browser (console clean).
5. Append to `memory/events.md` (`EVT-YYYYMMDD-XXXX`); add lessons/patterns when valuable.
   Full workflow: `memory/playbooks.md` PB-001.

## Session handoff (2026-09-07) — what was just built

Full file: `HANDOFF.md` at repo root. Summary:

1. **Admin items UX** — search/filter/sort/pagination toolbar on the items tab.
2. **Offers system** — 5 deal types in one `deals` table + one flexible admin modal + localized
   public summary (`dealSummary()`). Types: `percent | fixed | bogo | bundle | min_order`.
3. **Clickable offers** — tapping an offer card adds it to the order (`cartOffers`), count in the
   FAB badge, 🎁 line in the order sheet + WhatsApp, remove ✕.
4. **List/grid view toggle** — CSS-class toggle persisted in `localStorage 'qm-view'`.
5. **Consistent offer CTA + overlap fix** — flex-column deal cards, `margin-top:auto` add button,
   guaranteed 14px min gap above it (was 0px on the tallest card).
6. **One-tap remove** — per-line ✕ in the order sheet.
7. **Order numbers** — `orders` table, bigserial `id` = "Order #N"; anon can INSERT only, owner
   manages via RLS; `sendWhatsApp()` inserts first, falls back to `T<epoch-tail>` if it fails.
8. **Pricing engine** — one `computeOrder()` snapshot feeds FAB / order sheet / WhatsApp; discounts
   additive, capped at subtotal; per-type math in `dealSavings()`; money-valued deals apply only in
   their own currency.
9. **WhatsApp message upgrade** — numbered header, per-offer savings, subtotal/discount/total; strips
   non-BMP emoji and uses `★` markers (wa.me redirect mangles 🎁).
10. **Onboarding docs** — `HANDOFF.md`, `AGENTS.md`, `ASSISTANT_PROMPT.md`, refreshed `README.md`.

**Live state**: HEAD `bb1063f` pushed & Pages `built`. Production data: 9 items, 3 offers (BOGO
Cheese Manakish buy 2 get 1 · 10% off all · 100 SYP off all). `orders` table empty on purpose
(test rows truncated with `restart identity` → next real order is **#1**). Verified math:
105,000 − (25,000 + 10,500 + 100) = **69,400 SYP**.

**Likely next steps (confirm with the owner first)**: admin **Orders** view (table already exists
and is being populated), bundle/BOGO live data, true OTP login once SMTP is configured.

**Memory index**: events → EVT-…-0015 · lessons → LSSN-…-023 · patterns → PAT-…-011 ·
decisions → DEC-001…003 · playbooks → PB-001…003.