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
