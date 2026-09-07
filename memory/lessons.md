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
