# Patterns — qr-menu

Reusable patterns extracted from repeated successes. Append only.

## PAT-20260907-001 — Programmatic email-only auth session via Supabase Edge Function
- **When**: Need a login that requires only the admin email (no OTP/password) while keeping RLS (`owner_email = auth.email()`) intact.
- **How**:
  1. Edge function verifies typed email against `shops.owner_email` server-side (403 otherwise).
  2. `auth.admin.createUser({ email, email_confirm: true })` ensures the auth user exists/confirmed — no email is actually sent.
  3. `auth.admin.generateLink({ type: 'magiclink', email })` mints a one-time token.
  4. Exchange server-side: `fetch(supabaseUrl + '/auth/v1/verify?token=...&type=magiclink&redirect_to=...', { redirect: 'manual' })`, parse `access_token`/`refresh_token` from the 303 `Location#` fragment.
  5. Return tokens to client; client `sb.auth.setSession(...)` → real session → RLS works.
- **Ref**: functions/admin-login-gate/index.ts; EVT-20260907-0006.

## PAT-20260907-002 — Deploy an Edge Function via Management API (no CLI/Deno locally)
- **When**: Need to deploy/update a Supabase edge function from a Windows box without the Supabase CLI.
- **How**:
  `curl -X POST "https://api.supabase.com/v1/projects/{ref}/functions/deploy?slug=<name>" -H "Authorization: Bearer <PAT>" -F "file=@index.ts;type=text/plain" -F "metadata=@meta.json;type=application/json"`
  with `meta.json = {"entrypoint_path":"index.ts","verify_jwt":false,"name":"..."}`.
- **Ref**: EVT-20260907-0006; LSSN-20260907-007.

## PAT-20260907-003 — Single-file Arabic-first i18n (dictionary + t() + applyLang + data-i18n)
- **When**: A single-page app (admin panel or menu) must default to Arabic (RTL) with an EN/AR toggle.
- **How**:
  1. `let lang = localStorage.getItem('<key>') || 'ar';` (default Arabic, persisted).
  2. `const I18N = { key: { en: '...', ar: '...' } }` dictionary; `t(key)` returns entry per `lang` (fallback EN, then key).
  3. `applyLang()` sets `document.documentElement.lang/dir`, `document.title`, text of static nodes by ID or `[data-i18n]`, re-renders the active tab only when its data is loaded (`currentTab && currentShop`).
  4. `toggleAdminLang()` flips `lang`, persists, calls `applyLang()`.
  5. All dynamic render functions, modals, toasts, confirms call `t('...')`; translate known server error strings via a small map in the error handler.
- **Ref**: admin.html `I18N`/`applyLang`; index.html uses the same pattern; EVT-20260907-0007.

## PAT-20260907-004 — Mobile table → labeled stacked cards (no horizontal overflow)
- **When**: Any CRUD/admin table must remain readable at ~390px width with RTL content.
- **How**:
  1. Wrap every rendered `<table>` in `<div class="table-wrap">` (declarative tables too).
  2. Add `data-label="${t(colName)}"` to every `<td>` (RTL / Arabic-safe labels).
  3. At `@media (max-width:768px)`: `table,thead,tbody,tr,td{display:block}`, `thead{display:none}`, `td{display:flex;justify-content:space-between;gap:12px}`, `td::before{content:attr(data-label);opacity:.6;font-size:12px}`, `td:last-child{flex-direction:column;align-items:stretch}` (actions stack label above full-width buttons).
  4. Verify: `scrollWidth > clientWidth` false on `document.documentElement` and `main-content`; table `getBoundingClientRect().left` ≥ 0 in RTL; header `h2`/`.dash-header` wrap instead of squeeze.
- **Ref**: admin.html CSS + renderers; EVT-20260907-0008; LSSN-20260907-013.

## PAT-20260907-005 — Sticky element offset from a variable-height header via measured CSS var
- **When**: A sticky bar (tabs/filters) must sit flush below a header whose height changes by breakpoint or wraps.
- **How**: On `:root` declare `--header-h:70px`; in the ≤768px block override `--header-h:104px`; in JS, after each tab render, measure `header.getBoundingClientRect().height` when `> 0` and set `document.documentElement.style.setProperty('--header-h', (height+1)+'px')`; the sticky rule uses `top:var(--header-h,104px)`.
- **Ref**: admin.html `showTab()`; EVT-20260907-0008; LSSN-20260907-014.

