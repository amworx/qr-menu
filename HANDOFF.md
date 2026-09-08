# QR Menu — Handoff (2026-09-07)

Snapshot for the next engineer / AI assistant. Read `AGENTS.md` + `ASSISTANT_PROMPT.md` first,
then this. The `memory/` files are the running history (events/lessons/patterns/decisions/playbooks).

---

## 1. Live state right now

- **HEAD**: `bb1063f` on `main` — pushed, GitHub Pages build `built`.
- **Live menu**: https://amworx.github.io/qr-menu/ · **Admin**: https://amworx.github.io/qr-menu/admin.html
- **Data (production Supabase, shop `dfaab348-7fa3-46ba-b6cf-721b0b97ff55`)**:
  - 9 menu items with SYP prices, 4 categories.
  - 3 live offers: **Offer #1** (BOGO: buy 2 get 1 Cheese Manakish), **Mega Offer** (10% off all),
    **24 Offer** (100 SYP off all). No bundle/min_order deals in production yet.
  - `orders` table **empty** (all session test rows truncated with `restart identity`, so the
    next real order will be **#1**).
- All totals verified end-to-end this session: 105,000 SYP minus (25,000 BOGO + 10,500 10% + 100 fixed) = **69,400 SYP**.

## 2. What shipped in this session (chronological)

1. **Admin items UX** — search/filter/sort/pagination toolbar on the items tab (`PAT-006`, EVT-0009).
2. **Offers system** — 5 deal types in one `deals` table + one flexible admin modal + localized
   public summary via `dealSummary()` (`PAT-007`, EVT-0009). Types: `percent | fixed | bogo | bundle | min_order`.
3. **Clickable offers** — tapping an offer card adds it to the order as a line (`cartOffers`), count
   in the FAB badge, 🎁 line in the order sheet + WhatsApp, remove ✕ (`PAT-008`, EVT-0010).
4. **List/grid view toggle** — CSS-class toggle, persisted in `localStorage 'qm-view'` (`PAT-009`, EVT-0010).
5. **Consistent offer CTA + overlap fix** — all deal cards flex-column with `margin-top:auto` on the
   add button and a guaranteed 14px min gap (was 0px on the tallest card) (`EVT-0011`, EVT-0013, LSSN-019, LSSN-021).
6. **One-tap remove** — per-line ✕ in the order sheet, no more pressing minus to zero (`EVT-0012`, LSSN-020).
7. **Order numbers** — new `orders` table, bigserial `id` = the customer-facing "Order #N"; anon can
   INSERT only, owner manages via RLS; `sendWhatsApp()` inserts first, falls back to `T<epoch-tail>`
   if the insert fails (`EVT-0014`, `PAT-011`).
8. **Pricing engine** — `computeOrder()` snapshot (items, offers with savings, subtotal, discountLines,
   discount, total) feeds FAB / order sheet / WhatsApp so they always agree; discounts additive, capped
   at subtotal; per-type math in `dealSavings()`; money-valued deals apply only in their own currency
   (`EVT-0015`, LSSN-023, `PAT-010`).
9. **WhatsApp message upgrade** — numbered header, per-offer savings, subtotal + discount breakdown +
   total; non-BMP emoji stripped and `★` markers used because wa.me redirect mangles 🎁 (LSSN-022).
10. **Onboarding docs** — this `HANDOFF.md`, `AGENTS.md`, `ASSISTANT_PROMPT.md`, refreshed `README.md`.

## 3. Key architecture (in one paragraph each)

- **Files**: `index.html` (menu + cart + order flow), `admin.html` (dashboard), `config.js` (Supabase
  URL + publishable anon key). Vanilla HTML/CSS/JS, no build.
- **Auth**: email-only login via Edge Function `admin-login-gate` (no OTP — SMTP not configured).
  RLS everywhere: `owner_email = auth.email()`; public read for menu data; anon INSERT for `orders`.
- **Cart**: `cart = {itemId: qty}` + `cartOffers = {dealId: 1}`; all consumers use `computeOrder()`.
- **Deploy**: push `main` → GitHub Pages auto-builds; `.nojekyll` required (repo has `.ts`).

## 4. DB access (IMPORTANT)

- Postgres host is **IPv6-only** from this machine → run SQL via the Management API:
  `POST https://api.supabase.com/v1/projects/pxgwxcurhzphmtvowdri/database/query`, header
  `Authorization: Bearer <PAT>`, body `{"query":"..."}`. PAT in `memory/credentials.md` (gitignored).
- Never commit `memory/credentials.md`; never paste the PAT / service-role key into chat.

## 5. Known next steps (confirm with owner before building)

1. **Admin Orders view** — the `orders` table exists and is being populated; an admin tab to list them
   (search by number/date, status tracking optional) is the most valuable next feature.
2. **Bundle / BOGO live data** — engine + UI are ready; production offers only exercise percent/fixed/BOGO-on-one-item.
3. **True OTP login via SMTP** — replace the interim email-only edge-function login once SMTP is configured.

## 6. Session memory index (most recent)

- `memory/events.md` → up to **EVT-20260907-0015**
- `memory/lessons.md` → up to **LSSN-20260907-023**
- `memory/patterns.md` → up to **PAT-20260907-011**
- `memory/decisions.md` → **DEC-001…003** (email-only login, .nojekyll, Arabic-first admin)
- `memory/playbooks.md` → **PB-001…003** (deploy+verify, login, i18n)