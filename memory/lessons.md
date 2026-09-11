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

## LSSN-20260907-019 — Pin a card CTA to the same position via flex column + margin-top:auto
- **Problem**: The "أضف +" chip on offer cards sat at different heights because card content varied (some cards had descriptions, badge text lengths differed).
- **Root cause**: `.deal-card` was a block; the chip followed content height, so its y position depended on how much content was above it.
- **Fix**: Make `.deal-card{display:flex;flex-direction:column}`; change the CTA to `margin-top:auto;align-self:flex-start`. All cards in the horizontal flex row stretch to equal height (default `align-items:stretch`), so every CTA pins to the bottom at the exact same y.
- **Lesson**: For "same CTA position across variable-content cards", the flex-column + `margin-top:auto` combo is the standard fix — no JS measuring. Normalize inner `p` margins so spacing is consistent whether descriptions exist or not.

## LSSN-20260907-020 — Steppers are not removal affordances; add a per-line ✕
- **Problem**: In the order review, removing an item required tapping − until quantity reached 0 — tedious and non-obvious.
- **Root cause**: The order sheet reused the menu's stepper control and had no explicit remove action.
- **Fix**: `removeItem(id)` deletes the cart entry and runs the standard refresh trio (`renderItems(); renderOrderSheet(); updateCartBar()`); each `.order-line` gets a `.ol-remove` ✕ button (visible on both row backgrounds via `--card2` + border). Reuses the same styling as the offer-line ✕.
- **Lesson**: Any editable quantity control in a review/summary should be accompanied by a one-tap removal; keep every cart mutator calling the same refresh trio so badge, sheet, and menu stay in sync.

## LSSN-20260907-021 — `margin-top:auto` CTA alignment can create 0-gap collisions; pair it with a minimum gap
- **Problem**: User reported the order-add button overlapping the summary text above it on offer cards.
- **Root cause**: Cards in a flex row stretch to equal height; `margin-top:auto` on the CTA pins it to the bottom. On the tallest card (the one with a description) free space = 0, so the button sat flush against the badge text (measured gap 0px). Under the previous non-flex layout this couldn't happen; the alignment fix introduced it.
- **Fix**: Give the element above the CTA a bottom margin: `.deal-badge{margin:8px 0 14px}`. `margin-top:auto` still pins every button to the bottom (same y across cards); the margin guarantees a minimum 14px gap even on the tallest card. Stress-tested at 375px with a deliberately long 3-line Arabic description: gap stayed 14px, no overlap/clip.
- **Lesson**: When using `margin-top:auto` to align CTAs across equal-height cards, always pair it with a bottom margin on the preceding element — auto margins can be 0. Test with the LONGEST plausible text (multi-line descriptions), not just current data.

## LSSN-20260907-022 — WhatsApp `wa.me` → `api.whatsapp.com` redirect drops non-BMP (emoji) chars
- **Problem**: The order text sent to WhatsApp showed `�` where 🎁 should be, while the same string rendered fine in the DOM.
- **Root cause**: Not our encoding — `encodeURIComponent('🎁')` correctly produces `%F0%9F%8E%81`. WhatsApp's server-side redirect from `wa.me/?text=` to `api.whatsapp.com/send/?text=` re-encodes the URL and replaces supplementary-plane (surrogate-pair, >U+FFFF) characters like U+1F381 with U+FFFD. BMP chars (`•` U+2022, `—` U+2014, `−` U+2212, `★` U+2605, Arabic/Cyrillic) survive; empirically confirmed: `★ Offer test` survives, `🎁` becomes `�`.
- **Fix**: In the WhatsApp message use only BMP-safe markers (`★` instead of `🎁`) and strip ALL surrogate pairs before encoding: `lines.join('\n').replace(/[\uD800-\uDFFF]/g, '')`. The UI (sheet/cards) can keep emoji — only the wa.me text must be sanitized. Non-BMP emoji inside user-entered titles (e.g. "ميغا 🚀") are stripped the same way.
- **Lesson**: Before shipping any "share to WhatsApp" deep link, test with an emoji-bearing string end-to-end; preemptively strip non-BMP characters or use BMP-safe glyphs in the message text. Verify lat/long platforms' redirects, not just your own encoding.