## PAT-20260907-006 — Client-side list search/filter/sort/pagination toolbar
- **When**: An admin list (items, etc.) can grow large; users need to find rows quickly.
- **How**:
  1. Keep the full dataset in memory (`allItems`); render only into a tbody container.
  2. Toolbar: search input (`oninput`) matching EN+AR name/desc, category `<select>`, sort `<select>` (order/name/price low/high), live counter `t('showing') N t('of') M`, and a pagination cap (`itemShown`/`ITEM_PAGE=50`) with a "Load more" button that increments and re-renders.
  3. `filteredItems()` = filter → sort → return; `renderItemRows()` slices to `itemShown` and fills `#tbody`; stable inline `onchange/oninput` handlers keep it dependency-free.
  4. Call `renderItemRows()` right after `showTab` injects the tab HTML.
- **Ref**: admin.html items tab; EVT-20260907-0009.

## PAT-20260907-007 — Typed offer/deal model with one flexible admin modal
- **When**: An app needs multiple offer styles (percent, fixed amount, BOGO, bundle/combo, spend-threshold) with one DB table + one modal + localized public labels.
- **How**:
  1. DB: `deal_type` enum + `applies_to(item|category|all)` + per-type nullable columns (`item_id`, `category_id`, `buy_qty`, `get_qty`, `min_total`, `reward_type`, `bundle_price`, `bundle_items jsonb[]`); idempotent ALTER migration (safe with 0 rows).
  2. Modal: keep ALL field blocks in the DOM, toggle `display` via `dealTypeChanged()` map (`percent:['percent','scope']` etc.); every block id must be in the map for the types that need it. BOGO gets its own item picker; bundle uses checkbox chips; scope picker only for percent/fixed.
  3. `saveDeal()` builds a base object with nulls for irrelevant fields, then fills per-type values.
  4. Public menu: single `dealSummary(d)` switch returns localized AR/EN text per type.
- **Ref**: admin.html deals + index.html `dealSummary`; docs/schema.sql deals; EVT-20260907-0009; LSSN-20260907-016.

## PAT-20260907-008 — Offer cards as clickable order-line items (not a discount engine)
- **When**: Public menu shows deals; tapping an offer must add it to the customer's order as a line item.
- **How**:
  1. Separate `cartOffers = { dealId: 1 }` from priced `cart = { itemId: qty }` (offers have no unit price; total stays item-only).
  2. Deal card: `role=button`, `tabindex=0`, `onclick`/`onkeydown` → `toggleOffer(id)`; added state = `.deal-card.added` (white outline) + `✓ أُضيف إلى الطلب` chip + toast.
  3. Every consumer reads both structures: badge = item qty sum + offer count; order sheet renders 🎁 line (title + `dealSummary(d)` + remove ✕); WhatsApp appends `🎁 title — summary`; empty-guards check items AND offers.
  4. Rendering the offer's *numeric* discount on the total is a separate concern — only add that engine when discount math is explicitly requested.
- **Ref**: index.html `toggleOffer`/`removeOffer`/`renderOrderSheet`/`sendWhatsApp`; EVT-20260907-0010; LSSN-20260907-017.

## PAT-20260907-009 — CSS-class layout toggle (list vs grid) with localStorage persistence
- **When**: A responsive list needs a user-facing view switcher (grid ⇄ list) without maintaining two render paths.
- **How**:
  1. State: `viewMode = localStorage.getItem(key) || 'grid'`; one container class (`items-col`) expresses the grid layout; list = the default block layout. One renderer, two CSS states.
  2. Grid CSS global (desktop AND mobile): `grid-template-columns:1fr 1fr`, card `flex-direction:column`, media `width:100%;aspect-ratio:4/3`, full-width add/stepper. Item renderer just toggles the class + `display:grid|block`.
  3. Toggle button icon shows the TARGET mode (`☰` when grid → tap for list; `▦` when list → tap for grid); `aria-pressed` = current mode; `title` localized.
  4. Verify mobile: `body.scrollWidth === innerWidth`, computed grid columns ~ (width - padding - gap)/2.
- **Ref**: index.html `toggleView`/`renderViewBtn`/`.items-col`; EVT-20260907-0010; LSSN-20260907-018.
