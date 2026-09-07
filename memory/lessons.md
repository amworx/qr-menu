# Lessons — qr-menu

## LSSN-20260907-001 — Management API + PAT runs SQL even when DB host is IPv6-only
- **Problem**: `db.<ref>.supabase.co` for some Supabase projects resolves ONLY to an AAAA (IPv6) record. On networks without IPv6 routing, `pg` / psql / direct DB connections fail with ENOTFOUND.
- **Root cause**: No IPv6 connectivity on this network (only link-local address, no global route); DB host has no A record.
- **Fix**: Use the Supabase Management API SQL endpoint with a Personal Access Token:
  `POST https://api.supabase.com/v1/projects/{ref}/database/query` with `Authorization: Bearer <sbp_...>` and body `{"query": "<sql>"}`. Works over IPv4.
- **Lesson**: For Supabase SQL migrations from restricted networks, use the Management API + PAT (full-access token) instead of trying to connect to the DB directly. Service-role key does NOT work for the Management API (needs supabase_admin claim).

## LSSN-20260907-002 — Use jsDelivr, not unpkg, for @supabase/supabase-js UMD
- **Problem**: `<script src="https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.min.js">` got `ERR_BLOCKED_BY_ORB` / "Response was blocked by CORB" in Chrome; `supabase is not defined`.
- **Root cause**: unpkg returns a 302 redirect for the version-less path; the redirected MIME/opaque response trips the browser's Opaque Response Blocking.
- **Fix**: Switch to `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js` — loads cleanly.
- **Lesson**: When in-browser testing with localhost, prefer versioned/pinned CDNs with correct MIME (jsDelivr) over unpkg redirects for SDK bundles.