## LSSN-20260907-023 — Pricing engine pattern for menu offers
- **Problem**: Offers added to an order had 0 value; the order total ignored them.
- **Approach**: One `computeOrder()` snapshot (items, offers with savings, subtotal, discountLines, discount, total) reused by FAB, order sheet and WhatsApp so all three can never disagree. Deal math is pure and per-deal: percent/fixed use a scope subtotal (item/category/all); BOGO needs `item_id` present with `qty ≥ buy+get` (groups = floor(qty/(buy+get)) × get × unit price); bundle needs ALL bundle item ids in cart (≥1 each) and saves `Σ unit prices − bundle_price`; min_order triggers past `min_total` with % or fixed reward. Fixed/bundle/min-fixed discounts only apply in the deal's own currency (percent applies anywhere). Stacking is additive and capped: `discount = min(Σ savings, subtotal)`; `total = max(subtotal − discount, 0)` — explainable, never negative.
- **Lesson**: Compute one order snapshot once and derive every UI/outbound representation from it; scope-based discounts need the cart's items+quantities, not just an offer line; always cap total discount at subtotal to avoid negative orders when offers stack.

## LSSN-20260908-024 — A programmatic `fill` with an empty string may not fire `input`/`change`
- **Problem**: During Orders-tab testing, "clearing" the search box via the chrome-devtools `fill` tool left the view stale ("Showing 0 of 1" + no-match state) even though the input looked empty.
- **Root cause**: Not an app bug — the automation tool sets the field value programmatically and, for an empty-string fill, did not dispatch the `input` event the inline `oninput` handler listens on (non-empty fills had fired it). Real users typing/clearing with keys always fire the event.
- **Fix**: For tool-driven clears, dispatch manually: `el.value=''; el.dispatchEvent(new Event('input',{bubbles:true}))` (and `change` for selects) before asserting the re-render.
- **Lesson**: When automating browser verification, treat `fill`/value-setting as "set value, maybe no event" — if the test needs the app's handler, dispatch the event explicitly, or drive the field with real key presses. Don't turn a tooling quirk into a code change.

## LSSN-20260908-025 — jsonb order snapshots hold localized text; admin views must pick a language per field
- **Problem**: The Orders tab initially showed the offers column in Arabic even when the admin was in EN mode — because `orders.offers[]` stores `summary` as snapshot text *localized to the customer's session language* at order time (the AR customer saw "اشترِ 2 واحصل على 1 مجاناً").
- **Root cause**: Snapshot payloads intentionally freeze what the customer saw (title/summary/price per language) — but the admin's language is independent, so a fixed `summary || title` readout produces a mixed-language row.
- **Fix**: Render order-line text by the ADMIN's current lang, preferring the field that matches: AR → `summary || title_ar || title` (rich localized summary), EN → `title || summary` (English label; drop to the snapshot summary only if title is missing). Same principle for items (`name_ar`/`name`).
- **Lesson**: Whenever you persist per-language display text in jsonb payloads, every consumer must branch on its OWN current language and know which stored field is canonical for that language — never render a fixed field hoping it matches the viewer.

## LSSN-20260908-026 — Dynamic SEO/schema meta must be re-emitted on every render(), not just on init
- **Problem**: For AR/EN (and theme/currency) toggling to keep the meta tags, canonical + JSON-LD in sync, the SEO builder can't be a one-shot at load.
- **Fix**: Add `renderSEO()` as a normal member of the central `render()` pipeline (after `renderHeader()`, before the sections it depends on like `renderItems()`). It reads the already-loaded `shop`, `categories`, `items` globals and re-writes `document.title`, `meta[name=description]`, og/twitter tags, `link[rel=canonical]`, `meta[name=theme-color]`, and the `application/ld+json` `Restaurant` schema using the *current* `lang` (so MenuSection/MenuItem names + desc + Offer currency localize on the fly). Static placeholder tags live in `<head>`; `renderSEO()` only mutates `content`/`href`/`textContent` so duplicate-meta risk is nil.
- **Lesson**: Treat share/SEO meta as derived UI fed by the same render pass as the visible content; localize the JSON-LD the same way you localize the body, and rebuild it whenever language (or data) changes — not just at bootstrap.

