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