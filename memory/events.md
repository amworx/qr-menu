# Events — qr-menu

## EVT-20260907-0001

- **timestamp**: 2026-09-07
- **mode**: BUILD
- **action**: Major upgrade — Supabase backend, admin dashboard, multi-currency, deals
- **summary**: Rebuilt QR Menu from hardcoded v0.1 to a fully dynamic Supabase-backed product. Created `admin.html` (single-file dashboard, ~800 lines) with OTP email auth, full CRUD for shop settings/categories/items/deals/currencies. Created `config.js` (shared Supabase credentials). Rewrote `index.html` to read all data from Supabase (shop info, categories, items with multi-currency prices, active deals). Created `docs/schema.sql` (5 tables + RLS policies + seed data). Currency selector with per-item visibility toggles. Deal management with percent/fixed discounts and date ranges. Bilingual EN/AR throughout. WhatsApp order composition with cart.
- **result**: Pushed as `c3a8325` to `amworx/qr-menu`. Live at `https://amworx.github.io/qr-menu/` and `https://amworx.github.io/qr-menu/admin.html`. Both HTTP 200 verified.
- **files**: `index.html`, `admin.html`, `config.js`, `docs/schema.sql`
- **errors**: None
- **tags**: supabase, admin-dashboard, multi-currency, deals, otp-auth, major-upgrade

## EVT-20260907-0002

- **timestamp**: 2026-09-07
- **mode**: BUILD / DEPLOY / INFRA
- **action**: Provision dedicated Supabase project + migrate + verify + deploy new config
- **summary**: User created new dedicated Supabase project `qr_menu` (ref pxgwxcurhzphmtvowdri). Ran full SQL migration via Management API using PAT (sbp_...) because the DB host resolves only to IPv6 and this network had no IPv6 route — the Management API over api.supabase.com (IPv4) worked. Verified: 5 tables, shop seed, categories, 2 RLS policies per table. Fixed Supabase SDK CDN: unpkg UMD bundle was blocked by browser ORB (ERR_BLOCKED_BY_ORB, MIME issue) — switched to jsDelivr, which loads correctly. Verified end-to-end in browser: public menu loads real data (Al-Sahari Café, 9 seeded items with SYP/USD/TRY prices), currency switch works, cart + order sheet + WhatsApp URL composition correct (wa.me/963992656853), AR/RTL + Arabic font + Arabic numerals work, Featured badge shows, zero console errors. Verified data layer via service-role REST CRUD (insert/read/nested/update/cascade delete). Commit `2c48692` pushed (config.js new project + CDN fix). Live verified on GitHub Pages.
- **result**: Success — dedicated backend live, menu + admin operational.
- **files**: `config.js` (project switch), `index.html` + `admin.html` (CDN swap), `memory/credentials.md` (new project creds)
- **errors**: DRAGNET: DB host IPv6-only + no IPv6 route → Management API PAT workaround; unpkg ORB block → jsDelivr. Both solved.
- **lessons**: LSSN-20260907-001 (Management API + PAT can run SQL over IPv4 when DB host is IPv6-only); LSSN-20260907-002 (use jsDelivr not unpkg for @supabase/supabase-js UMD — ORB blocks unpkg 302 MIME)
- **tags**: supabase-migration, management-api, pat, ipv6-workaround, jsdelivr, deploy, verify

## EVT-20260907-0003

- **timestamp**: 2026-09-07
- **mode**: BUILD / UI / DEPLOY
- **action**: Public menu UI overhaul — Arabic default, theme toggle, quantity stepper, editorial ticket design
- **summary**: Rewrote `index.html` visual design based on ui-design.md playbook per user feedback: Arabic default (`lang='ar' dir='rtl'`, hash > localStorage > `'ar'`), light/dark theme with localStorage persistence (`qm-theme`, default dark espresso), quantity stepper (`add-btn` ↔ `− / input / +`) with direct number entry, editorial café-ticket item cards (dot leaders, emoji image placeholders, featured ring, sticky category rail, floating cart pill, bottom-sheet order modal, horizontal deal cards, 2-col grid ≥760px / single-column mobile ≤390px). Verified end-to-end on localhost: dark theme render, theme toggle + persistence, currency switch (SYP/USD/TRY), direct qty entry, order sheet steppers, WhatsApp URL composition, mobile 390px single-column + desktop 2-col, zero console errors. **Fixed 4 cart-state bugs found during verification**: (1) `setCartQty()` (direct input) never called `updateCartBar()` → badge/total stayed stale; (2) `incCart()` didn't refresh the open order sheet (asymmetric with `decCart()`); (3) `updateCartBar()` early-returned on empty cart without resetting badge/total text; (4) removed useless `oninput="updateCartBar()"` (fired before cart object updated). Also capped `incCart` at 99 to match input max. Commit `e70a405` pushed; GitHub Pages rebuilt (~45s lag, verified via raw `main` then live). Live verified: dark theme, 9 items, dot leaders, stepper working, no overflow.
- **result**: Success — new menu UI live at `https://amworx.github.io/qr-menu/`.
- **files**: `index.html`
- **errors**: GitHub Pages served stale index.html (~21.9KB) for ~45-60s after push despite cache-buster (raw.githubusercontent updated immediately; deployment lag).
- **lessons**: LSSN-20260907-003 (cart/UI mutators must refresh every consumer — badge, totals, order sheet); LSSN-20260907-004 (GitHub Pages redeploy lags ~1 min after push — verify via raw `main` first, then poll live with cache-buster)
- **tags**: ui-overhaul, rtl, theme-toggle, stepper, bugfix, deploy, verify

## EVT-20260907-0004

- **timestamp**: 2026-09-07
- **mode**: BUILD / DATA / UI / DEPLOY
- **action**: Store renamed to Judy Joy; currency switcher moved to top bar as single control
- **summary**: Per user request: (1) renamed shop in Supabase `shops` (PATCH via service-role REST) — `name`="Judy Joy", `name_ar`="جودي جوي" (verified via UTF-8 temp-file check; PowerShell console shows `????` for Arabic but DB stored correct UTF-8). (2) Moved currency selector out of the hero into the top `.controls` bar, placed directly after the theme toggle, as one compact pill (`.ctl.cur`) showing the active currency code; clicking it cycles through `shop.currencies` (SYP→USD→TRY). Added `cycleCurrency()` + `renderCurrencyBtn()` (hides if `<2` currencies or selector disabled), removed hero `currencyRow` + unused `.currency-row/.currency-btn` CSS. Verified localhost + live: title/hero show جودي جوي, controls order [theme, currency, lang], cycle updates prices, zero console errors (only favicon 404). Commit `0e8c31e` pushed; Pages lag ~50s then verified live `?cb=judy-joy-final`.
- **result**: Success — live at https://amworx.github.io/qr-menu/
- **files**: `index.html`, Supabase `shops` row
- **errors**: None (favicon 404 on localhost only, cosmetic)
- **lessons**: LSSN-20260907-005 (PowerShell console mangles Arabic — verify Supabase strings via UTF-8 file + Read)
- **tags**: rename, currency, topbar, rtl, supabase-patch, deploy, verify