## LSSN-20260908-027 — Management API: ship SQL as a Write-tool JSON file + curl --data-binary; never rebuild JSON in PowerShell
- **Problem**: Sending multi-line SQL to `POST /projects/{ref}/database/query` failed twice: `Invoke-RestMethod` with a payload built from a `.sql` file returned "expected string, received object", and `curl.exe --data-binary` with an inline payload failed "not valid JSON" because the string started with a UTF-8 BOM.
- **Root cause**: PowerShell `ConvertTo-Json` on a multiline value and quote escaping mangles the body; the Management API expects a single JSON object `{"query": "..."}`, and any BOM before `{` breaks parsing.
- **Fix**: Use the Write tool to create a clean no-BOM UTF-8 JSON payload file (one-line `{"query":"..."}`; escape inner double quotes, newlines as literal `\n`), then `curl.exe -s -X POST ... -H "Authorization: Bearer $pat" -H "Content-Type: application/json" --data-binary "@file"`. Verify responses the same way (`curl -o file` then Read).
- **Lesson**: For Supabase Management API SQL with Arabic/multiline content, the payload must originate from a file written by the Write tool and be sent with `curl.exe --data-binary @file`; reading the response back through `-o` + Read avoids PowerShell's Latin-1 mangling of UTF-8. (Also: `alter table ... add column if not exists` is idempotent and safe to run via this API.)

## LSSN-20260908-018 — Never inline Arabic in a PowerShell command when building SQL payloads (even for temp files)
- **Problem**: Restoring an Arabic `legal_note_ar` via `$q = '{"query":"update shops set legal_note_ar = ''...Arabic...'' ..."}'` then `Set-Content` wrote mojibake to the DB (stored `O�U.USO1...` garbage), corrupting a previously-good value.
- **Root cause**: The Arabic literal passed through the PowerShell 5.1 command line + `Set-Content -Encoding UTF8` lost encoding fidelity BEFORE curl; the payload bytes were already wrong.
- **Fix**: Deleted the corrupted attempt and re-ran the same UPDATE with a payload JSON file created by the **Write tool** (clean UTF-8) → value restored byte-perfect.
- **Lesson**: The "never Set-Content payloads for repo files" rule extends to ANY Arabic-containing payload — even throwaway temp files. If the payload contains Arabic (or any UTF-8 beyond ASCII), it must be authored with the Write tool and sent with `curl.exe --data-binary @file`; PowerShell 5.1 Polish/Latin-1 console + `.NET` string handling corrupts Arabic at the command-line stage. Verified by fetch → Read shows correct text.

## LSSN-20260910-001 — uiverse component adaptation: CSS selectors must match the FINAL DOM you ship
- **Problem**: Integrating uiverse plastic-moth-91 (animated heart) as the favorite icon initially didn't animate; clicking the badge toggled the favorite (state logic worked) but the SVG filled/celebrate animations never ran.
- **Root cause**: The uiverse markup wraps everything in `<label class="heart-container">`, but the adaptation placed the checkbox + `.svg-container` directly inside the app's existing `.fav-heart` label and dropped the `.heart-container` wrapper div. All selectors were scoped `.heart-container ...`, so none matched the live DOM (`.svg-filled` computed as UA-default `inline` instead of `none`/`block`).
- **Fix**: Re-scoped every rule to `.fav-heart .checkbox`, `.fav-heart .svg-container`, etc. (plus `.pd-fav` for the product sheet) directly on the labels actually rendered.
- **Lesson**: When adapting a uiverse/third-party component, first write the exact final markup your app will render, then rewrite the component's CSS selectors against THAT structure. Verify in-browser via getComputedStyle on a state transition (checked → filled display/anim) — a component can be fully wired functionally yet visually dead if its CSS hooks don't exist.