## LSSN-20260907-003 — Mutators must refresh every consumer of shared UI state
- **Problem**: After direct-entry quantity changes, the floating cart badge/total stayed stale (e.g. typed `5` but badge showed `1`); clicking `+` inside the order sheet appeared dead (line qty didn't change).
- **Root cause**: `setCartQty()` updated `cart` and re-rendered items but never called `updateCartBar()`; `incCart()` re-rendered the grid but skipped refreshing the open order sheet (`decCart()` did have the refresh — asymmetry). `oninput="updateCartBar()"` also fired before `cart` was updated.
- **Fix**: Every cart mutator (`incCart`, `decCart`, `setCartQty`) now calls `updateCartBar()` and refreshes the order sheet when the modal is open; `updateCartBar()` resets badge+total on empty; `incCart` capped at 99 to match input `max`.
- **Lesson**: When multiple components derive from one piece of state, every writer must refresh all readers, or keep the derived values computed (single render pass). Test with real interactions: type into inputs, click buttons inside open modals — not just the primary control.

## LSSN-20260907-004 — GitHub Pages redeploy lags ~1 min after push; verify raw `main` first
- **Problem**: After `git push`, `https://amworx.github.io/qr-menu/?cb=...` still served the OLD index.html (21.9KB, no new markers) even with a cache-buster query string.
- **Root cause**: The query string defeats the browser cache, but GitHub Pages' CDN/deployment had not yet rebuilt — the push had landed on `main` (raw.githubusercontent updated instantly) while the Pages deployment was still being generated.
- **Fix**: Poll the Pages URL until the byte count / markers match `raw.githubusercontent.com/amworx/qr-menu/main/index.html` (~45–60s), then re-verify in-browser.
- **Lesson**: When "live verify" fails right after a push, first diff `raw.githubusercontent.com/.../main/<file>` against the live URL — if raw matches your commit but live doesn't, it's Pages rebuild lag, not a bad deploy.

## LSSN-20260907-005 — PowerShell console mangles Arabic; verify Supabase UTF-8 via file
- **Problem**: PATCHing `name_ar`="جودي جوي" to Supabase returned `name_ar : ???? ???` in the PowerShell console — looked like mojibake got stored.
- **Root cause**: Windows PowerShell 5.1 console can't render Arabic; the value was actually stored correctly (UTF-8). The `????` was display-only.
- **Fix**: Write the API response to a UTF-8 (no BOM) temp file (`[System.IO.File]::WriteAllText` with `UTF8Encoding($false)`) and Read it back — showed `"name_ar":"جودي جوي"` correctly.
- **Lesson**: Never trust Windows PS console output for non-Latin text. If a check involves Arabic/Arabic-script data, dump to a UTF-8 file and verify with the Read tool before assuming corruption.
## LSSN-20260907-006 � Free-tier Supabase + default email provider: no email template customization
- **Problem**: Sign-in "magic link" email contained only a link, and the link pointed to http://localhost:3000 (default site_url) � useless. User wanted an OTP code in the email.
- **Root cause**: (1) The default magic_link template shows only {{ .ConfirmationURL }} (no token); (2) site_url was the Supabase default; (3) template modification is BLOCKED on free tier with the default email provider (Management API returned: "Email template modification is not available for free tier projects using the default email provider").
- **Fix**: Made the emailed link useful instead: set site_url + uri_allow_list to the real app, pass emailRedirectTo to admin.html from signInWithOtp, and have admin.html complete the session from ?token= (verifyOtp) or ?code= (exchangeCodeForSession). OTP length aligned to 6. For actual OTP-code emails, the user would need custom SMTP (or paid plan) � then templates become editable.
- **Lesson**: Before promising "OTP email", check the auth config: on free tier + built-in email, users get a magic link only; plan the redirect URL to be a real page that processes token/code params.

## LSSN-20260907-007 — supabase-js on Edge Runtime: import via full URL, not bare specifier
- **Problem**: Deploying an edge function failed bundle with: "Relative import path @supabase/supabase-js not prefixed with / or ./ or ../".
- **Root cause**: The Supabase edge bundler does not resolve bare npm specifiers; it needs a fully-qualified URL.
- **Fix**: `import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'` instead of `'@supabase/supabase-js'`.
- **Lesson**: In Supabase Edge Functions use `https://esm.sh/@supabase/supabase-js@2` (jsDelivr/esm.sh), not the bare package name. Also deploy the function via Management API: `POST /v1/projects/{ref}/functions/deploy?slug=<name>` multipart with a `file` field + a `metadata` field (JSON string: `{"entrypoint_path":"index.ts","verify_jwt":false,"name":"..."}`). Pass the metadata JSON from a file to avoid PowerShell string-mangling quotes.

## LSSN-20260907-008 — Hosted Supabase magic-link redemption is a 303 GET returning session in Location#fragment
- **Problem**: `auth.admin.generateLink({type:'magiclink'})` returned a token, but the client `sb.auth.verifyOtp({email, token, type:'magiclink'})` POST failed with "Token has expired or is invalid" — even with the exact token.
- **Root cause**: Hosted Supabase uses a PKCE/implicit-style magic-link flow. Redemption happens via a GET/SDP 303 to `/auth/v1/verify?token=...&type=magiclink&redirect_to=...` (the same request the browser makes when the user clicks the emailed link). That 303's `Location` header points to `redirect_to#access_token=...&refresh_token=...&expires_in=...&...`. The client library's `verifyOtp({type:'magiclink'})` POST is not the working path for this flow.
- **Fix**: Do the exchange server-side in an edge function: `fetch(verifyUrl, { redirect: 'manual' })`, read `location`, strip the `#`, parse the URLSearchParams, and return `access_token`/`refresh_token`/`expires_in`. Client then calls `sb.auth.setSession({access_token, refresh_token, expires_at})` to establish a real authenticated session — which preserves RLS (`owner_email = auth.email()`).
- **Lesson**: When minting sessions programmatically for hosted Supabase, prefer exchange-through-the-verify-URL over client `verifyOtp` for the magic-link type. Verify with curl: `GET .../auth/v1/verify?token=...&type=magiclink&redirect_to=<encoded>` returns 303 with the session fragment.

## LSSN-20260907-009 — Adding Jekyll-hostile files (e.g. .ts) to a GitHub Pages site requires .nojekyll
- **Problem**: After adding `supabase/functions/admin-login-gate/index.ts`, GitHub Pages deployment errored and the old page kept being served.
- **Root cause**: The repo had no `.nojekyll`. Jekyll's build (which processes the project for Pages) choked or mishandled the TypeScript file, causing an errored build.
- **Fix**: Add an empty `.nojekyll` at repo root so Pages serves the raw static files without running Jekyll. Build succeeded in ~21s afterwards.
- **Lesson**: Any GitHub Pages repo that serves non-Jekyll-friendly artifacts (source `*.ts`, `supabase/` folders, etc.) should include `.nojekyll` to bypass Jekyll processing. Verify via `gh api repos/<owner>/<repo>/pages/builds --jq '.[0].status'`.

## LSSN-20260907-010 — An async renderer assigned to `innerHTML` shows `[object Promise]`
- **Problem**: Clicking "Deals & Offers" in the admin showed literal `[object Promise]` in the main content area (verified via a11y snapshot).
- **Root cause**: `renderDealsTab()` is `async`, so `c.innerHTML = renderDealsTab()` assigned the returned Promise, not the HTML string. The sync tabs worked because their renderers return strings.
- **Fix**: `showTab('deals')` now sets a loading placeholder then `renderDealsTab().then(html => c.innerHTML = html)`.
- **Lesson**: Any `async` render function must be awaited (`a().then(html => el.innerHTML = html)`) — never assign the async call directly to `innerHTML`. Check all tab/render functions' `async` signature when wiring `innerHTML`.

## LSSN-20260907-011 — Guard re-render-after-login on loaded data; beware double showDashboard
- **Problem**: On page load with a persisted Supabase session, the admin threw `Cannot read properties of null (reading 'name')` inside `renderShopTab` during `applyLang()`.
- **Root cause**: With a stored session, `showDashboard()` runs twice — once from the INIT IIFE (`sb.auth.getSession()`), once from `onAuthStateChange` with `SIGNED_IN`. The second call's `applyLang()` re-rendered the current tab while `currentShop` was still null (the first call had set `#dashboard` display to block synchronously but had not finished loading the shop).
- **Fix**: `applyLang()` only re-renders when `currentShop` is loaded: `if (display==='block' && currentTab && currentShop) showTab(currentTab)`.
- **Lesson**: Auth events (`onAuthStateChange` SIGNED_IN on init with stored session) can duplicate explicit init code. Re-renders triggered by language/theme toggles must check that the data they render actually exists.

## LSSN-20260907-012 — Startup `refresh_token_not_found` 400 is benign stale-token noise
- **Problem**: Live admin console showed `POST /auth/v1/token?grant_type=refresh_token` → 400 `refresh_token_not_found`.
- **Root cause**: The browser still held a refresh token from an earlier manual-test session that had been invalidated/rotated. On load, supabase-js tries to refresh it, gets 400, clears the session, and shows the auth screen.
- **Fix**: None needed — this is normal auth hygiene. Each successful login mints a fresh valid pair, so after login the app works normally.
- **Lesson**: When auditing console errors after auth changes, distinguish startup refresh failures from functional failures. If the auth screen renders and login succeeds immediately after, a single refresh_token_not_found is stale-storage noise, not a bug.

## LSSN-20260907-013 — On mobile, admin CRUD tables must become labeled stacked cards
- **Problem**: Items table rendered 502px wide inside a 390px viewport; in RTL the table's left edge ran to x=-127, clipping data — mail body scrolled horizontally and fields were unreadable/overlapping.
- **Root cause**: Fixed-width content (tables, long unbroken labels) inside a flexible column overflows the viewport; RTL direction makes the clip appear on the logical left.
- **Fix**: Wrap tables in `<div class="table-wrap">`; at ≤768px: `table/thead/tbody/tr/td{display:block}`, hide `thead`, each `td` becomes a flex row with `::before{content:attr(data-label)}` label + value (`justify-content:space-between`), actions cell labels the buttons above (`flex-direction:column`). Every `<td>` carries `data-label="${t(...)}"`.
- **Lesson**: Never let a table overflow horizontally on phones — convert to stacked cards with `data-label` attributes. Verify with `document.documentElement.scrollWidth > clientWidth` on body AND `#main-content` at the target viewport, and check the RTL-left edge of tables (measure `getBoundingClientRect().left`).

## LSSN-20260907-014 — Set sticky offset var from measured parent only after layout is settled
- **Problem**: Sticky mobile tab bar sat 24px too low — `--header-h` stayed at the 104px default while the responsive header measured 80px.
- **Root cause**: The var was computed in `applyLang()` which ran before the dashboard was visible (`display:none` → rect height 0), and the margin/gap computed against the stale value; the header also wraps to two rows on phones so its height is not a fixed constant.
- **Fix**: Compute `--header-h` from `header.getBoundingClientRect().height` in `showTab()` (runs after layout is stable) guarded by `height > 0`; use `top:var(--header-h,104px)` in the sticky rule.
- **Lesson**: When a sticky element must sit flush below a variable-height header, measure the header after layout is settled (not at script parse / hidden state) and inject the value as a CSS var; always guard rect height > 0.

## LSSN-20260907-015 — Reload the browser after editing an admin page before testing JS
- **Problem**: First BOGO deal created via the UI stored `item_id: null` and the item picker was missing from the modal, even though the code looked correct.
- **Root cause**: The test ran against an already-loaded browser page that still executed the pre-edit script — the fix was committed to the file but not reloaded into the tab.
- **Fix**: Reload `http://localhost:8088/admin.html`, re-open the deal in edit mode, set the item via the new picker, save — item_id persisted correctly.
- **Lesson**: `localhost` static servers serve the file fresh per navigation, but an already-open tab keeps the old script. Always reload before verifying any JS/HTML edit; stale pages produce false failures (and can write wrong test data to the real DB).

## LSSN-20260907-016 — Dynamic show/hide field blocks: keep all blocks in DOM and toggle by a type map
- **Problem**: In the redesigned deal modal the "applies to" scope block never appeared, no matter the selected offer type.
- **Root cause**: `dealTypeChanged()` used a per-type map (`percent: ['percent']`) that omitted `scope`; the loop hid any block not listed, so scope was hidden for every type.
- **Fix**: Map now includes the block: `percent: ['percent','scope'], fixed: ['fixed','scope'], bogo: ['bogo'], ...`.
- **Lesson**: For type-dependent form blocks, render every block always and toggle `display` via a single map; every block id must be present in the map for the types that need it. Keeping all blocks in the DOM also preserves field values when the user switches type mid-edit.

## LSSN-20260907-017 — Cart is two independent structures: items and offers
- **Problem**: After adding clickable offers, the cart badge/sheet/WhatsApp ignored them — they only read `Object.entries(cart)`.
- **Root cause**: The cart was designed as a single `{ itemId: qty }` map; offers are a different entity (dealId → presence) with no per-unit price.
- **Fix**: Keep `cart = { itemId: qty }` for priced items and `cartOffers = { dealId: 1 }` for offers. Every consumer must read both: `updateCartBar()` badge = item count + offer count (total stays item-only), `renderOrderSheet()` renders offer lines (🎁 title + localized summary + remove ✕), `sendWhatsApp()` appends `🎁 title — summary` rows, and all empty-guards check `totalItems===0 && offerCount===0`.
- **Lesson**: When adding a second entity type to a shopping flow, enumerate every consumer of the cart state (badge, sheet, message builder, empty states) and update each; introduce a combined "line count" helper so nothing reads only one structure.

## LSSN-20260907-018 — View-mode toggles are pure CSS-class swaps, not duplicate renderers
- **Problem**: Needed a list/grid toggle on the public menu without rewriting the item renderer twice.
- **Root cause**: (n/a — design choice) The natural approach would have been two rendering functions or two markups.
- **Fix**: One renderer; `viewMode` (from `localStorage 'qm-view'`, default grid) toggles one class on the container. Grid CSS (`.items-col`) is global (works on mobile AND desktop): `grid-template-columns:1fr 1fr`, `.item-card{flex-direction:column}`, image `width:100%;aspect-ratio:4/3`, full-width add/stepper. List = the original block/ticket layout. Button icon shows the *target* mode (`☰` in grid mode → switches to list; `▦` in list mode → switches to grid) with `aria-pressed` reflecting current mode.
- **Lesson**: For layout switches, mutate one container class and let CSS express both layouts; persist the choice; make toggle buttons show what you'll switch TO, with `aria-pressed` = current state. Verify at mobile width that the grid computes `1fr 1fr` columns without body overflow (body.scrollWidth == innerWidth).

(End of file - total 101 lines)

(End of file - total 77 lines)

(End of file - total 75 lines)
