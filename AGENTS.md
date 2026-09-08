# QR Menu — Project AGENTS.md

Project rules for AI agents working in this repo. Inherits the global doctrine in
`C:\Users\HP\.config\opencode\AGENTS.md` (orchestrator, memory system, UI rules, safety).
This file adds only project-specific conventions.

---

## What this is

**QR menu + WhatsApp ordering system** for cafés & restaurants, Arabic-first (EN/AR, RTL).
Customers scan a QR code, browse the menu, add items **and offers**, review the order
(subtotal → discounts → total), and send it to the shop over WhatsApp. The admin panel
manages the shop profile, categories, items, prices, and 5 offer types.

## Stack (no build step)

- Vanilla HTML/CSS/JS in two files: `index.html` (public menu), `admin.html` (dashboard).
- Supabase (Postgres + Auth + Edge Functions) via supabase-js v2 UMD from CDN.
- `config.js` keeps `SUPABASE_URL` + `SUPABASE_ANON_KEY` (publishable — safe to commit).
- Hosted on GitHub Pages (`amworx/qr-menu`); `.nojekyll` at root is REQUIRED (repo contains a `.ts` file).

## File map

| Path | Role |
|---|---|
| `index.html` | Public menu + cart + order flow (single file) |
| `admin.html` | Admin dashboard (shop, categories, items, prices, deals) |
| `config.js` | Supabase URL + anon key shared by both pages |
| `docs/schema.sql` | Canonical schema (tables, RLS, migrations) |
| `supabase/functions/admin-login-gate/index.ts` | Email-only admin login edge function |
| `memory/` | events / lessons / patterns / decisions / playbooks / credentials (gitignored) |
| `AGENTS.md` | This file |
| `ASSISTANT_PROMPT.md` | Paste-ready briefing for any new AI assistant |
| `README.md` | Human-facing overview |

## Key architecture facts

- **i18n**: default Arabic (RTL). `lang` from `window.location.hash` (`#ar`/`#en`) else
  `localStorage 'qm-lang'`; admin uses `qm-admin-lang`. `dealSummary()` localizes offer text.
- **Cart**: `cart = { itemId: qty }` + `cartOffers = { dealId: 1 }` (offers have no quantity).
- **Pricing**: one `computeOrder()` snapshot (items, offers with savings, subtotal,
  discountLines, discount, total) feeds the FAB, the order sheet, and the WhatsApp message —
  they can never disagree. Discounts are additive and capped at `subtotal`; per-type math
  lives in `dealSavings()`; money-valued deals (fixed/bundle/min-fixed) only apply in the
  deal's own currency.
- **Orders**: `orders` table, bigserial `id` = the "Order #N" shown to the customer.
  Public can INSERT only; owner selects/manages (RLS). `sendWhatsApp()` inserts first,
  falls back to `T<epoch-tail>` if the insert fails.
- **Auth**: email-only admin login via the edge function (OTP/SMTP not configured).
  All RLS uses `owner_email = auth.email()`.
- **WhatsApp text**: strip surrogate pairs (`.replace(/[\uD800-\uDFFF]/g,'')`) and use
  BMP-safe markers (`★`, NOT 🎁) — the wa.me → api.whatsapp.com redirect mangles non-BMP emoji.

## Hard rules & gotchas

1. **DB is IPv6-only** from this network. Run SQL via the Management API:
   `POST https://api.supabase.com/v1/projects/{ref}/database/query` with the PAT from
   `memory/credentials.md` (never commit, never paste the PAT into chat).
2. **Never `Set-Content` / `Out-File` on repo files** (writes mojibake). Use Edit/Write tools.
3. **Never commit `memory/credentials.md`** (gitignored: service role, DB password, PAT).
4. `create policy if not exists` is invalid SQL — use DO blocks guarded by `pg_policies`.
5. PowerShell: use single-quoted here-strings (`@'...'@`) for SQL containing `$$`.
6. Emails are the only auth; the shop owner id `dfaab348-7fa3-46ba-b6cf-721b0b97ff55`
   (`amworxx@gmail.com`). Default currency SYP; currencies SYP/USD/TRY.

## Workflow

1. Read `memory/` first — events/lessons/patterns/playbooks contain hard-won gotchas.
2. Test locally on `http://localhost:8088` (serve this folder statically) in BOTH
   languages and at mobile 375px width.
3. Deploy = `git push origin main` → GitHub Pages auto-build (~20–60s) → verify live.
   Full playbook: `memory/playbooks.md` PB-001.
4. Commit only when the user asks; small commits, `fix:`/`feat:`/`docs:` style per git log.

## Memory discipline

Every meaningful action appends to `memory/events.md` with `EVT-YYYYMMDD-XXXX`.
Lessons → `lessons.md`; reusable patterns → `patterns.md`; decisions → `decisions.md`.
Reuse playbooks before creating new ones. Memory files are append-only — never rewrite.