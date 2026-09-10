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
## EVT-20260907-0005

- **timestamp**: 2026-09-07
- **mode**: AUTH / INFRA / DEPLOY
- **action**: Fix admin sign-in email � link now opens admin dashboard and auto-completes session
- **summary**: User reported the Supabase sign-in email sent a link to the app instead of the admin dashboard. Root cause: (1) default magic-link email template shows only a link (no OTP token); (2) site_url was default http://localhost:3000 so the link was dead; (3) mailer_otp_length was 8 while the admin form expected 6. Attempted to replace the email template with an OTP-code template via Management API PATCH � blocked by plan: "Email template modification is not available for free tier projects using the default email provider. Please upgrade your plan or configure a custom SMTP provider." Applied allowed config: site_url=https://amworx.github.io/qr-menu, uri_allow_list=both qr-menu URLs, mailer_otp_length=6. Updated admin.html: sendOTP passes emailRedirectTo=https://amworx.github.io/qr-menu/admin.html; init now handles magic-link params (?token=/type= ? verifyOtp, ?code= ? exchangeCodeForSession) and auto-shows dashboard; graceful error + history.replaceState cleanup; honest copy ("secure sign-in link") + hint under code field. Verified localhost (normal load + fake-token path errors gracefully, zero console errors) and live (rebuild ~50s, admin renders, new code markers present). Commit 96b01dd pushed.
- **result**: Success � clicking the emailed link now opens the admin dashboard and logs in. OTP-code-in-email NOT achievable on free tier + default provider (needs custom SMTP or paid plan) � offered as follow-up if user insists on code emails.
- **files**: admin.html, Supabase auth config
- **errors**: Management API 4xx "Email template modification is not available for free tier�" � worked around with link-into-admin approach.
- **lessons**: LSSN-20260907-006 (free-tier default email provider cannot customize templates; email must be magic-link-based)
- **tags**: auth, magic-link, email-template, supabase-config, otp, deploy, verify

## EVT-20260907-0006