## LSSN-20260910-002 — Same-document hash navigation does not re-run app init; testing a locale needs a real reload
- **Problem**: Navigating from `index.html#en` to `index.html#ar` (same URL, different hash) in Chrome is same-document navigation — the QR-Menu init IIFE does not re-run, so `lang` stays `en` even though the URL shows `#ar`; the page appeared to "ignore" the hash.
- **Fix/verification**: after changing the hash, force a real document load (chrome navigate `type=reload`, or append a query param) so the init block re-reads `location.hash` on a fresh boot.
- **Lesson**: Never conclude a hash-based locale switch "doesn't work" on the first attempt; confirm the document actually reloaded (check the `lang` global, not just the URL). For automated AR/EN testing, drive a hard reload with the target hash.

## LSSN-20260910-003 — Splash loader shapes on dark themes need theme ink, not the uiverse default
- **Problem**: massive-falcon-52's pills are hardcoded `#000`; on the app's near-black dark theme they'd be invisible.
- **Fix**: `.splash .Strich1/.Strich2` use `var(--text)` (cream on dark, cocoa on light), keeping the original colorful bubble gradients untouched (they pop on both themes).
- **Lesson**: Before porting a light-theme uiverse component into a dark-first app, audit every hardcoded luminance (pill/ball/text colors) against both theme blocks; brightly-colored accents usually survive, base shapes often need a theme var.

## LSSN-20260910-004 — uiverse components with `position:absolute` children assume the site's preview wrapper supplies the positioning context
- **Problem**: slippery-robin-92 loads its three bordered "QR" boxes with `position:absolute` but its own CSS never sets a positioned ancestor — on uiverse it works because the preview container provides one implicitly. Dropped straight into the app, the boxes would anchor to the nearest positioned ancestor (or the viewport).
- **Fix**: Add `position:relative` to the embedding wrapper (`.loader{position:relative;width:112px;height:112px}`) so `box1/box2/box3`'s `margin-top/margin-left` offsets land exactly as in the source.
- **Lesson**: Ported uiverse markup with absolute children needs an explicit positioned wrapper in the target app; verify rects in-browser (box1 112x48@(0,64), box2/box3 48x48@(0,0)/(64,0)) rather than assuming the CSS "just works".

## LSSN-20260910-005 — This app's theme selector is `:root[data-theme="dark|light"]`, not a body/class
- **Problem**: Testing the loader in light mode: toggled `classList` `.dark`/`.light` on `<html>` and read `getComputedStyle` — the border stayed cream, suggesting the theme var didn't change.
- **Fix**: `document.documentElement.dataset.theme = 'light'`; then computed border = rgb(41,29,18) cocoa, bg rgb(250,245,238) cream.
- **Lesson**: Check the real CSS selector before flipping themes in tests (`Select-String -- "--bg:"` shows `:root[data-theme=...]`). getComputedStyle after 200ms reflects the flip; a `.light` class on `<html>` does nothing here.

## LSSN-20260910-006 — uiverse components position absolute boxes via margin + static position, which BREAKS under `dir=rtl`
- **Problem**: After re-anchoring the wink loader with a positioned wrapper, the two top squares still overlapped perfectly on the app (Arabic-first, RTL): user reported "two squares at top… one animated, and both are overlapped". Live measurement confirmed box2 and box3 had IDENTICAL rects (both x254-302).
- **Root cause**: The component's CSS uses `margin-left` + hypothetical static position (no `left/top`) to place `box2` (margin-left:0) at top-left and `box3` (margin-left:64) at top-right. In an RTL document the static position of abs-pos blocks follows right-aligned flow: both boxes resolved to the SAME slot → stacked. The uiverse preview works only because it renders LTR.
- **Fix**: Replace margin-based placement with explicit physical `left/top` (box1 left:0/top:64px, box2 left:0/top:0, box3 left:64px/top:0) and set `direction:ltr` on the wrapper. `@keyframes wink` unchanged — its `margin-top` still shifts the box down because `top:0 + margin-top` add for abs-pos boxes.
- **Lesson**: When embedding any component whose layout was authored for LTR (positioning via margins/static position, `left`-implied shorthand, `float`, flex `margin-inline` assumptions), verify it in BOTH page directions — or preempt by rewriting coordinates as explicit `left/top`. Measure rects of every piece, not just the animated one; identical rects are the classic symptom of RTL stacking.

## LSSN-20260910-007 - CSS `animation` shorthand resets `animation-fill-mode` — multiple keyframed animations need explicit `forwards`
- **Problem**: After wiring two burst animations onto `.svg-celebrate`, the favorite-heart "pulse rays" stayed visible on screen after the burst instead of disappearing like the original uiverse plastic-moth-91 source.
- **Root cause**: The rule was written as the `animation` shorthand (`animation:keyframes-svg-celebrate .55s,keyframes-celebrate-glow .55s`). The shorthand resets every `animation-*` longhand it doesn't mention, so `animation-fill-mode` reverted to `none`; when the animation ended, the element fell back to its base style (visible). The original source used `animation-fill-mode:forwards` + a `display:none` end keyframe.
- **Fix**: `.fav-heart .checkbox:checked~.svg-container .svg-celebrate{animation:keyframes-svg-celebrate .55s forwards,keyframes-celebrate-glow .55s forwards}`. Verified: rays visible at 140ms (opacity .9, 38px), gone at 900ms (display:none, opacity:0).
- **Lesson**: Any time you list keyframe animations in the `animation` shorthand, re-declare `forwards` if the final keyframe state must persist (display:none / opacity:0). Prefer longhands (`animation-name/animation-duration/animation-fill-mode`) when layering styles from different sources to avoid surprise resets.

## LSSN-20260911-008 - Empty-filter results must still expose the pagination control
- **Problem**: Applying a rating filter that matched nothing in the first loaded page hid the Load More button, so deeper matching reviews were unreachable; count said "Showing 0 of 200+".
- **Fix**: renderReviewRows renders the Load More button whenever `reviewHasMore` (and data exists), independent of the filtered list length; the empty row stays as the table message but does not remove the pager.
- **Lesson**: In paginated list UIs, treat "filter matched nothing (yet)" and "no data at all" as different states: the former keeps the pager visible so users can load deeper pages.

## LSSN-20260911-009 - Concurrent list loads duplicate rows unless guarded by a request token
- **Problem**: Firing loadReviews(true) twice in a row (double-click Refresh) started two fetches with the same range; both appended `from=0` results -> duplicate rows (reproduced length 2, unique 1).
- **Fix**: `reviewFetchToken = ++reviewFetchToken` at call entry; after the await, `if (token !== reviewFetchToken) return;` drops stale responses. Fetch REVIEW_PAGE+1 rows so `reviewHasMore = (fetched > REVIEW_PAGE)` is exact, eliminating the extra phantom fetch on exact-multiple totals.
- **Lesson**: Any async loader that concatenates into a shared array needs an in-flight token (or AbortController) — double-clicks and rapid tab re-renders are the normal trigger, not an exotic case.

## LSSN-20260911-010 - RLS policy boolean logic needs explicit parentheses; table CHECKs are only a second fence
- **Problem**: surveys_insert was `(rating 1..5 and comment is null or comment='''' or length(comment)<=500)` — due to AND/OR precedence, any short non-empty comment made the whole check TRUE regardless of rating; only the table CHECK (surveys_rating_check) blocked rating=99.
- **Fix**: Re-applied as `(rating between 1 and 5) and (comment is null or comment = '''' or length(comment) <= 500)`. Verified via anon REST insert: bad rating now errors 42501 (policy layer) instead of 23514 (check layer).
- **Lesson**: When authoring RLS WITH CHECK expressions, group every disjunct with parentheses and verify each branch independently (anon-key probe); never rely on a table CHECK to silently backstop a policy bug.