- **timestamp**: 2026-09-07
- **mode**: AUTH / EDGE-FUNCTION / INFRA / DEPLOY
- **action**: Interim email-only login (OTP disabled) — Supabase Edge Function mints a real session server-side
- **summary**: User requested OTP login disabled until SMTP is set up, and that login require only the admin email. Initial idea (relax RLS / service-role in client) rejected as insecure. Implemented the secure path: a new Supabase Edge Function `admin-login-gate` (supabase/functions/admin-login-gate/index.ts) that (1) verifies the typed email equals `shops.owner_email` server-side (403 otherwise), (2) ensures the auth user exists/confirmed via `auth.admin.createUser({email, email_confirm:true})` (no email sent), (3) mints a magic-link token via `auth.admin.generateLink`, (4) exchanges it server-side with a `redirect: 'manual'` fetch to `/auth/v1/verify?token=...&type=magiclink` and reads `access_token`/`refresh_token` from the 303 Location fragment, (5) returns the session tokens. Deployed via Management API `POST /v1/projects/{ref}/functions/deploy` (multipart file+metadata, verify_jwt:false). Reworked admin.html auth screen: removed OTP section + sendOTP/verifyOTP, single Email field + Login button calling `loginWithEmail()` which POSTs to the function then `sb.auth.setSession({access_token, refresh_token, expires_at})`. **Key discovery during debugging**: `auth.admin.generateLink().properties.hashed_token` equals the raw token, but client-side `verifyOtp({type:'magiclink'})` POST fails "Token has expired or is invalid" — the hosted project is PKCE/implicit so redemption must go through the 303 GET `/auth/v1/verify?token=&type=` (browser magic-link flow), then read fragment. Verify endpoint returns the full session only via that flow. Verified end-to-end: wrong email rejected (403 "This email is not the admin"), admin email logs in → dashboard loads all Judy Joy data (shop settings, categories, 9 items with SYP/USD/TRY prices). Also hit a GitHub Pages deploy failure: adding the `.ts` file made the repo build-time Jekyll choke without `.nojekyll` — fixed by adding `.nojekyll` (commit 427ac44). Commit 5f76381 (login feature) + 427ac44 (.nojekyll) pushed.
- **result**: Success — email-only login live; wrong email rejected, admin email → dashboard. OTP email flow removed until SMTP configured.
- **files**: `supabase/functions/admin-login-gate/index.ts` (new), `admin.html`, `.nojekyll` (new), Supabase edge function `admin-login-gate` (v2)
- **errors**: (1) Management API JSON parse error via PowerShell inline metadata (mangled quotes) — solved with metadata from file + ASCII no-BOM; (2) bundler "Relative import path @supabase/supabase-js not prefixed" — fixed with full esm.sh URL; (3) `verifyOtp` POST "Token has expired or is invalid" — root cause PKCE: must use 303 GET /verify + read fragment, see summary; (4) GitHub Pages errored build after adding `.ts` — fixed with `.nojekyll`.
- **lessons**: LSSN-20260907-007 (supabase-js on Edge Runtime: import via https://esm.sh/@supabase/supabase-js@2, not bare specifier); LSSN-20260907-008 (hosted Supabase magic-link redemption is a 303 GET /auth/v1/verify returning session in Location#fragment — client `verifyOtp` for magiclink fails; exchange server-side and read the fragment); LSSN-20260907-009 (adding `.ts`/Jekyll-hostile files to a GitHub Pages repo requires `.nojekyll` or the build errors)
- **tags**: auth, email-only-login, edge-function, magic-link, setSession, rls, nojekyll, deploy, verify

## EVT-20260907-0007

- **timestamp**: 2026-09-07
- **mode**: BUILD / UI / I18N / DEPLOY
- **action**: Admin dashboard Arabic-first i18n (EN/AR toggle); fix Deals tab async render; fix null-shop race on load
- **summary**: (1) **Arabic-first admin**: added `lang` state (default `'ar'`, persisted `qm-admin-lang`), full `I18N` dictionary (~100 keys), `t()` helper, `applyLang()` (sets `<html lang/dir>`, title, static nodes via IDs + `data-i18n`, re-renders active tab when data loaded), `toggleAdminLang()` (header + auth screen buttons). All render functions, modals, toasts, confirms now use `t()`. Auth server messages mapped (403 → "هذا البريد الإلكتروني ليس بريد المشرف"). (2) **Deals tab `[object Promise]` bug**: `showTab('deals')` did `c.innerHTML = renderDealsTab()` where the render function is `async` — innerHTML got the unresolved Promise. Fixed with loading placeholder + `.then(html => c.innerHTML = html)`. (3) **Null-shop race**: on reload with a persisted session, `showDashboard()` runs twice (INIT + `onAuthStateChange` SIGNED_IN); second call's `applyLang()` re-rendered the tab before `currentShop` loaded → `Cannot read properties of null`. Guarded re-render on `currentShop`. Verified localhost: auth screen Arabic RTL, EN/AR toggle flips title/sidebar/content/modals, shop/categories/items/deals/currencies tabs all Arabic, mobile 390px tab bar Arabic (`ظاهر`), logout → Arabic auth → login back to Arabic dashboard, zero console errors. Verified live `https://amworx.github.io/qr-menu/admin.html`: Arabic auth, login, full Arabic dashboard. Commit `54abb39` pushed; Pages build `built` (~20s). Live 400 `refresh_token_not_found` at startup is benign (stale token from pre-change manual test session; supabase-js clears it and shows login).
- **result**: Success — admin dashboard is Arabic by default with working EN/AR toggle on both screens.
- **files**: `admin.html`
- **errors**: (1) `showTab('deals')` rendered `[object Promise]` (async renderer) — fixed with `.then()`; (2) `applyLang()` re-render threw on null shop (double `showDashboard` race) — guarded on `currentShop`.
- **lessons**: LSSN-20260907-010 (async tab renderers need `.then()`); LSSN-20260907-011 (guard `applyLang`-style re-renders on loaded data; beware double `showDashboard` from INIT + SIGNED_IN); LSSN-20260907-012 (startup `refresh_token_not_found` 400 is benign stale-token noise)
- **tags**: i18n, arabic-first, rtl, admin-dashboard, lang-toggle, bugfix, async-render, deploy, verify

## EVT-20260907-0008

- **timestamp**: 2026-09-07
- **mode**: BUILD / UI / RESPONSIVE / DEPLOY
- **action**: Mobile CRUD UI overhaul — tables become stacked labeled cards; header wraps; tab bar sticky; touch-friendly controls
- **summary**: User reported CRUD UI/UX bad on phone, hard-to-read fields, overlaps. Diagnosed at 390px: items table was 502px wide in a 390px viewport → `main-content` overflowed horizontally, and in RTL the table's left edge ran to x=-127 (data clipped); dash header title was squeezed to 85px and wrapped into ~3 lines (header 70px), and `--header-h` var defaulted wrong. Fixes in `admin.html`: (1) tables wrapped in `.table-wrap`; (2) at ≤768px tables become stacked cards — `display:block` on table/thead/tbody/tr/td, `thead{display:none}`, each `td` is a labeled row (`::before{content:attr(data-label)}` with `justify-content:space-between`), last cell (actions) stacks label above buttons; every `<td>` in categories/items/deals renderers got `data-label="${t(...)}"`; added `actions` i18n key (إجراءات). (3) `.dash-header` wraps to two rows on phones (title 100% width top, user-info right-aligned below); `--header-h` computed in `showTab()`/`applyLang()` from measured header height (guarded >0) so sticky `.mobile-tabs{top:var(--header-h)}` sits exactly below the header. (4) Touch/readability: inputs font-size 16px (iOS zoom prevention), `.btn` min-height 42px, `.toggle` 44×24, `.modal` full-width with 18px padding, `.modal-actions .btn{flex:1}`, `.btn-group{flex-wrap:wrap}`. Verified localhost + live at 390px: zero body/main overflow on shop/categories/items/currencies; cards show Arabic labels (الترتيب/الاسم/التصنيف/متاح/مميّز/الأسعار/إجراءات); sticky offset exact (header 80px, tabs at 81px); price rows in item modal fit (31→360px); console clean. Desktop regression check: sidebar visible, mobile-tabs hidden, thead visible, `td` display table-cell, no overflow. Commit `c6e7795` pushed; Pages build `built` (~30s).
- **result**: Success — mobile CRUD is readable stacked-card layout; zero console errors; desktop unchanged.
- **files**: `admin.html`
- **errors**: sticky offset initially wrong (var fixed at 104px while header measured 80px) because `applyLang()` computed it before the dashboard was visible (rect 0) — moved computation into `showTab()` with height>0 guard.
- **lessons**: LSSN-20260907-013 (on mobile, convert admin CRUD tables to labeled cards — never let a table overflow horizontally); LSSN-20260907-014 (set a CSS var for a sticky element's offset from a measured parent only after layout is settled; guard rect height >0)
- **tags**: responsive, mobile-ui, crud, table-to-cards, data-label, sticky-tabs, header-wrap, deploy, verify

## EVT-20260907-0009

- **timestamp**: 2026-09-07
- **mode**: BUILD / FEATURE / DB-MIGRATION / DEPLOY
- **action**: Items admin UX (search/filter/sort/pagination) + full offers system (5 deal types) + DB migration + public menu rendering
- **summary**: User: "not practical when owner has many items — need better UX + search" and "offers/deals need more options like buy 2 get 3, cover all deals options". (1) **Items tab**: `.item-toolbar` with search input (`oninput` → `itemQuery`; matches EN+AR name/desc), category filter select, sort select (order/name/price low/high), live counter ("عرض X من Y"), and pagination (`itemShown`/`ITEM_PAGE=50`, "Load more" button); list body rendered by `filteredItems()` + `renderItemRows()` into `#items-tbody` (keeps stacked-card mobile layout); `showTab('items')` now calls `renderItemRows()` after innerHTML. (2) **Deals**: new `deal_type` enum `percent|fixed|bogo|bundle|min_order` + `applies_to` (`item|category|all`), `item_id`, `category_id`, `buy_qty`, `get_qty`, `min_total`, `reward_type`, `bundle_price`, `bundle_items jsonb[]`. DB migration run via Management API (idempotent ALTERs + constraint drops/adds; backfilled `deal_type` from old `discount_type`; 0 rows so safe). Admin modal redesigned: type select + `dealTypeChanged()` shows only relevant field block; percent/fixed get a scope picker (item/category/all) with dependent selects (`dealScopeChanged()`); bogo has its own item picker `#m-deal-item-list`; bundle has item checkbox chips + combo price; min_order has min-total + reward type/value. `saveDeal()` nulls irrelevant fields per type. List row shows `dealLabel()` (e.g. `2 + 1`, `2x 35000 SYP`, `≥50000 → -10%`) + `dealScopeLine()` (item/category name). (3) **Public menu** (`index.html`): new `dealSummary(d)` localizes each type (AR+EN, e.g. "اشترِ 2 واحصل على 1 مجاناً" / "BUY 2 GET 1 FREE"); removed percent-only giant `%` ::after decoration. docs/schema.sql updated with new DDL + commented migration. Verified locally: created one deal of EACH type through the real modal → list labels correct, public menu AR+EN correct; search "lemon"→1, Arabic "قهوة"→1, Desserts filter→2, price sort correct; 390px: no overflow, toolbar stacks full-width, modal+bundle chips fit; zero console errors both pages. Test deals deleted (0 remaining). Commit `2d846ee` pushed; Pages build `built`; live-verified admin at 390px (search present, all 5 types, 9 bundle chips, no overflow, console clean).
- **result**: Success — items list scales with search/filter/sort/pagination; offers cover percent, fixed, BOGO, bundle, spend-threshold on admin + public menu.
- **files**: `admin.html`, `index.html`, `docs/schema.sql`
- **errors**: (1) BOGO `item_id` saved null during first test — the create test ran against a stale page (JS loaded before the bogo item-picker edit); fixed by reload + re-save via new picker. (2) Initial `dealTypeChanged()` map omitted 'scope' → scope never showed; fixed by including `scope` in percent/fixed field sets.
- **lessons**: LSSN-20260907-015 (when editing an admin page in the browser, always reload before testing JS changes — stale cached script silently mis-tests); LSSN-20260907-016 (dynamic show/hide field blocks: keep ALL blocks in DOM and toggle `display` by a type map — values survive type switching; include every block id in the map or it silently hides)
- **tags**: items-ux, search, filter, sort, pagination, deals, offers, bogo, bundle, min-order, schema-migration, management-api, deploy, verify

## EVT-20260907-0010

- **timestamp**: 2026-09-07
- **mode**: BUILD / FEATURE / DEPLOY
- **action**: Offers now clickable and added to the order + list/grid view toggle on public menu
- **summary**: User: "offers in the main app are not clickable, they should be added to the order once clicked" then "add a list view option button to switch between list view and grid view". (1) **Offers → order**: `index.html` deal cards are now `role=button` with `onclick`/`onkeydown` → `toggleOffer(dealId)` adds to a new `cartOffers = {dealId:1}` (separate from item `cart`), card shows `✓ أُضيف إلى الطلب` + white outline `.deal-card.added`, toast confirms. Cart affects three layers: `updateCartBar()` counts items+offers (badge shows combined, total stays item-only), `renderOrderSheet()` renders 🎁 offer lines (title + localized `dealSummary`) with `removeOffer(id)` ✕ chip, `sendWhatsApp()` appends `🎁 title — summary` rows. Empty-guards updated (`totalItems===0 && offerCount===0`). (2) **List/grid toggle**: new top-bar `.ctl.view` button (`☰`/`▦`) → `toggleView()` flips `viewMode` (`localStorage 'qm-view'`, default grid), `renderViewBtn()` shows the *target* icon + localized title + `aria-pressed`, `renderItems()` toggles `#items-grid.items-col` (grid) vs block (list). Grid CSS moved out of desktop-only media query into global `.items-col`: 2-col `grid-template-columns`, cards become `flex-direction:column`, image full-width `aspect-ratio:4/3` (desktop *and* mobile), full-width add button/stepper. List view = existing editorial tickets unchanged. Verified localhost: clicked TEST BOGO card → added state + toast + FAB badge 1; order sheet shows `🎁 TEST BOGO 2+1 — اشترِ 2 واحصل على 1 مجاناً` with working ✕; WhatsApp message correctly includes offer line; view toggle switches grid (2-col, cards column, img 100% width) ↔ list (block, tickets row, 60px img), icon flips `☰`↔`▦`, `aria-pressed` updates, persists across reload; emulated 375px mobile: no body overflow (body==viewport), grid cols 171.6px; zero console errors (only favicon 404). Test deals (3 TEST rows) created via Management API then deleted (remaining 0).
- **result**: Success — live at `https://amworx.github.io/qr-menu/` after Pages build `4937404`.
- **files**: `index.html`
- **errors**: None (favicon 404 only); one stray placeholder item id polluted a test cart — cleaned in test only.
- **lessons**: LSSN-20260907-017 (memorize that cart has two independent structures — `cart` items and `cartOffers` — every consumer (badge, sheet, WhatsApp) must read both; badges combine counts, totals stay item-only); LSSN-20260907-018 (view-mode toggles are pure CSS-class swaps — no duplicate renderers; keep one renderer that branches on the class, persist choice in localStorage, and make the button icon show the *target* mode)
- **tags**: offers, clickable-deals, add-to-order, cart, order-sheet, whatsapp, list-view, grid-view, view-toggle, responsive, deploy, verify

## EVT-20260907-0011

- **timestamp**: 2026-09-07
- **mode**: BUILD / UI-FIX / DEPLOY
- **action**: Offer add-button pinned to the same spot on all deal cards
- **summary**: User: "the add offer button location on all offer cards should be in the same location". Deal cards had varying content (some with description, badge text lengths differ) so `.deal-add` chips landed at different y positions per card. Fix in `index.html` CSS: `.deal-card` became `display:flex;flex-direction:column`, `.deal-add` changed `margin-top:10px` → `margin-top:auto` + `align-self:flex-start` (pins chip to card bottom), `.deal-badge` got `align-self:flex-start`, `.deal-card p` got explicit `margin:0 0 8px` (normalizes spacing regardless of description presence). Cards are equal height (flex row stretch), so bottom alignment = identical button position. Verified: all 3 deal cards' `.deal-add` `getBoundingClientRect().top` = 424px (single unique value) at 375px and grid; zero console errors.
- **result**: Success — commit `e90b767` pushed; Pages build `built`.
- **files**: `index.html`
- **errors**: None
- **lessons**: LSSN-20260907-019 (to pin a CTA at the same position across cards of varying content, make the card a flex column and give the CTA `margin-top:auto` — flex-row stretch equalizes card heights so all CTAs align at the bottom)
- **tags**: ui-fix, deal-card, cta-alignment, flexbox, margin-top-auto, deploy, verify

## EVT-20260907-0012

- **timestamp**: 2026-09-07
- **mode**: BUILD / FEATURE / DEPLOY
- **action**: One-tap remove (✕) for items in the order review sheet
- **summary**: User: "in order review there should be a remove item from order, now the user has to press - till the amount reaches 0". Item rows in `renderOrderSheet()` had only the stepper; removing meant pressing − down to zero. Added `removeItem(id)` (`delete cart[id]; renderItems(); renderOrderSheet(); updateCartBar()` — same refresh trio as other cart mutators) and an `✕` button (`.ol-remove`, existing style augmented with `background:var(--card2);border:1px solid var(--border2);cursor:pointer` so it's visible on both plain item rows and card2 offer rows) after the stepper, with localized `aria-label` (إزالة العنصر / Remove item). Verified localhost at 375px: built cart (3 items + 1 offer) → each `.order-line` shows ✕; one tap removed قهوة عربية ×2 (badge 5→3, total 30k→32k); clearing all rows shows empty-cart state and hides FAB; zero console errors.
- **result**: Success — commit `c5a44b8` pushed; Pages build started.
- **files**: `index.html`
- **errors**: None
- **lessons**: LSSN-20260907-020 (a quantity stepper is not a removal affordance — reviewers expect a one-tap remove; add ✕/🗑 per line and route it through the same refresh trio as all cart mutators)
- **tags**: order-review, remove-item, one-tap, cart-ux, deploy, verify

## EVT-20260907-0013

- **timestamp**: 2026-09-07
- **mode**: BUILD / UI-FIX / DEPLOY
- **action**: Offer add-order button no longer overlaps the description/summary text above it
- **summary**: User: "there is overlap between the add order button and the above text 'Description'". Investigated all layouts (deal cards, item cards grid/list, admin deal/item modals, order sheet) via rect measurements — the literal label "Description" exists only in admin modals (which were clean). The real defect was on the **public menu deal cards**: with the earlier `margin-top:auto` CTA alignment, the tallest card (the one with a description) had ZERO free space, so the `.deal-add` button sat flush against the `.deal-badge` summary text (measured gap = 0px, badge bottom == button top). Stress test confirmed it: with a 3-line Arabic description the button still touched the badge. Fix in `index.html`: `.deal-badge` margin changed `margin-top:8px` → `margin:8px 0 14px` — guarantees a 14px minimum gap above the CTA even on the tallest card, while `.deal-add{margin-top:auto}` keeps every button bottom-aligned at the same y. Verified: 3 live deals all have gap ≥14px (14 on described cards, 40 on short cards), all add buttons at identical y (438px) at 375px; long-description stress card (3 lines) still gap 14px, no overlap, no overflow; console clean. Stress card deleted after test (TEST rows = 0).
- **result**: Success — commit `d9147b6` pushed; Pages build `built`; verified live.
- **files**: `index.html`
- **errors**: None
- **lessons**: LSSN-20260907-021 (margin-top:auto CTA alignment can produce 0-gap collisions on the tallest equal-height card — pair it with a fixed margin-bottom on the element above so the minimum gap is never zero; always stress-test with a multi-line/3-line description, not just the current data)
- **tags**: ui-fix, deal-card, overlap, cta-gap, margin-top-auto, stress-test, deploy, verify

## EVT-20260907-0014

- **timestamp**: 2026-09-07
- **mode**: BUILD / DATA / DEPLOY
- **action**: Every order now gets a sequential ID/number and is recorded server-side
- **summary**: Added an `orders` table (bigserial `id` = the displayed order number, `shop_id`, `currency`, `subtotal`, `discount`, `total`, `items` jsonb, `offers` jsonb, `discount_lines` jsonb, `note`, `created_at`). RLS: anon can INSERT (public order form), only the shop owner can manage (`shop_id in (select id from shops where owner_email = auth.email())`). `sendWhatsApp()` now inserts the order first, gets `data.id`, and the WhatsApp header shows `*New Order #<id> — <shop>*` (fallback `T<epoch-tail>` if the insert fails, so ordering never breaks offline). Verified: orders #1/#2 EN + #3 AR recorded with correct numbers; test rows TRUNCATEd (restart identity) so real orders start at #1. `docs/schema.sql` updated (table + index + policies).
- **result**: Success — commit `052c838` pushed; Pages build `built`; verified live (105,000 − 35,600 = 69,400 SYP).
- **files**: `index.html`, `docs/schema.sql`, Supabase `orders` table
- **errors**: `create policy if not exists` is NOT valid Postgres — used DO block with `pg_policies` guard instead; PowerShell double-quoted here-string expands `$` — used single-quoted here-string for SQL with `$$`.
- **lessons**: LSSN-20260907-022 (WhatsApp redirect mangles non-BMP emoji) + LSSN-20260907-023 (pricing engine pattern)
- **tags**: orders, order-number, bigserial, RLS-public-insert, whatsapp, fallback, deploy, verify

## EVT-20260907-0015

- **timestamp**: 2026-09-07
- **mode**: BUILD / PRICING / DEPLOY
- **action**: Offers now affect the order value (were 0-value line items)
- **summary**: Built `computeOrder()` pricing engine in `index.html` — a single snapshot used by FAB, sheet and WhatsApp: `itemUnitPrice`, `cartSubtotal`, `scopeSubtotalValue` (item/category/all), `dealSavings` (percent → % of scope subtotal; fixed → min(value, scope subtotal) and only in matching currency; bogo → floor(qty/(buy+get))×get×unit price of the target item; bundle → sum of bundle item prices − bundle_price when all present; min_order → % or fixed after threshold), and final `discount = min(Σ savings, subtotal)` / `total = subtotal − discount` (additive stacking, never negative). FAB total shows the discounted total; the sheet shows Subtotal, one green `−X` per offer, and Total; the WhatsApp message shows per-offer savings and `Total after discount`. Verified: Manakish×3 + Coffee×2 (105,000) + Offer#1 BOGO −25,000 + Mega 10% −10,500 + 24 Offer −100 = **69,400**; offers-only → total 0 with no fake discounts; BOGO with qty < buy+get → no discount; AR + EN both correct.
- **result**: Success — commit `052c838` pushed; Pages build `built`; verified live.
- **files**: `index.html`
- **errors**: None (beyond the emoji issue fixed in the same session — see LSSN-022)
- **lessons**: LSSN-20260907-023
- **tags**: pricing, discounts, bogo, bundle, percent, fixed, min-order, computeOrder, addititive-cap, deploy, verify

## EVT-20260908-0016

- **timestamp**: 2026-09-08
- **mode**: BUILD / FEATURE / UI / LOCAL-VERIFY (no commit yet)
- **action**: Admin Orders view — new tab listing recorded orders (items, offers, pricing, note) with search, Today filter, refresh, range pagination
- **summary**: User asked to "build the Admin Orders view in the QR Menu project" so the owner can see every recorded order. Added to `admin.html` only: (1) state `ordersAll = []`, `orderHasMore = true`, `orderQuery = ''`, `orderFilter = 'all'`, `ORDER_PAGE = 200`; (2) `loadOrders(reset)` fetches via supabase-js `.select('*').eq('shop_id', currentShop.id).order('id',{ascending:false}).range(from,to)` (server-side range pagination, preserves RLS owner-select); (3) toolbar with search input (`oninput` → id-substring match on loaded window), filter select All/Today (local midnight comparison), refresh button, live counter `عرض X من Y+`; (4) `renderOrderRows()` renders rows into `#orders-tbody` using the existing stacked-card `data-label` mobile layout (PAT-004) — per row: `#N` badge, localized date (`ar-SY`/`en-GB` short style), item lines (`name_ar` in AR / `name` in EN), offer lines (green `−savings`), subtotal/discount/total, note line `ملاحظة/Note:`; empty states `لا توجد طلبات` / `لا توجد طلبات تطابق البحث.`; (5) i18n keys added for all labels + nav button in sidebar AND mobile tabs (17 new keys); (6) showTab('orders') uses the async `.then(html=>c.innerHTML=html)` pattern (LSSN-010). **Bilingual offer line fix**: jsonb snapshots store the *localized-at-order-time* summary; for full EN/AR parity the renderer prefers `summary||title_ar||title` in AR but `title||summary` in EN (so EN admins see "Offer #1", AR admins see "اشترِ 2 واحصل على 1 مجاناً"). Verified end-to-end locally: created a real order through the public flow (3× Manakish 25,000 + 2× Arabic Coffee 15,000 + all 3 live offers BOGO −25,000 / 10% −10,500 / 100 SYP −100) → DB row id=1, SYP, subtotal 105,000, discount 35,600, total **69,400** (matches handoff math); Orders tab render correct in AR/RTL desktop AND EN desktop AND strict 375px mobile emulation (body.scrollWidth == 375, td clipped? no — first td left 31/right 344 in RTL, sticky tabs at 79px under 78px header per PAT-005); search "1" keeps row, "999" shows no-match state; Today filter keeps today's order; UTF-8 note `نص تجريبي — بلا ثوم` intact; console clean (only pre-existing unlabeled-input a11y lint, no errors). Cleanup: `TRUNCATE orders RESTART IDENTITY` via Management API → orders empty, sequence back to 1 so the next real order is **#1** (handoff intent preserved). NOT committed/deployed — awaiting user approval.
- **result**: Success — feature complete and locally verified; pending user decision on commit/push/deploy.
- **files**: `admin.html` (only file changed), temp server `C:\Users\HP\AppData\Local\Temp\opencode\server.js` (localhost:8088)
- **errors**: (1) chrome-devtools `fill` with empty string did NOT fire the `oninput` handler → cleared search left stale "Showing 0 of 1"; forced via `el.value=''; el.dispatchEvent(new Event('input',{bubbles:true}))` to confirm real behavior (typing clears fine — tooling quirk, not app bug); (2) Management API `select count(*), last_value from orders, orders_id_seq` failed `42803` (must not cross-join aggregates) — rewrote as scalar subselects.
- **lessons**: LSSN-20260908-024, LSSN-20260908-025
- **tags**: orders, admin-view, tab, pagination, search, filter, today, refresh, jsonb-snapshot, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0017

- **timestamp**: 2026-09-08
- **mode**: RESEARCH / PLAN / BUILD / LOCAL-VERIFY (no commit yet)
- **action**: Feature-gap analysis vs qrmenum.app demo + implement P1.1 SEO/OG/JSON-LD
- **summary**: Studied the professional QR-menu SaaS demo `https://aurora.qrmenum.app/restaurant` (Aurora Kitchen & Bar, Istanbul/TRY) in-browser to inventory the production feature set: full catalog with 3 accordion groups and per-category deep-link routes (`/restaurant/menu/{group}/{category}`, e.g. `yiyecekler/kahvalti-brunch`); category hero (cover image, description, "7 items"); featured rail; product cards with image/desc/price/`kcal`/allergen icons; **product detail pages** with breadcrumb, multi-image gallery, Share + Add-to-favorites, badges (Popular, New, Chef's Choice), dietary chips (Vegetarian, Gluten-Free), nutritional values block (cal/fat/carbs/protein per portion), preparation time, allergen listing (EU 14), similar-products carousel; **size/price variants** ("From 165,00₺", Cappuccino Small 110 / Large 130); instant search overlay with **AI concierge "Aura"** (greeting + quick chips + voice search + FEATURED/MOST POPULAR/MOST LIKED rails); Info modal (about, service hours, address + Get Directions, phone, socials, VAT/allergy legal note, WiFi network/password/Copy, Satisfaction Survey link); PWA install prompt; SEO/OG/Twitter + JSON-LD `Restaurant` schema; tenant theming via `:root` vars; language selector; bottom nav (Menu/Info/Language). Wrote organized **plan** `plans/feature-gaps-qrmenum.md` with all evidence inlined and a Phase 1/2/3 ranked queue (order: Soy SEO → category hero → badges → kcal+prep+allergens → product sheet → variants+From price → search overlay → info modal/share/hours → phase 2). Then implemented **P1.1 SEO/OG/JSON-LD in `index.html`**: static meta (description, twitter:card, og/twitter placeholders) + `renderSEO()` wired into `render()` that sets per-page title, description, canonical, og/twitter title/desc/url/image, theme-color from `shop.primary_color`, and emits a dynamic `application/ld+json` `Restaurant` schema (name, url, image, telephone from `shop.phone||whatsapp`, address localized AR/EN, priceRange = default currency, `hasMenu` with per-category `MenuSection` of `MenuItem` each carrying `Offer`{price, priceCurrency, availability InStock/OutOfStock}, desc, image). Language-aware: `renderSEO()` runs on every `render()` so switching AR/EN re-emits localized title/desc/schema (P1.1 and LSSN-028 make this the template for the rest of the gap list).
- **result**: Success — verified locally (EN desktop, AR/RTL desktop, strict 375px mobile both langs): AR shows title `جودي جوي` + RTL desc + JSON-LD with 4 MenuSections / 9 MenuItems (first: `قهوة عربية` Offer 15000 SYP InStock); EN shows "Judy Joy" / "Fresh coffee & light bites" / Section "Hot Drinks" / Item "Arabic Coffee"; canonical+og url resolved to `http://localhost:8088/index.html`, theme-color `#D97706`; 375px no horizontal overflow (docScrollW==docClientW==375) in AR and EN; console clean (no new errors). Working tree dirty (index.html + plan + pending memory). Committed NOT yet — awaiting user decision.
- **files**: `plans/feature-gaps-qrmenum.md` (new), `index.html` (head meta + `renderSEO()`), memory/events.md, memory/lessons.md
- **errors**: None (one earlier false-spike: `#ar` navigation kept `lang=en` until a clean reload — hash reads only on full init; re-reloaded to confirm AR, not an app bug)
- **lessons**: LSSN-20260908-026
- **tags**: gap-analysis, plan, seo, og, twitter-card, json-ld, restaurant-schema, menu-sections, canonical, color-scheme, rtl, mobile-375, research, local-verify, pending-commit

## EVT-20260908-0018

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.7 — Category hero (image, description, item count) on public menu + admin CRUD fields
- **summary**: Continued the gap-closing queue (`plans/feature-gaps-qrmenum.md`, P1.1 already on main). Implemented the category hero feature end-to-end: (1) **DB migration** via Management API — added `image_url`, `description`, `description_ar` columns to `categories` (idempotent `alter table ... add column if not exists`); recorded migration note in `docs/schema.sql`; (2) **admin.html** — category modal now has Image URL, Description (EN), Description (AR) fields, `saveCategory()` persists them, categories table gained an image thumbnail column (reused existing i18n keys `image_url`, `desc_en`, `desc_ar`); (3) **index.html** — added `#cat-hero` container + `.cat-hero` CSS (gradient fallback, optional cover image with dark overlay via `::after`, eyebrow chip, h2, description) and `renderCatHero()` which renders only when a category tab is active: eyebrow item-count chip ("عدد الأصناف · N" AR / "N items" EN), localized name + localized description; wired into `render()` and `setCategory()`; hidden on "All" view. Seeded all 4 Judy Joy categories with Unsplash hero images + bilingual descriptions via a clean JSON payload file (Write tool + curl) to avoid PowerShell Arabic mangling.
- **result**: Success — verified locally at strict 375px (docScrollW==docClientW==375 in AR and EN): AR Hot Drinks hero shows "عدد الأصناف · 3" + image (loaded) + Arabic description, items filtered to 3; EN shows "3 ITEMS" + English description; "All" hides the hero; language switch re-renders hero; admin categories table shows image column and edit modal populates the 3 new fields; tested admin save path (temporarily appended `[P1.7TEST]` to Hot Drinks description via modal, confirmed persisted via Management API, then restored). Console clean except pre-existing "No label associated with a form field (count: 22)" a11y issue unrelated to this change (tracked as follow-up).
- **files**: `docs/schema.sql` (categories columns + P1.7 migration note), `admin.html` (category modal/table/save), `index.html` (CSS + `#cat-hero` + `renderCatHero()`), memory/events.md, memory/lessons.md
- **errors**: (1) Management API `Invoke-RestMethod` with payload read from a raw `.sql` file returned "expected string, received object" — ConvertTo-Json mangled the multiline value; solved by writing the JSON payload file with the Write tool and sending with `curl.exe --data-binary @file` (also avoids BOM issues); (2) first curl attempt inline had a UTF-8 BOM → "not valid JSON"; fixed via Write tool (no-BOM UTF-8). Both reinforce LSSN: write payload files, never rebuild JSON in PowerShell.
- **lessons**: LSSN-20260908-027 (Management API: always send the query as a JSON payload file written by the Write tool + `curl.exe --data-binary @file`; PowerShell `ConvertTo-Json`/here-strings mangle multiline SQL and BOM breaks `--data-binary` inline)
- **tags**: p1.7, category-hero, image-url, description, item-count, db-migration, admin-crud, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0019

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.3 — Item badges (New / Popular / Chef's Choice) on cards + admin CRUD
- **summary**: Continued the gap-closing queue after P1.7 shipped (commit 24a51b9). Implemented promotional item badges end-to-end: (1) **DB migration** via Management API — added `popular`, `chef_choice`, `is_new` boolean columns to `items` (idempotent `add column if not exists`); documented in `docs/schema.sql` (columns + P1.3 migration note); (2) **admin.html** — new i18n keys (`popular` الأكثر طلباً, `chef_choice` اختيار الشيف, `new_badge` جديد, `badges` الشارات), item edit modal gained a Badges checkbox row (three `.checkbox` toggles wired into `saveItem()`), items table gained a chips column (colored pills per badge) and header/colspan updated (7→8); (3) **index.html** — added `.badge-chip` CSS (green NEW / amber POPULAR / purple CHEF'S CHOICE) + `badgeChipsHTML(item)` helper rendering a `.badge-row` under the item sub-name, called in `renderItems()`; localized labels (جديد / الأكثر طلباً / اختيار الشيف). Seeded badges: Arabic Coffee + Cappuccino `popular`, Cheese Manakish `chef_choice`, Iced Latte + Chicken Wrap `is_new` (via Write-tool JSON payload + curl per LSSN-027).
- **result**: Success — verified locally at strict 375px (docScrollW==docClientW==375 in AR and EN): 5 chips render with correct localized labels in both languages; admin items table shows the الشارات column with pills; item edit modal loads checked state correctly (Arabic Coffee: Popular ✓) and the save path was proven (toggled `is_new` on Arabic Coffee via modal → confirmed `is_new=true` persisted (PATCH 204) → restored to false). Console: only pre-existing favicon 404 + the known "No label associated" a11y issue; all Supabase REST calls 200/204.
- **files**: `docs/schema.sql` (items columns + P1.3 migration note), `admin.html` (badges i18n, modal checkboxes, saveItem, table chips column), `index.html` (badge CSS + `badgeChipsHTML()` + renderItems), memory/events.md
- **errors**: None (save-path test required a check-then-restore cycle; no regressions observed)
- **lessons**: (none new — reused LSSN-027 payload technique)
- **tags**: p1.3, badges, popular, chef-choice, new, item-badges, db-migration, admin-crud, chips, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0020

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.4 — kcal + prep time on item cards + admin CRUD
- **summary**: Continued queue after P1.3 shipped (commit af5d3a3). Implemented kcal + preparation time: (1) **DB migration** via Management API — added `kcal integer null`, `prep_time_min integer null` to `items`; documented in `docs/schema.sql` (columns + P1.4 migration note); (2) **admin.html** — i18n keys (`kcal` السعرات (سعرة), `prep_time` وقت التحضير (دقيقة)); item modal gained a two-field card-row (numeric kcal + prep-time inputs); `saveItem()` persists them as `null` when empty, integer otherwise; (3) **index.html** — `.item-meta` pill CSS + `itemMetaHTML(item)` helper emitting `🔥 N kcal` and `⏱ ~N min`/`~N دقيقة` chips (localized), rendered under the description/control in `renderItems()`. Seeded realistic values on 5 items (Arabic Coffee 12kcal/3min, Cappuccino 95/7, Fresh Lemonade 25/5, Cheese Manakish 420/25, Kunafa 320/15).
- **result**: Success — verified locally at strict 375px (docScrollW==docClientW==375): AR shows `🔥 12 kcal ⏱ ~3 دقيقة` style chips with Arabic prep label; EN shows `~3 min`; items without values show no meta row; admin modal inputs populate/persist correctly (saved via `saveItem()`); console clean apart from the two pre-existing issues (favicon 404, label-association a11y).
- **files**: `docs/schema.sql` (items kcal/prep columns + migration note), `admin.html` (i18n + modal fields + saveItem), `index.html` (CSS + `itemMetaHTML()` + renderItems), memory/events.md
- **errors**: None
- **lessons**: (none new — kcal/prep follow the same schema→admin→render pattern as P1.3/P1.7)
- **tags**: p1.4, kcal, prep-time, calories, db-migration, admin-crud, item-meta, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0021

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.5 — Allergens (fixed 14-list, icon chips on cards + admin CRUD)
- **summary**: Continued queue after P1.4 shipped (commit a75c91b). Implemented allergen declarations end-to-end: (1) **DB migration** via Management API — added `allergens jsonb` to `items` (array of codes); documented in `docs/schema.sql` (column + P1.5 migration note + list of the 14 codes); (2) **admin.html** — `ALLERGENS` constant (14 EU-FIC codes × en/ar label + icon) + `allergenMeta()` helper; i18n keys (`allergens` مسببات الحساسية, `none`); item modal gained a 2-column `.allergen-grid` (1-col under 520px) of 14 icon+label checkboxes pre-checked from `item.allergens`; `saveItem()` collects checked values into the `allergens` array; (3) **index.html** — same `ALLERGENS` constant + `allergenChipsHTML(item)` rendering a row of circular icon-only `.allg-chip` with localized `title` tooltips (aria-label on the row); wired into `renderItems()` after the meta line. The full labeled "Allergens" section is deferred to the product sheet (P1.2). Seeded: Cappuccino [eggs,gluten], Cheese Manakish [gluten,milk], Chicken Wrap [gluten,sesame,milk], Iced Latte [milk], Kunafa [gluten,milk,nuts].
- **result**: Success — verified locally at strict 375px in AR and EN (docScrollW==docClientW==375): 5 card rows show the correct icon sets; AR tooltips are Arabic (البيض, الحليب, الغلوتين…); cards without allergens show no row. Admin: item modal shows all 14 localized checkboxes and edit loads them; save path proven (checked gluten on Arabic Coffee via modal → persisted `["gluten"]` → restored to `[]`). Console clean apart from the two pre-existing issues.
- **files**: `docs/schema.sql` (allergens column + migration note), `admin.html` (ALLERGENS const, i18n, allergen grid, saveItem), `index.html` (ALLERGENS const, `allergenChipsHTML()`, CSS, renderItems), memory/events.md
- **errors**: Seed ids for Chicken Wrap / Iced Latte were misremembered (wrong UUID tails) — first seed silently updated 0 rows; lessons: look up real ids via a SELECT before multi-row UPDATEs. No code error; fixed by re-seeding with looked-up ids.
- **lessons**: (reusable) When seeding by id, SELECT the ids first — don't trust remembered UUIDs.
- **tags**: p1.5, allergens, allergen-chips, jsonb, db-migration, admin-crud, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0022

- **timestamp**: 2026-09-08
- **mode**: BUILD / UI / I18N / LOCAL-VERIFY
- **action**: P1.2 — Product detail bottom-sheet (image, desc, badges, allergens, nutrition, qty, per-item note, add-to-cart)
- **summary**: Continued queue after P1.5 shipped (commit ea3c4f2). Implemented the product detail sheet end-to-end in `index.html` (no new DB columns): (1) **HTML** — `#product-modal` reusing the `.order-modal`/slideUp pattern with `.product-sheet` (92vh, flex column: fixed `.pd-hero` 230px image/emoji hero + scrollable `.pd-body` + fixed `.pd-actions` bar; close button inset-inline-end for RTL); (2) **Card affordance** — `.item-media` and `.item-name` became real `<button>`s (`openProductSheet(id)`) with focus-visible rings; `.item-name-btn` reset CSS keeps the visual row identical; quick-Add/stepper still works on the card; (3) **Sheet content** — hero image (or emoji placeholder), badges row (reuses `badgeChipsHTML`), localized name + secondary name, full description (no clamp), nutrition meta chips (reuses `itemMetaHTML`), full labeled **allergen section** (`allergenSectionHTML` — icon + AR/EN label chips, or "لا يحتوي على مسببات حساسية / No allergens" when empty; completing the P1.5 plan promise), per-item optional note textarea (`#pd-note`), qty stepper (`pdQty`/`pdQtySet`), Add-to-order button showing price, label flips to "تحديث الطلب / Update order" + in-cart hint when the item is already in cart; (4) **Per-item notes** — new `cartNotes = { itemId: note }` in-memory map (consistent with in-memory cart): written by `pdCommit()`, cleared on `removeItem()`, threaded into `computeOrder().itemsList` (persisted in the `orders.items` jsonb) and appended per line in the WhatsApp message as `(ملاحظة: … / note: …)`; note text is BMP-safe by the existing surrogate-strip at send. Escape key closes both sheets (product + order); backdrop click closes product sheet.
- **result**: Success — verified locally at strict 375px in AR and EN: open sheet from name button, media button, list view, and backdrop + Escape close all work; AR Arabic Coffee sheet shows badge / full desc / kcal chips / "لا يحتوي على مسببات حساسية" / note field / stepper / تعديل button; qty+ note commit put qty 2 with `badنص` note into the order (computeOrder.firstLine.note persisted, FAB total 30,000 SYP, sheet auto-closes); reopen shows Update-order state (qty 2, note prefilled); EN: "No allergens", "Update order", English placeholder; no horizontal overflow (docScrollW==375) in grid and list views. Console: pre-existing favicon 404 only + one non-blocking a11y suggestion (card stepper input lacks name/id — same as known admin label issue class).
- **files**: `index.html` (product modal HTML, CSS, card buttons, `openProductSheet`/`renderProductSheet`/`allergenSectionHTML`/`pdQty*`/`pdCommit`, `cartNotes`, computeOrder note, WhatsApp note line, Escape handler), memory/events.md
- **errors**: None (careful not to drop the base `.order-note` CSS rule while adding styles after it — caught by visual review)
- **lessons**: (reused) bottom sheet pattern from the existing order modal; sheet content reuses P1.3/P1.4/P1.5 helpers so the feature is composition-only.
- **tags**: p1.2, product-detail, bottom-sheet, modal, cart-notes, allergens-section, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0023

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.6 — Size/price variants jsonb + "From X" card pricing + cart carries chosen variant
- **summary**: Continued queue after P1.2 shipped (commit 5f39f63). Implemented size/option variants end-to-end: (1) **DB migration** via Management API — added `variants jsonb` to `items`; documented in `docs/schema.sql` (shape `[{name, name_ar, prices:{SYP,USD,TRY}}]` + P1.6 note); (2) **admin.html** — i18n keys (`variants`, `add_variant` إضافة خيار, `variant_name_en/ar`), a dynamic variant editor in the item modal (`#m-variants` rows with EN/AR name + SYP/USD/TRY inputs + remove; `variantRowHTML()`/`addVariantRow()`/`collectVariants()`), `saveItem()` persists `variants` (rows empty on all fields are dropped); (3) **index.html** — `selectedVariants = { itemId: index }` in-memory map; helpers `itemHasVariants()`, `variantPrice()`, `itemVariantPrices()`, `cardPriceHTML()` (renders "من X / From X" with `.price-from` when variants exist); `itemUnitPrice()` now returns the selected variant's price (falls back to `item_prices`); card quick-add becomes "إختر/Choose" → opens the product sheet when the item has variants; the sheet renders a size/option chip group (`.pd-var`, localized label + per-currency price, active ring, `pdSelectVariant()` updates footer price in place); `pdCommit()` stores the chosen index; order-sheet row shows the variant as a primary-colored sub-line; `computeOrder().itemsList` carries `variant {name, name_ar}` (persisted into `orders.items`); WhatsApp line appends `(اسم الخيار)`. Seeded Cappuccino with Small/Medium/Large (17k/20k/24k SYP + USD/TRY).
- **result**: Success — verified locally at strict 375px in AR and EN: Cappuccino card shows `From 17,000 SYP` / `من ١٧٬٠٠٠ SYP` with a Choose button; sheet shows 3 localized chips; selecting Large updates the footer to 24,000 SYP and commit stores qty 1 @ 24,000 with `variant {name:Large,name_ar:كبير}` (FAB 24,000); order sheet shows the variant sub-line; AR sheet labels صغير/وسط/كبير; no horizontal overflow. Admin: modal loads the 3 seeded rows with prices; save path proven (added XL via editor → persisted → removed → restored to 3); console only pre-existing favicon 404 + known a11y label/id suggestions (variant inputs counted in the existing follow-up issue).
- **files**: `docs/schema.sql` (variants column + migration note), `admin.html` (i18n, variant editor HTML/CSS, helpers, saveItem), `index.html` (selectedVariants, pricing helpers, card/price/sheet/order/WA integration), memory/events.md
- **errors**: None. (Note: an earlier check on the admin modal ran against a stale in-browser script — reload the page after editing admin.html before testing.)
- **lessons**: (reused) payload-file Management API; after editing any page with DevTools open, reload the target page to pick up new JS.
- **tags**: p1.6, variants, sizes, options, from-price, jsonb, db-migration, admin-crud, cart-variant, whatsapp, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0024

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P1.8 — Instant search overlay (keyword fuzzy, grouped by category, no voice/AI in v1)
- **summary**: Added a full-screen search overlay matching the demo's "Search" pattern: (1) 🔍 button in the floating controls (`.ctl`, next to lang); (2) `.search-modal` (z-index 110, top-sheet style, backdrop click closes, `slideDown` animation, max-height 76vh, safe scroll with `overscroll-behavior`); (3) localized placeholder (`ابحث عن طبق أو مشروب…` / `Search dishes or drinks…`) set on open; (4) `normSearch()` — lowercase + strips Arabic diacritics (`\u064B-\u0652`) and tatweel plus folds أ/إ/آ→ا, ة→ه, ى→ي so typed queries match stored text; (5) `searchRender(q)` matches `name/name_ar/description/description_ar`, empty query shows a hint, no matches shows «لا توجد نتائج لـ» / “No results for” with the query echoed; (6) results grouped per category via `.search-group-title`, each `.search-row` = thumb/emoji + localized name + secondary localized name + badge chips + price (variant items keep the "From / من" price via existing `cardPriceHTML`), tap opens the product sheet and auto-closes the overlay (`openProductSheet(id); closeSearch()`); (7) Escape closes search (added to the existing global keydown along with order + product sheets). No DB/admin changes.
- **result**: Success — AR 375px: open shows Arabic hint; «قهوة» → Coffee category rows (قهوة عربية الأكثر طلباً, قهوة تركية); «إسبريسو» (typed WITH hamza/diacritics) matches Cappuccino via description_ar and shows `من ١٧٬٠٠٠ SYP` (variant From price); «ساندويش» → Chicken Wrap (جديد chip); «zzzz» → Arabic no-results; result tap opened كنافة sheet and closed overlay; Escape closed both. EN 375px: placeholder "Search dishes or drinks…", «latte» → Cold Drinks/Iced Latte NEW 22,000 SYP, «milk» → Cappuccino (desc match), EN no-results, group titles EN. No horizontal overflow in either language; console only pre-existing favicon 404.
- **files**: `index.html` (search button, overlay markup, search CSS, openSearch/closeSearch/normSearch/searchRender/searchRowHTML, Escape wiring), memory/events.md
- **errors**: None. (Testing note: `navigate type=url` with only a hash change is a same-document navigation — JS does NOT re-run; use `type=reload` with `ignoreCache` after changing the hash to test a fresh language load.)
- **lessons**: (reused) verify both languages with a hard reload on the target hash; keep the search price path via `cardPriceHTML` so variant "From X" logic stays in one place.
- **tags**: p1.8, search, instant-search, overlay, fuzzy-match, arabic-normalization, grouped-results, no-voice, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0025

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.9 — Info modal (about, hours-ready, address+directions, phone, WhatsApp, socials, legal note) + admin fields
- **summary**: (1) **DB migration** (Management API): added to `shops` → `about`, `about_ar`, `instagram`, `facebook`, `tripadvisor`, `legal_note`, `legal_note_ar` (all text default ''); documented in `docs/schema.sql` (columns in create table + P1.9 migration note). (2) **admin.html**: i18n keys (about_en/ar, social_links, instagram, facebook, tripadvisor, legal_note, legal_note_ar, page_about), a new shop-settings card with AR/EN about textareas, social URL inputs, legal note inputs; `saveShop()` persists the new fields (uses existing `gv()` for textarea/inputs). (3) **index.html**: ⓘ button in floating controls, `#info-modal` bottom sheet (`.info-sheet`, max-height 88vh, scrollable `.info-body`), `openInfo()/closeInfo()/renderInfo()/infoHoursHTML()`. Render sections: logo+names head, About (AR/EN), Opening Hours (renders when `shop.hours` array exists — populated by P1.11, hidden otherwise), Address + 🧭 Get Directions (`google.com/maps/search/?api=1&query=`), Phone tel: + WhatsApp links, socials chips (Instagram/Facebook/Tripadvisor, empty URLs filtered), legal note styling (`.info-legal`). Escape + backdrop click close. Seeded demo content for amworxx@gmail.com (about AR/EN, Instagram/Facebook, legal AR/EN).
- **result**: Success — AR 375px (hard reload on #ar): RTL, sections `نبذة عنا`/`تابعنا`, Arabic about/legal, title جودي جوي, links correct, no overflow. EN: About/Follow us EN text, no overflow. Admin: new card shows seeded values; write path proven (appended "(اختبار الحفظ)" to legal_note_ar in UI → saved → API confirmed persisted → restored). Console only pre-existing favicon 404 + known a11y label count (67).
- **files**: docs/schema.sql, admin.html (i18n, shop card, saveShop), index.html (ⓘ button, info modal markup/CSS/JS, Escape), memory/events.md
- **errors**: One self-inflicted failure: attempted to restore the legal note in AR by building a payload inline in a PowerShell command + `Set-Content` — PS 5.1 mangled the Arabic to mojibake BEFORE curl (stored garbage in DB). Fix: re-ran restore with a payload file written via the **Write tool** (project rule) → clean UTF-8 stored. Lesson logged in lessons.md.
- **lessons**: (reinforced) NEVER pass Arabic inline through PowerShell when building SQL payloads — always Write tool → curl.exe --data-binary @file.
- **tags**: p1.9, info-modal, about, directions, socials, legal-note, shop-columns, db-migration, admin-settings, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0026

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P1.10 — Share product (native share / WhatsApp text / copy link) + `?item=` deep link
- **summary**: Added sharing on the product sheet without any DB change: (1) two floating buttons in the sheet hero (`.pd-share` 📤 at inset-inline-end 58px, `.pd-copy` 🔗 at 102px, both sharing `.pd-close` glass style, localized aria-labels); (2) `productLink(item)` → `${origin}${pathname}?item=<id>` (no per-page routing; noted that `shops.slug` column does NOT exist — init's `?shop=` filter branch is dead code, so deep links carry only `?item=`); (3) `shareText(item)` builds a localized BMP-safe message `Name / Name_AR — From X (variant-aware min price)`, shop name, first 90 chars of description, link — `.replace(/[\uD800-\uDFFF]/g,'')` applied for the wa.me redirect; (4) `shareProduct()` → `navigator.share` when available/secure context, else `window.open('https://wa.me/?text=…')`; (5) `copyProductLink()` → clipboard writeText with `window.prompt` fallback + localized toast «تم نسخ الرابط / Link copied»; (6) deep-link support in init: after `render()`, parse `?item=<id>` and `setTimeout(() => openProductSheet(id), 400)` so a shared link opens the exact item after first paint.
- **result**: Success — AR 375px: hero shows 🔗/📤/✕, share text for Cappuccino = `كابتشينو / Cappuccino — من ١٧٬٠٠٠ SYP` + shop + desc + deep link, BMP-safe, no overflow. Deep link `?item=d97406b4-…` opened the sheet on fresh load (AR and EN via hard reload): AR «كابتشينو», EN «Cappuccino», EN shareText `From 17,000 SYP` + Judy Joy + English desc. Console only pre-existing favicon 404.
- **files**: `index.html` (hero share/copy buttons, productLink/shareText/shareProduct/copyProductLink, deep-link init block), memory/events.md
- **errors**: None.
- **lessons**: (reused) hard reload after hash-only navigation to re-run JS; discover the app's dead `slug` branch while building share links — deep links are `?item=` only for now.
- **tags**: p1.10, share, whatsapp-share, copy-link, deep-link, product-sheet, bmp-safe, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0027

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P1.11 — Service hours + "Open now / Closed" status
- **summary**: Added opening-hours to `shops.hours jsonb` (7 entries Mon..Sun, each `{open,close}` or `null` = closed; overnight allowed like Fri 09:00–02:00): (1) migration `alter table shops add column if not exists hours jsonb;` and seeded Judy Joy as Mon–Thu 08:00–23:00, Fri–Sat 09:00–02:00, Sun closed; (2) admin Shop Settings gains an "Opening Hours / ساعات العمل" card — 7 localized rows (`.hours-row` with `.h-open`/`.h-close` time inputs, empty/empty = closed) fed by `hoursEditorRows(s)` and persisted via `saveShop → collectHours()` (save path proven: set Sunday 10:00–22:00 in UI → API read back → restored to null); (3) public side: `isNowOpen()` computes Mon=0..Sun=6 from `getDay()`, supports same-day + overnight windows and **attributes early-morning hours to YESTERDAY's overnight window** (first version exited early on `cur >= o` and wrongly reported Sat 01:00 as closed when Friday's 09:00–02:00 covers it — fixed by falling through to the prev-day check only when today's window hasn't opened yet); `infoHoursHTML()` now appends an 🟢 "مفتوح الآن / Open now" or 🔴 "مغلق الآن / Closed now" chip (hidden when no hours configured); chip CSS `.info-openchip.open/.closed`.
- **result**: Success — Admin editor loads 7 seeded rows; DB round-trip verified (write Sunday → API select shows 10:00–22:00 → restored to null). Public AR 375px: hours table (الاثنين…الأحد, «مغلق» for Sun) + chip «🔴 مغلق الآن» correct at 23:16 local (Tue closes 23:00). EN 375px: "Closed now" + English rows + no overflow. isNowOpen mocked over 11 clock cases all correct (Tue 12:00 ✓ open, Tue 7:59 ✓ closed, Fri 1:00 ✓ closed before Fri's open, Fri 23:30 ✓ open overnight, Sat 01:00/01:59 ✓ open via Fri overnight, Sat 03:00 ✓ closed, Sun 01:00 ✓ open via Sat overnight, Sun noon ✓ closed). Console only pre-existing favicon 404.
- **files**: `docs/schema.sql` (hours jsonb column + P1.11 note), `admin.html` (i18n day keys, hours card, hoursEditorRows/collectHours, CSS), `index.html` (isNowOpen, infoHoursHTML chip, CSS), memory/events.md. DB: `shops.hours` seeded.
- **errors**: (1) PowerShell ok; (2) isNowOpen overnight early-return bug caught by mocked-clock matrix — lesson: always test overnight-window logic over a weekday matrix, not just the current clock.
- **lessons**: extend the existing mock-clock verification technique to any time-window logic; seed hours using Friday/Saturday late-night windows so the public field has realistic data.
- **tags**: p1.11, service-hours, open-now, hours-jsonb, db-migration, admin-editor, overnight-hours, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0028

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P2.1 — Favorites (localStorage) + favorites rail
- **summary**: Added per-device favorites without any DB change: (1) `localStorage 'qm_favs'` = JSON array of item ids, `favs` state + `loadFavs/saveFavs/isFav`; (2) heart button on every card `.fav-heart` (absolute over media, top:12px inset-inline-end:12px, z-index 3, dark glass, ♥ filled / ♡ outline, `.on` = rose rgba(190,24,93,.72)) plus a heart on the product sheet `.pd-fav` at inset-inline-end:146px (4th round button, `pd-fav-btn`) with synchronized `syncFavHearts()`; (3) horizontal `#fav-rail` under the category rail — `<div class="fav-card">` mini cards (thumb/emoji, name, `cardPriceHTML` incl. "من/From" variant prices), ✕ remove, "مسح الكل / Clear" button, `renderFavRail()` shows only when ≥1 fav; (4) `toggleFav` localizes the toast (♥ أُضيف إلى المفضلة / ♥ Added to favorites; أُزيل من المفضلة / Removed from favorites; أُفرغت المفضلة / Favorites cleared).
- **result**: Success — AR 375px: card hearts toggle, rail shows «♥ المفضلة» + «مسح الكل» with correct AR mini cards (كابتشينو «من ١٧٬٠٠٠ SYP», كنافة), sheet heart added Kunafa and rail updated; hard-reload persistence verified (2 favs survive re-render incl. post-deep-link state); rail ✕ removed one (favs [كنافة]); Clear emptied + hid rail. EN 375px: sheet heart aria «Remove from favorites», rail «♥ Favorites» / «Clear» with Cappuccino, no overflow. Console only pre-existing favicon 404.
- **files**: `index.html` (fav-rail DOM, CSS heart/rail/pd-fav, FAVORITES module, favBtnHTML in card, pd-fav-btn in sheet, render() calls renderFavRail), memory/events.md
- **errors**: None (test note: the AR wrap card lookup by «راب دجاج» missed — the seeded AR name differs; no code impact).
- **lessons**: keep favoriting fully client-side (no per-item table needed) — localStorage suits a QR-per-table audience; reuse the existing `cardPriceHTML` so variant-aware "From" prices carry into the rail for free.
- **tags**: p2.1, favorites, localStorage, favorites-rail, heart-toggle, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0029

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P2.2 — Voice search (Web Speech API wrapper)
- **summary**: Wrapped the P1.8 search overlay with a thin voice layer: (1) mic button `.voice-btn` in the search header between input and close (hidden via `initVoice()` when `window.SpeechRecognition || window.webkitSpeechRecognition` is missing); (2) `toggleVoice()` creates `rec = new SR()`, sets `rec.lang = lang==='ar' ? 'ar-SA' : 'en-US'`, `interimResults=false`, `maxAlternatives=1`; `onstart` toggles `.recording` (`.voice-btn.recording` + `@keyframes rec-pulse` red pulse) + «🎤 استمع الآن… / 🎤 Listening…» toast; `onresult` puts the transcript into `#search-input` and calls `searchRender(t)` so results flow through the existing normSearch pipeline; `onend` clears state; `onerror` maps codes (`not-allowed`/`service-not-allowed`, `no-speech`, `audio-capture`, `network`) to localized toasts via `voiceErrMsg()`; (3) `stopVoice()` guard used when toggling off mid-listen; (4) `openSearch()` localizes mic aria-label/title (بحث صوتي / Voice search).
- **result**: Success (structural) — AR 375px: mic visible, aria/title «بحث صوتي», Arabic placeholder, no overflow; EN 375px: mic visible, «Voice search», English placeholder. Page loads without JS errors after fixing a **TDZ bug** (`initVoice()` was called before the `const SR` declaration — ReferenceError "Cannot access 'SR' before initialization"; fixed by moving the call to the end of the init IIFE). `new SR()` constructs (`hasRec:true`), but the full onstart/onresult cycle cannot complete in the DevTools page because mic permission/audio capture is not granted in that context — environmental; code path matches the standard Web Speech API contract and leaves no stuck state (stopVoice/onend clear `recActive`).
- **files**: `index.html` (search-head mic button, .voice-btn/.recording/rec-pulse CSS, VOICE SEARCH module after searchRowHTML, openSearch localizes mic labels, init IIFE calls initVoice), memory/events.md
- **errors**: ReferenceError before initialization (TDZ) — root cause: top-level `const SR` declaration appears later in source than the `initVoice()` call site; fix moved the call after the module. Lesson: any top-level `const` used by a hoisted function must be initialized before the function is *invoked*, not merely declared.
- **lessons**: voice UI must hide gracefully when there is no SpeechRecognition; bind recognition language to the active UI language and re-run search through the existing normalized pipeline so Arabic diacritics still match.
- **tags**: p2.2, voice-search, web-speech-api, speechrecognition, aria, toast, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0030

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P2.3 — Similar products rail (same category)
- **summary**: Added a horizontal "مشابهة / Similar" rail inside the product sheet for same-category items: `similarHTML(item)` filters `items` by `category_id === item.category_id && id !== item.id` (limit 10), renders mini cards reusing the P2.1 fav-card visual language (`.fav-thumb`/`.fav-name`/`.fav-price`, so variant-aware "From" prices carry over for free), each card's tap re-opens `openProductSheet(otherId)`; section hidden when the category has only the current item; injected into `pd-body` between the allergen section and the order-note. CSS `.similar-sec/.similar-head/.similar-track` (horizontal scroll, hidden scrollbar).
- **result**: Success — AR 375px: Cappuccino sheet shows «مشابهة» with قهوة عربية (١٥٬٠٠٠ SYP) + قهوة تركية (١٢٬٠٠٠ SYP); tapping a card switched the sheet to «قهوة عربية» (still 2 similar cards, no overflow). EN 375px: deep link `?item=<Cappuccino>#en` auto-opened the sheet, heading «Similar», cards "Arabic Coffee"/"Turkish Coffee", no overflow. Console clean.
- **files**: `index.html` (SIMILAR PRODUCTS module before VOICE SEARCH, .similar-* CSS, `${similarHTML(item)}` in sheet), memory/events.md
- **errors**: Test-only — visited `#en?item=…` (query inside the hash) which breaks lang detection + deep link; correct ordering is `?item=…#en` (P1.10 pattern).
- **lessons**: reuse the fav-card mini-card styles for any horizontal "related" rail — consistent and free variant pricing; keep URL query params before the `#lang` hash.
- **tags**: p2.3, similar-products, related-rail, product-sheet, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0031

- **timestamp**: 2026-09-08
- **mode**: BUILD / PWA / LOCAL-VERIFY
- **action**: P2.4 — PWA: manifest + service worker + install prompt
- **summary**: Made the public app installable with zero deps: (1) `manifest.webmanifest` (name "Judy Joy — QR Menu", short_name "Judy Joy", `start_url ./index.html`, `display standalone`, portrait, theme/background `#0d0a07`, icons 192/512 any + 512 maskable); (2) three PNG icons generated with PowerShell System.Drawing (`icon-192.png`, `icon-512.png`, `apple-touch-icon.png` — dark bg + gold circle); (3) `sw.js` — precache app shell (index/config/manifest/icons), `install` → `skipWaiting`, `activate` → clean old caches + `clients.claim`, `fetch` network-first for same-origin navigations (menu updates never stale) with offline fallback to cached shell, cache-first for static assets, non-GET/supabase requests pass through; (4) index.html head gains manifest + apple-touch-icon + mobile-web-app-capable metas; (5) install banner `#install-banner` (fixed above cart FAB) shown from `beforeinstallprompt` (preventDefault + `deferredPrompt.prompt()`), localized «ثبّت التطبيق لفتح القائمة بشكل أسرع / Install…», hidden on `appinstalled`.
- **result**: Success — after fix, `navigator.serviceWorker.ready` resolves (scope `/`, active `activated`, controller true); simulated `beforeinstallprompt` shows the banner with EN «Install the app… / Install»; AR label «ثبّت التطبيق لفتح القائمة بشكل أسرع / تثبيت»; 375px no overflow. Local server serves manifest as text/plain but GitHub Pages serves .webmanifest as `application/manifest+json`. Console only pre-existing favicon 404.
- **files**: `manifest.webmanifest` (new), `sw.js` (new), `icon-192.png`/`icon-512.png`/`apple-touch-icon.png` (new, generated), `index.html` (head PWA metas, install-banner markup+CSS, PWA module in init), memory/events.md
- **errors**: (1) PowerShell `$size-8` mangled by the parser as object-array subtraction → icons initially saved as flat colors; fixed by `[int]` casts + explicit param types. (2) SW never registered because `setupPWA()` attached a `window.load` listener but the init IIFE (which calls setupPWA) only runs after the remote data fetch resolves — `load` had already fired; fixed by registering immediately (script is at end of body).
- **lessons**: when registering a service worker from an async init path, register directly, never rely on `window.load` — the load event may precede data-driven init; always confirm with `navigator.serviceWorker.ready` (scope/active/controller) rather than assuming registration happened.
- **tags**: p2.4, pwa, manifest, service-worker, install-prompt, beforeinstallprompt, icons, offline, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0032

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P2.5 — WiFi info block (network/password/copy)
- **summary**: Added a "واي فاي / WiFi" section to the public Info modal with zero deps: migration `alter table shops add column if not exists wifi_name text default '', add column if not exists wifi_pass text default '';` (seeded JudyJoy_WiFi / jj2026); public `renderInfo()` renders `shop.wifi_name` (dir=ltr) + optional password row with a 📋 copy button → `copyWifiPass()` (clipboard when secure context, textarea + execCommand fallback, toast «✓ تم نسخ كلمة المرور / ✓ Password copied»); admin Shop Settings gains a WiFi card (`#s-wifi-name`/`#s-wifi-pass`) persisted by `saveShop`; CSS `.wifi-block/.wifi-row/.wifi-cap/.wifi-val/.wifi-act`; schema.sql updated (columns + P2.5 migration note).
- **result**: Success — AR 375px: Info shows «واي فاي» with الشبكة JudyJoy_WiFi + كلمة المرور jj2026 + copy button; copy toast «✓ تم نسخ كلمة المرور»; EN 375px: «WiFi», Network/Password rows, labels ltr; no overflow. Admin save path proven: change pass to test123 in UI → API select shows test123 → restored to jj2026. Console only pre-existing favicon 404.
- **files**: `docs/schema.sql`, `admin.html` (i18n wifi_block/wifi_name/wifi_pass, WiFi card, saveShop), `index.html` (wifiSection in renderInfo, copyWifiPass, .wifi-* CSS), memory/events.md. DB: shops.wifi_name/wifi_pass seeded.
- **errors**: None.
- **lessons**: the copy pattern (secureContext clipboard first, execCommand fallback) is now reusable — consider a shared helper for copyWifiPass vs copyProductLink.
- **tags**: p2.5, wifi-info, copy-password, info-modal, db-migration, admin-editor, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0033

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P2.6 — Takeaway / dine-in order mode toggle (affects WhatsApp message)
- **summary**: Added an order-type choice to the review sheet: (1) `orderMode` ('dinein'|'takeaway') persisted per device via localStorage `qm-order-mode`; (2) `.om-row` with two pill buttons `🍽️ في المكان / 🥡 سفري` (EN: Dine-in/Takeaway) rendered at the bottom of `renderOrderSheet()` above the note, `setOrderMode(m)` re-renders and saves; (3) `orders.order_mode` column (migration `alter table orders add column if not exists order_mode text default 'dinein'`) and `sendWhatsApp()` inserts it; (4) WhatsApp message gains a BMP-safe mode line right after the title — «طلب سفري (TAKEAWAY)» / «في المكان (DINE-IN)» (no emoji in the wa text because the redirect strips non-BMP); (5) schema.sql updated.
- **result**: Success — AR 375px: «نوع الطلب», tap 🥡 سفري → active/pressed transitions + localStorage saved; full `sendWhatsApp()` with stubbed window.open produced «*طلب جديد #1 — Judy Joy*\nطلب سفري (TAKEAWAY)\n• كابتشينو × 1 — ٢٠٬٠٠٠ SYP / المجموع» and the inserted orders row carried `order_mode=takeaway` (verified via API, then deleted test row id=1). EN 375px: «Order type», 🍽️ Dine-in / 🥡 Takeaway, active state + storage verified, no overflow. Also fixed a DevTools form-field a11y issue (stepper qty inputs now `name="qty"`).
- **files**: `docs/schema.sql` (order_mode column + note), `index.html` (state, setOrderMode, .om-* CSS, renderOrderSheet mode row, insert order_mode, WA line, stepper name attr), memory/events.md. DB: orders.order_mode.
- **errors**: None (test order cleaned up after verification).
- **lessons**: reuse the localStorage-on-toggle pattern for per-device preferences; keep wa.me lines BMP-safe with plain-text mode tags instead of emoji.
- **tags**: p2.6, order-mode, dinein, takeaway, wa-message, db-migration, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0034

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P2.7 — Table/QR per-table attribution (?table= → order sheet, WhatsApp, orders)
- **summary**: Public page now reads `?table=<id>` (clean label, e.g. "5", "A12", "balcony"): parsed in the init IIFE after the deep-item block into module `tableLabel`; the review sheet shows a dashed chip row «🪑 5 / Table 5» above the order-mode toggle (`tableRow` in `.om-foot`, `.table-chip`); `sendWhatsApp()` inserts a BMP-safe line right after the mode line — «الطاولة: 5 / Table: 5» — and persists `orders.table_label` (migration `alter table orders add column if not exists table_label text default '';`). No table → chip and WA line omitted entirely. Share links (`cleanUrl`) already carry `window.location.search`, so ?table= + ?item= coexist in deep links.
- **result**: Success — AR 375px `?table=5#ar`: «الطاولة» chip 🪑 5, full stubbed sendWhatsApp produced «*طلب جديد #2 — Judy Joy*\nفي المكان (DINE-IN)\nالطاولة: 5\n• كابتشينو × 1 — ٢٠٬٠٠٠ SYP»; orders row id=2 carried `table_label=5` (verified via API, then deleted). EN `?table=5#en`: «Table» + 🪑 5 chip, no overflow. Console clean (only favicon 404) — previous form-field a11y issue resolved by `name="qty"`.
- **files**: `docs/schema.sql` (table_label column + note), `index.html` (tableLabel state, init parse, tableRow chip, .table-chip CSS, WA line, insert), memory/events.md. DB: orders.table_label.
- **errors**: None (test order cleaned up).
- **lessons**: the `?table=` param pattern makes any QR a per-table QR with zero admin work — post-GA QR generator just encodes `https://amworx.github.io/qr-menu/?table=<id>` (+ optional `&item=`).
- **tags**: p2.7, table-attribution, qr-param, wa-message, db-migration, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0035

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / I18N / LOCAL-VERIFY
- **action**: P2.8 — Multi-outlet selector (shop → outlets, per-outlet WhatsApp, admin CRUD)
- **summary**: New `outlets` table (id, shop_id FK cascade, name/name_ar, whatsapp, address/address_ar, sort_order, is_active, created_at) + RLS (select to all; owner insert/update/delete via shops.owner_email = auth.email()); `orders` gains `outlet_id uuid` FK + `outlet_label` snapshot. Seeded 2 demo outlets for Judy Joy (Main Branch/الفرع الرئيسي, Branch 2/الفرع الثاني, both 963992656853). PUBLIC: fetches active outlets, persists choice in localStorage `qm-outlet-id`; order sheet shows a `<select class="om-select">` branch row («الفرع / Branch») above table/mode rows only when ≥2 active outlets; WhatsApp gets a BMP-safe «الفرع: … / Branch: …» line after the title; `sendWhatsApp()` routes to `(selectedOutlet.whatsapp || shop.whatsapp)` and inserts outlet_id + outlet_label. ADMIN: Shop Settings gains an Outlets card (`outletsEditorRows`, `addOutletRow`, `removeOutletRow` with `removedOutletIds`, `saveOutlets()` called from `saveShop()`), i18n keys, `.outlet-row` grid CSS (+ mobile 2-col); `showDashboard` loads outlets.
- **result**: Success — PUBLIC AR 375px: «الفرع» select shows الفرع الرئيسي/الفرع الثاني, stubbed sendWhatsApp headed «*طلب جديد #5…\nالفرع: الفرع الرئيسي\nفي المكان (DINE-IN)», order row recorded outlet_label; switched to Branch 2 → «الفرع: الفرع الثاني». EN 375px: Branch / Main Branch / Branch 2, no overflow. ADMIN AR/EN: card + rows render; add → save → DB verified (Test Branch rows inserted), delete → save → DB verified removed; also fixed a real bug: after adding a new row and saving, the DOM row kept `data-oid=""` so a later delete was silently skipped — `saveOutlets()` now re-renders `#s-outlets` after reload so saved rows carry DB ids. Console: admin has pre-existing label/attr a11y issues (not P2.8); public clean (only favicon 404).
- **files**: `docs/schema.sql` (outlets table + RLS + orders cols + note), `index.html` (outlets state/fetch, branch select + CSS, WA line, routing, insert), `admin.html` (outlets card, editor CRUD, saveShop integration, i18n, CSS), memory/events.md. DB: outlets seeded; orders.outlet_id/outlet_label.
- **errors**: Test Branch delete silently skipped until fix (stale data-oid after add-and-save) — solved by re-rendering rows post-save.
- **lessons**: 1) After any admin upsert, re-render the edited rows so DOM ids stay in sync with DB — otherwise subsequent deletes are skipped. 2) Chrome DevTools shows SW-cached stale pages when the local server dies; always re-check `navigator.serviceWorker.controller`/doc size after a server restart, and use a real reload (not hash navigation) + unregister SW before trusting local verification. 3) Read API responses with the Read tool, not PS 5.1 Get-Content (Arabic displays as mojibake/`?` in the console but is stored correctly).
- **tags**: p2.8, multi-outlet, outlets, branch-selector, wa-routing, admin-crud, db-migration, rls, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0036

- **timestamp**: 2026-09-08
- **mode**: BUILD / DB-MIGRATION / EDGE-FUNCTION / I18N / LOCAL-VERIFY
- **action**: P2.9 — Satisfaction survey (rating + comment → edge function → DB)
- **summary**: `surveys` table (id bigserial, shop_id FK restavras, rating 1..5 CHECK, comment <= 500, created_at) + RLS (anon insert with check, owner select). New edge function `supabase/functions/submit-survey/index.ts`: CORS headers, OPTIONS 204, POST validation (uuid shop_id, integer rating 1..5, comment slice 500), insert via service role, 201 {ok,id}. Deployed with `--no-verify-jwt` (public endpoint — the function itself validates). Public: `#survey-modal` center dialog + `.survey-card`, `showSurvey/renderSurvey/setSurveyRating/closeSurvey/submitSurvey`, 5 ★ buttons, comment textarea, submit + skip; trigger `setTimeout(showSurvey, 900)` at the end of `sendWhatsApp()` after the toast. submitSurvey posts to `${SUPABASE_URL}/functions/v1/submit-survey` with the anon key and shows localized toasts.
- **result**: Success — CLI deploy OK; curl POST → `{"ok":true,"id":1}` 201 (verified via Management API, cleaned up); browser AR: after sendWhatsApp the modal appears «كيف كانت تجربتك؟», 4/5 stars toggle, submit → modal closes + toast «شكراً لتقييمك! 💛», surveys row created (id=2, verified, cleaned up); EN 375px: "How was your experience?", "Submit rating", "Later", 3/5 stars, no overflow; OPTIONS preflight returns 204 + valid CORS headers (browser fetch works). Console clean on public.
- **files**: `docs/schema.sql` (surveys note + DDL), `supabase/functions/submit-survey/index.ts` (new), `index.html` (survey modal markup, CSS, JS, trigger), memory/events.md. DB: surveys. Deployed edge function.
- **errors**: 1) raw fetch from browser failed → gateway requires JWT on preflight; redeployed --no-verify-jwt. 2) Then preflight still failed: `new Response('ok', {status:204})` is invalid (204 must have no body) → Edge Runtime 500 EDGE_FUNCTION_ERROR; fixed with `new Response(null, ...)`.
- **lessons**: in Supabase edge functions keep 204 preflight bodies empty (runtime rejects bodyful 204 with a 500); for public endpoints use --no-verify-jwt + server-side validation instead of fighting the gateway's JWT-enforced preflight. Deploy works without Docker from Windows (falls back to API deploy).
- **tags**: p2.9, survey, rating, edge-function, deno, cors, no-verify-jwt, db-migration, rls, i18n, mobile-375, local-verify, pending-commit

## EVT-20260908-0037

- **timestamp**: 2026-09-08
- **mode**: BUILD / I18N / LOCAL-VERIFY
- **action**: P2.10 — Campaign/promo landing modal (one-time per campaign)
- **summary**: Full `#campaign-modal` center dialog (reuses `.survey-modal`/`.survey-card` styles) shown ~1.1s after first paint unless a product deep-link (`?item=`) is active. Features `deals[0]` (first active deal): 🔥 badge, eyebrow «عرض خاص 🔥 / SPECIAL 🔥», localized title/desc, `dealSummary(d)` badge, CTA «اطلب الآن / Order now» → `useCampaign(id)` closes + `toggleOffer(id)` (adds to order, re-renders deals/cart) + skip «لاحقاً / Later». One-time via `localStorage 'qm_campaign_seen' = <deal id>` (set before showing) — same campaign never re-opens; a new featured deal re-shows once. `showCampaign/closeCampaign/renderCampaign/useCampaign` + `.promo-*` CSS.
- **result**: Success — AR 375px: modal «العرض #1», CTA «اطلب الآن», badge «اشترِ 2 واحصل على 1 مجاناً», no overflow; CTA closes + adds offer + deal card shows added + toast; reload with seen flag → modal does NOT re-open (one-time works); EN 375px: "SPECIAL 🔥 / Offer #1 / Order now / Later", no overflow. Console clean except pre-existing favicon 404.
- **files**: `index.html` (campaign modal markup, `.promo-*` CSS, trigger in init, campaign JS block), memory/events.md. No DB changes.
- **errors**: none.
- **lessons**: one-time promo = compare `localStorage 'qm_campaign_seen'` against the CURRENT featured deal id (not a boolean) so a new campaign naturally shows again; seed the flag before showing the modal to avoid re-open on reload. Reuse existing modal CSS classes rather than duplicating overlay styles.
- **tags**: p2.10, campaign, promo, landing, one-time, localStorage, deals, i18n, rtl, mobile-375, local-verify, pending-commit

## EVT-20260908-0038

- **timestamp**: 2026-09-08
- **mode**: MEMORY / SESSION-WRAP
- **action**: Session wrap-up — Phase 2 fully closed, Phase 3 deferred
- **summary**: User reviewed the gap-closing work (P2.5 WiFi, P2.6 order mode, P2.7 table attribution, P2.8 multi-outlet, P2.9 survey, P2.10 campaign) and decided to leave Phase 3 (platform/large: AI concierge, extra languages, tenant theme editor, desktop mockup stage, loyalty) untouched for now. They will inspect the shipped work and return with fixes if needed.
- **result**: Paused — no pending work. Commits this session: 33dd668 (P2.8), ae23d1d (P2.9), eb721f4 (P2.10), e0555b0 (plan marks). All live. Phase 3 + any post-inspection fixes await explicit user request.
- **files**: memory/events.md only (informational event)
- **errors**: none
- **lessons**: none new
- **tags**: session-wrap, phase2-done, phase3-deferred, parked-for-user-review

## EVT-20260908-0039

- **timestamp**: 2026-09-08
- **mode**: BUILD
- **action**: Admin Badges + Allergens CRUD pages and Orders status/reply (A1/A2/A3)
- **summary**: New user request: separate admin pages to CRUD Badges and Allergens, plus admin order interaction (status updates + WhatsApp replies). Implemented: shop_badges catalog + items.custom_badges (ids); shop_allergens catalog (14 EU FIC pre-seeded per shop) + items.allergens stays codes; orders.status check constraint + orders.customer_phone, public order sheet optional phone field (localStorage qm-phone), admin Orders tab status filter + per-row status select + Reply modal (wa.me pre-filled, phone copy + persist back). item_allergens junction created then dropped (Option A: jsonb codes is the source of truth). Verified AR/EN/375px both pages; test data cleaned (0 badges, 0 orders).
- **result**: Working locally. DB migrations applied via Management API. Bugs fixed during testing: duplicate `const phone` (renamed customerPhoneInput), openReplyModal/sendReply/updateOrderStatus id lookup string-vs-number (String() compare).
- **files**: admin.html, index.html, docs/schema.sql, memory/events.md
- **errors**: duplicate const phone -> SyntaxError; undefined order id in reply modal (Number vs id object)
- **lessons**: another duplicate-identifier collision risk when adding fields to existing functions; always pass ids as primitives and String()-compare lookups
- **tags**: badges, allergens, orders, admin, whatsapp-reply, p3

## EVT-20260909-0001

- **timestamp**: 2026-09-09
- **mode**: BUILD
- **action**: Public menu UX redesign + switch UI chrome icons to Font Awesome Free
- **summary**: Redesigned the public app layout for better first-paint content and desktop usage: compact hero (223→~169px), taller 49px category pills with RTL-aware edge fade, slim deals wall (212→170px, 2-line clamp), favorites rail converted to inline pills (157→100px), menu wrap max-width 640→1080px centered with auto-fill item grid (2-col mobile → up to 4-col desktop), square 1:1 card images + uniform rows + CTA pinned to card bottom, cart FAB reworked to full-width bottom bar on mobile (351x62) / centered pill <=560px on desktop. Then replaced UI chrome emojis with Font Awesome Free 6.7.2 (CDN css link in index.html + admin.html): controls (grid/list, sun/moon, search, info), hearts (solid/regular swap), contact row (brand whatsapp/phone/envelope), deal+meta fire/clock, sheets closes/xmark, link, share-nodes, location-dot, wifi/key/clipboard, socials brands, order mode utensils/bag-shopping, chair, whatsapp button + spinner, cart-shopping, utensils empty states. Kept content emojis (allergen chips, emojiFor thumbs, status dots, WA message ★/♥ markers, toasts). User chose "free set" after Jelly required Pro (no kit code).
- **result**: Verified locally via DOM measurement: no horizontal overflow (375==375, desktop 1265==1265), first item y=469→458 (was 735), tabs 49px, uniform card rows, cart bar + order/product sheets + search + dark mode + RTL + list/grid toggle all intact, console only favicon 404. Commit f752092 pushed, GitHub Pages built, 10/10 live markers verified (index: FA css, controls, contact-wa, order-wa, grid-1080, item-col-square, rail-fade, heart-swap; admin: FA css, xmark). Screenshots saved to temp: qm_redesign_ar_mobile.png, qm_redesign_desktop.png, qm_icons_ar_mobile.png.
- **files**: index.html, admin.html, memory/events.md
- **errors**: none
- **lessons**: horizontal scroll strips need edge fading; icons-in-buttons need pointer-events:none so clicks don't hit the <i>; when swapping textContent→innerHTML for icons keep aria-labels; PowerShell -match on curl array output returns elements not boolean - join to string first
- **tags**: ux, redesign, responsive, grid, cart-bar, font-awesome, icons, cdn, rtl, dark-mode, mobile-375, desktop, live-verify

## EVT-20260909-0002

- **timestamp**: 2026-09-09
- **mode**: BUILD
- **action**: Store location (admin map) + customer delivery location (public map) + Info Directions button
- **summary**: Owner sets the store pin in Shop Settings via an interactive Leaflet map (OSM tiles + Nominatim search/reverse-geocode + geolocate + drag/click pin + clear). DB: shops.location_lat/lng; public order sheet gains third order mode Delivery with an interactive location picker (same map, pin persisted per device qm-dlat/qm-dlng/qm-dladdr, reverse geocode fills the editable address field, must-have-pin validation before send); orders gains delivery_address/lat/lng + order_mode CHECK constraint extended to include delivery. WhatsApp message adds Delivery label + address + Google Maps q=lat,lng link; admin Orders rows show delivery address + Map link. Info modal "Directions" is now a prominent .dir-btn using shop pin (falls back to address search when no pin). Applied migration live via Management API.
- **result**: Local verification passed: admin pin save -> DB (33.5138,36.2765), search box -> real Afrin coords with auto address (not saved), clear pin; public AR/EN/375/desktop: 3 mode buttons, delivery block + Leaflet map, reverse geocode fills address, validation toast blocks send without pin, WA message contains Delivery + address + maps link, real order #9 inserted with delivery fields then deleted; admin order row shows delivery address + link. After testing, reset stored pin + auto-filled address fields to NULL/' ' because test coords were Damascus while the shop is in Afrin (about says عفرين) — owner must set the real pin via the new UI. Screenshots: qm_delivery_map_ar_mobile.png, qm_admin_location_card.png.
- **files**: admin.html, index.html, docs/schema.sql, memory/events.md
- **errors**: one edit accidentally removed `if (!list || list.length === 0) {` from outletsEditorRows -> SyntaxError "Illegal return statement" + loginWithEmail not defined; fixed by restoring the guard (validated all inline scripts with `node --check` before reloading).
- **lessons**: after any multi-edit session, run node --check on each inline `<script>` block before browser testing; never save auto-filled reverse-geocode test addresses into production rows — reset after testing.
- **tags**: location, map, leaflet, osm, nominatim, delivery, geo, admin, orders, whatsapp, directions, p3.1

## EVT-20260909-0003

- **timestamp**: 2026-09-09
- **mode**: BUILD / DEPLOY
- **action**: Deploy P3.1 (store location + customer delivery + directions button)
- **summary**: User approved deploy. Committed 1021dd6 "feat: store location map + customer delivery location + directions button (P3.1)" (4 files, +304/-7) and pushed origin main. GitHub Pages build status=built (2026-09-09T19:15:43Z). Live-verified 11/11 markers on amworx.github.io/qr-menu: index leaflet css+js, delivery mode button, dl-map, dlInit, dir-btn, fa-truck-fast; admin leaflet css, shop-map, shopLocInit, dl-inline.
- **result**: Live. Remember: shop pin + address fields are empty in DB (test values reset) - owner must set the real pin via Shop Settings > Store Location for the Directions button to show coordinates.
- **files**: index.html, admin.html, docs/schema.sql, memory/events.md
- **errors**: none
- **lessons**: none new
- **tags**: deploy, pages, p3.1, live

## EVT-20260909-0004

- **timestamp**: 2026-09-09
- **mode**: BUILD
- **action**: Fix offer "0 value" bug + admin deal price-after-discount preview
- **summary**: Public order sheet: each offer line now renders a positive "price after discount" instead of blank/0. New dealAfterValue(d) in index.html: bundle -> bundle_price (deal currency), bogo -> buy_qty x unit, percent/fixed -> scopeSubtotal - savings, min_order -> subtotal - savings; returns null when not determinable -> the line shows a muted dash (no more 0). computeOrder() adds value to each offer; totals math untouched (offers still discount lines). Admin deal modal: added live "Price Preview" block (Price Preview / Original price / New price after discount / savings chip / hint). New updateDealPreview() + adminItemPrice() + pfmt() + dealPreviewPair(): bundle uses real sum of selected item prices vs bundle price; bogo uses real item price (buy+get -> buy); percent/fixed show example on 100,000 basis; min_order uses its threshold basis. Recomputes on type switch + every field input/change (percent/fixed values, buy/get, item select, bundle checkboxes, bundle price, currencies, min/reward). AR + EN labels.
- **result**: Verified locally (AR + EN, mobile 375 + desktop): fixed deal alone -> dash (not 0); fixed with 1 Arabic Coffee -> line shows 14,900 SYP (15,000-100); BOGO 2x25,000 -> 50,000; percent 10% on 65,000 scope -> 58,500; min_order (60,000/10% -> 58,500, fixed 500 -> 64,500); bundle with 2x15,000 items -> 30,000 -> 20,000 (-10,000). Admin preview: percent 10 -> 100,000->90,000, fixed 5,000 -> 100,000->95,000, bogo 45,000->30,000, bundle 30,000->20,000, min 50,000->45,000/46,000; empty states show hint; AR text verified (?????? ????? etc.). node --check passed on all inline scripts. Console clean both pages (favicon 404 only). Percent deal "Mega Offer" is expired (ends_at 2026-09-09 00:00) so hidden from the public deals wall - expected.
- **files**: index.html, admin.html, memory/events.md
- **errors**: test selector used Arabic name on bundle chips which display English names (admin item.name) - selector bug only, app fine
- **lessons**: admin bundle chip labels use English item names; deal offers are discount lines, so "price after discount" per deal is a display value only - never change the totals math; percent/fixed/min deals that don't yet qualify for the cart show a muted dash, not 0
- **tags**: deal, offer, price, discount, order-sheet, admin, preview, bugfix


## EVT-20260909-0005

- **timestamp**: 2026-09-09
- **mode**: BUILD
- **action**: Theme-aware scrollbar design (public + admin)
- **summary**: Vertical scrollbars on the page body, order/product/search/info sheets (index.html) and admin main content/modals/table wraps (admin.html) were browser-default gray and clashed with the dark coffee/slate themes. Added thin pill scrollbars: WebKit via *::-webkit-scrollbar (9px, transparent track, rounded thumb with 2px inner border via background-clip:padding-box, hover state) and Firefox via *{scrollbar-width:thin;scrollbar-color:thumb transparent}. Public page defines --scr-thumb/--scr-thumb-hover per theme (:root[data-theme=dark] warm cream rgba(245,239,230,.18/.34); light coffee rgba(41,29,18,.18/.34)). Admin uses slate --text2 tone rgba(148,163,184,.35/.6). Horizontal rails (.cat-tabs/.deals-scroll/.fav-track/.similar-track and admin .mobile-tabs) keep scrollbar-width:none + edge fade - unchanged.
- **result**: Verified computed styles: public dark thumb rgba(245,239,230,.18) transparent, light rgba(41,29,18,.18), admin rgba(148,163,184,.35); scrollbar-width thin everywhere, rails still 'none'; no horizontal overflow (0px at 375 and 1280); all inline scripts pass node --check. Screenshots saved: qm_scrollbar_dark_desktop.png, qm_scrollbar_light_desktop.png, qm_admin_scrollbar_mobile.png.
- **files**: index.html, admin.html, memory/events.md
- **errors**: none
- **lessons**: on non-overlay desktop browsers the 9px pill scrollbar reserves width - verified zero layout shift; keep horizontal rails hidden (edge fade) so only real vertical/horizontal scroll containers get styled thumbs
- **tags**: ui, scrollbar, theme, webkit, firefox, dark-mode, light-mode, admin, polish


## EVT-20260909-0006

- **timestamp**: 2026-09-09
- **mode**: BUILD / DEPLOY
- **action**: Deploy offer price fix + admin deal preview + theme-aware scrollbars
- **summary**: User approved deploy. Committed 64072b0 "feat: offer price after discount (order + admin deal preview) + theme-aware scrollbars" (3 files, +171/-17: index.html, admin.html, memory/events.md; supabase/.temp/ left untracked) and pushed origin main. GitHub Pages build status=built (2026-09-09T20:02:36Z, no error). Live-verified 8/8 markers: index dealAfterValue, offers value field, .ol-muted dash, --scr-thumb scrollbar vars; admin updateDealPreview, price_preview i18n, .deal-preview.muted, scrollbar-width:thin.
- **result**: Live. Live QR menu now shows offer after-discount price lines (dash instead of 0 when not determinable) and admin deal modal has live price preview; both pages have thin theme-aware pill scrollbars.
- **files**: index.html, admin.html, memory/events.md
- **errors**: none
- **lessons**: none new
- **tags**: deploy, pages, offers, pricing, scrollbar, live


## EVT-20260909-0007

- **timestamp**: 2026-09-09
- **mode**: BUILD / DEPLOY
- **action**: Fix cart bar FAB showing 0 for offers-only cart
- **summary**: User reported offer price fix "not working". Reproduced on live site: order sheet + totals were correct once items were present (fixed + coffee = 14,900), but the FAB (cart bar) still displayed ? SYP when the cart contained ONLY an offer. root cause: updateCartBar() always rendered formatPrice(o.total) and an offers-only cart has total 0. Fix in index.html: when totalItems===0 && offerCount>0, FAB shows the determinable after-discount value (bundle/BOGO e.g. BOGO alone = 50,000) summed from offer.value, else a hint label `??? ???????`/`Add items` (.cart-total-hint CSS) instead of a misleading 0. Verified locally in AR: BOGO alone -> ?????? SYP, fixed alone -> hint, fixed+item -> ?????? SYP. Committed 24c20ba "fix: cart bar shows offer after-discount value or add-items hint instead of 0" (1 file +20/-2), pushed, Pages built, 4/4 live markers present (hint css, ar/en strings, standalone branch).
- **result**: Live. No screen shows a bare 0 for an added offer anymore.
- **files**: index.html, memory/events.md
- **errors**: none
- **lessons**: The offer fix surface includes the cart bar (FAB), not just the order sheet; when offers-only, the honest total is the determinable offer value or a guidance label, never 0. PWA: users must refresh (network-first SW) to get the new code.
- **tags**: deploy, offers, pricing, cart-bar, pwa


## EVT-20260909-0008

- **timestamp**: 2026-09-09
- **mode**: BUILD / DEPLOY
- **action**: Remove always-visible fav-del (X) button from favorites rail cards
- **summary**: User reported the `.fav-del` button (fa-xmark, aria-label ?????) is "always there". Reproduced: it is rendered per-card inside the favorites rail (renderFavRail) whenever an item is favorited; on the user''s device Arabic Coffee (e742e7b1) is a favorite, so the X persisted on its rail card. Fix: removed the fav-del markup from renderFavRail() template and deleted the two now-dead .fav-del CSS rules (0 occurrences in file). Rail cards now show thumb + name + price and open the product sheet on tap; favorites remain manageable via product-sheet heart and the rail "??? ????/Clear" header button. Verified locally with a favorited item (rail shows, no fav-del anywhere) and live (0 fav-del occurrences in deployed HTML).
- **result**: Live. Deployed ee5bbae "fix: remove always-visible fav-del button from favorites rail cards" (1 file, -3) - Pages built.
- **files**: index.html, memory/events.md
- **errors**: none
- **lessons**: The favorites rail X was a per-item removal affordance, but users found it cluttered; removal keeps management via sheet heart + clear-all. Check both main-card hearts (fav-heart) and rail X (fav-del) when tuning favorite toggles.
- **tags**: ui, favorites, rail, deploy


## EVT-20260909-0009

- **timestamp**: 2026-09-09
- **mode**: BUILD / DEPLOY
- **action**: Fix top controls stacking over sticky category rail on scroll
- **summary**: User reported "top icons and categories stack on each other when scrolling down". Reproduced: .controls (fixed top:14, z-index 60: view/theme/currency/search/info/lang) overlapped .rail-wrap (sticky top:0, z-index 50) once scrolled (measured overlap: true at scrollY 900, RTL). Fix: added id="floating-controls" on .controls, .controls.fade CSS (opacity 0, pointer-events none, translateY -10, .22s transition), and setupFloatControls() scroll listener (rAF-throttled, passive): hide when scrollY > 160 and scrolling down; show on scroll-up or near top. Verified locally: scroll to 900 -> faded (opacity 0), rail top 0; scroll up to 400 -> visible; top -> no overlap (rail not stuck). Deployed e7751f3 "fix: hide floating top controls while scrolling so they never cover the category rail" (1 file, +21/-1), Pages built, 3/3 live markers.
- **result**: Live. No stacking while scrolling down; controls reappear on scroll-up.
- **files**: index.html, memory/events.md
- **errors**: none
- **lessons**: Fixed floating controls over a sticky bar collide visually; rAF-throttled scroll-hide is the lightweight standard fix. Keep pointer-events:none so hidden controls never block taps.
- **tags**: ui, sticky, scroll, controls, deploy


## EVT-20260910-0001

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY
- **action**: Implement hero-blended utility button + bottom sheet (Option 2 design)
- **summary**: After the user approved the refined Option 2 mock (hero-blended button), replaced the old floating `.controls` (6 pill circles: view/theme/currency/search/info/lang at fixed top-right, z 60) with: (1) `.hero-util` — a 40px glass button (rgba(255,255,255,.14), blur 6, hairline border, shadow) absolutely positioned inside the hero at top:14 inset-inline-start:14 (z 2), scrolls away with the hero; (2) `.util-modal`/`.util-sheet` bottom sheet (z 100, max-width 520) with grab handle, 6 rows (Appearance/Language/Currency/View mode/Search/Info) + close X + backdrop-tap + ESC (added closeUtilitySheet() to the existing keydown handler). New JS: toggleUtilitySheet/openUtilitySheet/closeUtilitySheet with hero button `.on` state + aria-expanded, renderUtilitySheet() (localized labels + live values, currency row only when shop has >1 currency and show_currency_selector !== false), utilSearch/utilInfo (close sheet then open modal). Rewired renderViewBtn/updateThemeBtn/renderCurrencyBtn + applyLang to the sheet (removed all view-btn/theme-btn/currency-btn/lang-btn refs); deleted setupFloatControls + .controls/.ctl/.fade CSS. Theme/view/currency toggles update the sheet live while it stays open; lang switch re-localizes open sheet. Verified locally AR+EN, mobile 375 + desktop: button inside hero (top offset 14, 40x40), sheet opens with 6 localized rows, theme dark<->light, view list<->grid, currency SYP->USD, search/info open their modals and close the sheet, ESC closes, sticky rail top:0 with ZERO fixed/sticky overlappers at scrollY 500 (original stacking bug gone), console clean, node --check passed.
- **result**: Committed 601acfd "feat: hero-blended utility button + bottom sheet (theme/lang/currency/view/search/info)" (index.html +114/-58 + 3 screenshots in docs/screenshots/; supabase/.temp/ left untracked), pushed origin main, Pages built (2026-09-09T21:09:49Z, commit 601acfd). Verified deployed HTML via direct fetch (hero-util present, floating-controls absent) and on a FRESH browser page (page 11): button inside hero, sheet opens, all 6 rows. Note: existing browser tab served stale SW-cached HTML until SW unregistered + caches cleared + fresh page — users will need one hard refresh / re-scan to see the new UI.
- **files**: index.html, memory/events.md, docs/screenshots/hero-util-btn-ar-dark.png, docs/screenshots/util-sheet-open-ar-dark-mobile.png, docs/screenshots/util-sheet-open-ar-dark-desktop.png, docs/screenshots/util-sheet-open-ar-light.png
- **errors**: chrome-devtools screenshots intermittently timed out after evaluate-driven state changes (MCP/CDP flakiness) — recover by select_page then retry; not an app bug.
- **lessons**: Replacing the floating controls with a hero-anchored button + bottom sheet permanently removes the sticky-overlap bug (no fixed top elements left). When a PWA's SW caches index.html, verification of a new deploy must use a fresh page target, not an existing tab (unregister SW + clear caches there).
- **tags**: ui, redesign, hero, bottom-sheet, controls, i18n, deploy, pwa


## EVT-20260910-0002

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI
- **action**: Theme-aware hero utility button (light mode fix)
- **summary**: User reported the hero util button content is white on the light theme (invisible on the cream hero). The button had hardcoded color:#fff, bg rgba(255,255,255,.14), border rgba(255,255,255,.28). Fix: moved all button colors to theme CSS vars — dark keeps white glass; light uses cocoa --hero-util-bg rgba(41,29,18,.14), hover .24, on .3, border rgba(41,29,18,.22), color #291d12. `.hero-util` now reads var(--hero-util-*). Verified computed styles on localhost: dark icon #fff / light icon rgb(41,29,18), bg var resolves per theme (first immediate read raced/flushed incorrectly; adding a 120ms setTimeout before getComputedStyle gives the correct value — CSS var recalc needs a frame).
- **result**: Verified locally both themes. Screenshot docs/screenshots/hero-util-btn-ar-light.png. Deployed together with EVT-20260910-0003 in commit de8be1a (single Pages rebuild to minimize stale-cache refreshes).
- **files**: index.html, docs/screenshots/hero-util-btn-ar-light.png
- **errors**: none
- **lessons**: When theming a UI element that sits on a gradient hero, define bg/border/color as vars in BOTH theme blocks — don't hardcode white. Reading getComputedStyle immediately after flipping data-theme can return the pre-flip background value; wait one animation frame before asserting.
- **tags**: theme, light-mode, hero, button, css-vars


## EVT-20260910-0003

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI
- **action**: Offer card tweaks — layout polish + show the target item the offer applies to
- **summary**: User asked for offer card alignment/padding/margin tweaks and that the item the offer applies to appears in the card details. Changes in index.html: (1) `.deal-card` padding 12px->26px top so the "عرض خاص/SPECIAL —" ribbon no longer overlaps the title (ribbon height 25.6px); tightened h3/p/badge margins (h3 2px 0 4px, p 0 0 8px, badge 2px 0 12px); (2) new `.deal-scope` row (icon + truncated single-line chip, bg rgba(255,255,255,.12), radius 10) between desc and badge showing localized target: bundle -> first 2 item names +N, bogo -> the buy item, min_order -> whole order, applies_to item/category -> item/category name, else all items; (3) added `.deal-grow{flex:1;min-height:9px}` spacer between badge and the add button so the add button pins to the card bottom uniformly (previously margin-top:auto computed 0px on equal-height cards, so adds sat tight under badges). renderDeals() renders the scope row; new dealScopeLabel(d) helper handles all 5 deal types + AR/EN. Verified: cards equal height 202px, add buttons aligned (21px above / 12px below on both cards), AR text "يطبّق على: مناقيش جبنة" / "يطبّق على كل الأصناف", EN "Applies to: Cheese Manakish" / "Applies to all items", node --check passed.
- **result**: Deployed commit de8be1a (also carries EVT-20260910-0002) — Pages built, fresh live page verified: scope rows render, hero util themed, spacer present.
- **files**: index.html, docs/screenshots/deal-cards-scope-ar-dark-mobile.png, docs/screenshots/deal-cards-scope-en-light-mobile.png
- **errors**: none
- **lessons**: margin-top:auto in a flex column only absorbs leftover space; when sibling cards size to their own content (equal height), leftover is 0 and the CTA isn't pinned — a flex:1 spacer div is the deterministic fix. Ribbon overlays need top padding >= ribbon height, not just breathing-room assumptions.
- **tags**: deals, offer-cards, layout, scope, i18n, deploy

## EVT-20260910-0004

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY
- **action**: uiverse splash loader + animated favorite heart
- **summary**: Replaced the `.cup` spinner loading screen with uiverse massive-falcon-52: `.splash` container (150x150) with two crossed pills (.Strich1 rotate 45 / .Strich2 rotate -90, 130x50, radius 25) + 5 colored bubbles dancing on `dropAndShift` (4-7s, translate 0/80/40px + vertical hop). Pills use var(--text) so they read on both themes (dark cream / light cocoa); colorful radial gradients kept from source. #loading/#loading-text contract preserved (no-shop error path + AR/EN localization). Replaced FA-heart favorite buttons with uiverse plastic-moth-91 animated heart on item cards (`favBtnHTML` now renders `<label class="fav-heart">` with hidden checkbox + outline/filled/celebrate SVGs) and the product sheet (`pd-fav` label, keeps sheet-close/pd-close styles). `toggleFav` untouched; `syncFavHearts` now syncs `checkbox.checked` + aria-label instead of innerHTML (fav rail + toasts + AR/EN/RTL intact). First CSS-scope attempt was dead (selectors `.heart-container ...` matched nothing because the wrapper div was dropped; `.svg-filled` computed `inline`); re-scoped to `.fav-heart/.pd-fav ...`.
- **result**: Verified localhost: filled/celebrate animation names + display flip on toggle, theme-ink pills (dark rgb(245,239,230) / light rgb(41,29,18)), mobile 375px heart-bounds inside card, AR dir=rtl heart at inline-end, product-sheet heart, toast text; `node --check` OK. Committed 40235c2 (`feat: uiverse splash loader + animated favorite heart`) and pushed; live fresh page (SW cleared) verified: 5 splash bubbles, heart label animates, AR toast.
- **files**: index.html, docs/screenshots/2026-09-10-splash-new-loader.png, docs/screenshots/2026-09-10-heart-in-card.png, docs/screenshots/2026-09-10-heart-in-product-sheet.png, docs/screenshots/2026-09-10-heart-ar-rtl-mobile.png, docs/screenshots/2026-09-10-splash-mobile-ar.png
- **errors**: initial heart CSS selectors matched no DOM (dropped .heart-container wrapper) — fixed by re-scoping; splash pill transform computed "none" while loading screen display:none (correct matrix when visible — assertion must render first).
- **lessons**: LSSN-20260910-001 (adapt CSS selectors to the final DOM you ship), LSSN-20260910-002 (hash navigation isn't a reload — hard reload to test locales), LSSN-20260910-003 (loader shapes need theme ink on dark themes)
- **tags**: uiverse, splash, loader, favorites, animation, ui, deploy

## EVT-20260910-0005

- **timestamp**: 2026-09-10
- **mode**: DESIGN / MOCK
- **action**: Temp category-switcher mock using uiverse soft-baboon-75 (do NOT apply to app)
- **summary**: User asked for a test mock design only. Built self-contained `docs/mocks/category-switcher-mock.html` (TEMP, untracked): 390px AR/RTL phone frame using app dark tokens, uiverse glass channel + sliding ball radio as the category switcher with 5 rows (الكل، مشروبات ساخنة، مشروبات باردة، حلويات، ساندويشات), small mock dataset with emoji/price cards filtered below. Glass height auto (align-items:stretch) instead of the source's fixed 210px so it fits 3-5 rows; translateX(-72px) for the ball pool; ball kept original #e8e8e8 with the 0.8s cubic-bezier(1,-0.4,0,1.4) overshoot.
- **result**: Verified in browser: ball slides -72px→0 on selection with correct transition params, mid-flight transform observed (-75.34px at 120ms), item list filters (حلويات → 3 items). Screenshot saved. Nothing applied to the app.
- **files**: docs/mocks/category-switcher-mock.html (untracked/temp), docs/screenshots/2026-09-10-mock-category-switcher.png
- **errors**: none
- **tags**: mock, uiverse, category-switcher, radio, glassmorphism, design-only

## EVT-20260910-0006

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY / FIX
- **action**: Replace splash loader with uiverse slippery-robin-92 (wink loader)
- **summary**: User rejected the massive-falcon-52 adaptation as distorted vs source and asked for a different loader: `https://uiverse.io/MetaBlue2000/slippery-robin-92`. Extracted CSS + HTML from the uiverse page: `.loader` 112x112, three `box1/box2/box3` siblings with 16px borders forming a QR-like frame (box1 112x48 bottom bar `margin-top:64px`, box2 48x48 top-left, box3 48x48 top-right blinking via `@keyframes wink` 1.8s infinite: height 48→10 with `rotate:-25deg/-45deg` then back). Flat sibling structure this time (no nesting trap). Adaptation kept geometry + keyframes verbatim; changed border color `#f5f5f5` → `var(--text)` for theme ink; added `position:relative` to `.loader` so the absolute boxes anchor to it (the uiverse preview supplies that implicitly). Removed all `.splash`/`.Strich1/2`/`.bubble*`/`dropAndShift` CSS+markup (incl. the extra `.bubble4` added earlier). `#loading`/`#loading-text` contract preserved.
- **result**: Verified localhost fresh (SW cleared): loader 112x112 centered, boxes at exact source rects (box1 112x48@(0,64), box2 48x48@(0,0), box3 48x48@(64,0), 16px border), `wink 1.8s infinite` running, mid-blink pause captured (box3 57x49 rotated), dark cream rgb(245,239,230) / light cocoa rgb(41,29,18) ink, loading auto-hides, menu renders, `node --check` OK. Screenshots dark/light/mobile (375). Committed b6ab4dd (`fix: replace splash loader with uiverse slippery-robin-92 wink loader (faithful geometry, theme-aware ink)`) + pushed; live fresh page verified: `.loader` with box1/box2/box3, `wink` animation, splash markup gone.
- **files**: index.html, docs/screenshots/2026-09-10-splash-slippery-robin-dark.png, docs/screenshots/2026-09-10-splash-slippery-robin-light.png, docs/screenshots/2026-09-10-splash-slippery-robin-mobile-ar.png
- **errors**: First live check served stale SW index.html (hasLoader:false, old splash present) — fixed by unregister+clear caches+hard reload. First light-theme assertion used classList `.dark/.light` but themes are `:root[data-theme="dark|light"]` — flipped the attribute (border then read rgb(41,29,18)).
- **lessons**: LSSN-20260910-004 (absolute-positioned uiverse children need an explicit positioned wrapper) + LSSN-20260910-005 (theme is chosen via `data-theme` attr; don't flip classes)
- **tags**: uiverse, splash, loader, deploy, theme, data-theme

## EVT-20260910-0007

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY / FIX
- **action**: Fix RTL overlap of the slippery-robin-92 loader (box2 + box3 stacked)
- **summary**: User reported the new wink loader was still broken: "three parts, two squares at top and a triangle at bottom; one square animated; the two squares overlap." Root cause: the loader is embedded in an RTL document (Arabic-first app) and its source CSS positions boxes via `margin-left` + hypothetical static position (no `left/top`). Under `dir=rtl`, the static position of abs-pos blocks is computed from right-aligned flow: box2 (margin-left:0) and box3 (margin-left:64) BOTH resolved to the same right-hand slot (x254-302 on 190-based loader) → perfectly stacked (live measurement: box2 x254-302 == box3 x254-302). The uiverse preview works only because it's LTR. Fix: replaced margin-based placement with direction-immune explicit `left/top` (box1 left:0/top:64, box2 left:0/top:0, box3 left:64/top:0) and set `direction:ltr` on `.loader`; `@keyframes wink` kept byte-identical (its margin-top still shifts the blink downward as in source because abs top:0 + margin-top add).
- **result**: Verified localhost #ar (rtl): box2 x190-238, box3 x254-302, overlap false; 20-frame sampling over a full 1.8s cycle: box3 never intersects box2 (min gap 6px at ~400ms). #en (ltr): same slots, overlap false. `node --check` OK. Committed ff2b2ad (`fix: anchor loader boxes with explicit left/top so RTL static-position math cannot stack box2+box3`) + pushed; live fresh AR page verified: box1 190-302, box2 190-238, box3 254-302, overlap false, wink running.
- **files**: index.html, docs/screenshots/2026-09-10-splash-slippery-robin-fixed-en.png, docs/screenshots/2026-09-10-splash-slippery-robin-live-fixed-ar.png
- **errors**: none (root cause confirmed by measuring live rects: box2 == box3 rects before fix)
- **lessons**: LSSN-20260910-006 (abs-pos margin/static-position layout is RTL-sensitive — uiverse components assume LTR)
- **tags**: uiverse, splash, loader, rtl, direction, deploy, bug

## EVT-20260910-0008

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY
- **action**: Extend wink loader cycle 1.8s -> 2.4s
- **summary**: User asked to "extend animation duration a bit" after the RTL fix. Changed `.loader .box3` `animation:infinite 1.8s wink` → `animation:infinite 2.4s wink`. No other changes; geometry/RTL anchoring untouched.
- **result**: Localhost disk check confirmed rule 2.4s; live deploy computed `2.4s/wink` (fresh SW-cleared page). Commit b952a0a pushed (`tweak: extend wink loader cycle 1.8s -> 2.4s`).
- **files**: index.html
- **errors**: none (note: a previously-open localhost tab still showed 1.8s due to its own SW cache — cleared SW + reload resolved; disk had the new value)
- **lessons**: none new
- **tags**: uiverse, splash, loader, duration, deploy

## EVT-20260910-0010

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY
- **action**: Double wink loader cycle 3.2s -> 6.4s
- **summary**: User: "double up the duration it is so short". `.loader .box3` `animation:infinite 3.2s wink` → `6.4s wink`. Progression: 1.8 → 2.4 → 3.2 → 6.4s.
- **result**: Live verified computed `6.4s/wink`, box2/box3 still not overlapping. Commit ce41068 pushed (`tweak: double wink loader cycle 3.2s -> 6.4s`).
- **files**: index.html
- **errors**: none
- **lessons**: none new
- **tags**: uiverse, splash, loader, duration, deploy

## EVT-20260910-0009

- **timestamp**: 2026-09-10
- **mode**: BUILD / UI / DEPLOY
- **action**: Extend wink loader cycle 2.4s -> 3.2s
- **summary**: User: "more duration". `.loader .box3` `animation:infinite 2.4s wink` → `3.2s wink`. Progression now 1.8 → 2.4 → 3.2s (~+33% each step).
- **result**: Live verified computed `3.2s/wink`, box2/box3 still not overlapping. Commit a13e4c3 pushed (`tweak: extend wink loader cycle 2.4s -> 3.2s`).
- **files**: index.html
- **errors**: none
- **lessons**: none new
- **tags**: uiverse, splash, loader, duration, deploy