## LSSN-20260911-011 - Verify write-path Db fixes in code, not by mutating production data
- **Problem**: Whole-app audit produced fixes in saveItem/deleteBadge/saveDeal paths that write to the live DB; running them as probe tests would create or destroy real rows in the owner's shop.
- **Fix**: Exercise only the guard/render/read branches in the browser (double-submit noops, last-currency block, empty-filter pager, XSS string output, memoization sentinel, clipboard). For write-path mutations (price cleanup, badge cleanup, currency select, percent clamp), verify the exact code path by reading the function they live in.
- **Lesson**: In a live single-shop app, prefer "test the guard, read the mutation" over "probe the mutation then restore" — a failed restore can silently corrupt shop data, and the guard tests are the parts most likely to regress anyway.

## LSSN-20260911-012 - An async function wrapping a memoized promise breaks identity checks
- **Problem**: showDashboard() returns `dashboardPromise` inside `async function` — an async fn always wraps its return in a NEW promise, so `p1 === p2` is false even when the memoization works. The false negative looked like the guard was broken.
- **Fix**: Test memoization by replacing the stored promise with a sentinel and asserting the function does NOT reassign it (`dashboardPromise === sentinel` still true after the call returns).
- **Lesson**: When testing promise-memoization, never compare promise identities returned from an async function; check that the memo slot did not get a new promise instead.

## LSSN-20260911-013 - Additive discounts can exceed subtotal; cap the LINES, not just the total
- **Problem**: With several offers, raw savings sum could exceed the subtotal; the total was capped but the line items still showed the uncapped savings, so the WhatsApp receipt and admin order view could disagree with the total (-120 in offers vs -100 discount).
- **Fix**: computeOrder caps discount to subtotal and scales each discount line proportionally (with a remainder on the last line) so `sum(discountLines) === discount` always; the receipt renders the capped lines.
- **Lesson**: Every derived-money list must be consistent with its own total — cap the components when you cap the aggregate, or shared consumers (receipt, order record, admin view) will render contradictions.

## LSSN-20260911-014 - Cart state must reset when the order leaves; guards prevent duplicate sends
- **Problem**: After sendWhatsApp the cart stayed populated; a later press would build the SAME order again (duplicate orders). A double-click on Send could also fire two inserts while the first was still in flight.
- **Fix**: waSending flag guards re-entry during the async insert/open; after window.open the whole cart (items, offers, notes, variants) is cleared and the UI re-rendered; survey prompt follows 900ms later.
- **Lesson**: Order-flows are state machines: an in-flight guard (double-submit) AND a terminal state transition (cart reset) are both required to make send-once semantics real.

## LSSN-20260911-015 - A WhatsApp fallback must never be silent; the shop has to know an order was not saved
- **Problem**: sendWhatsApp caught every insert error and continued to a client-only T<epoch> order number. The customer got WhatsApp + a green "WhatsApp opened" toast, but no row reached the orders table — so the dashboard stayed empty while the shop kept receiving WhatsApp texts. ~15 consumed-but-empty bigserial ids showed this had happened repeatedly.
- **Fix**: Retry the insert once (a duplicate saved row is visible and fixable; a silent loss is not); if it still fails, log a warning, show an error-styled toast, and append "⚠️ لم يُحفظ الطلب في لوحة التحكم" to the actual WhatsApp text so the fallback is self-documenting. Also gate dealAfterValue('bogo') on cart eligibility so the sheet can't show a price for an offer that isn't applying.
- **Lesson**: Any fallback path that changes the outcome for the user must surface the change of state to the humans involved — silent degradation is indistinguishable from data loss. Money/order flows especially: if the primary write failed, say so out loud (customer + shop), or "orders are not appearing in the dashboard" becomes the standing bug report.

## LSSN-20260911-016 - Persisted UI state must be validated on restore; switch-without-default is a blank-panel trap
- **Problem**: On refresh the admin always reset to the first tab; fixing it with localStorage was easy, but restoring an unvalidated value into showTab() (whose switch has no default case) would render an empty main-content panel forever if the value was ever corrupt/legacy/edited.
- **Fix**: showTab() persists the tab on every switch; on dashboard load restore only if the value is in a hard-coded allow-list of the 9 known tabs, else fall back to 'orders'.
- **Lesson**: Whenever you persist UI state that feeds a dispatcher, validate against the known domain on restore — never trust localStorage, and give the dispatcher a default branch so a bad value degrades gracefully instead of blanking the UI.

