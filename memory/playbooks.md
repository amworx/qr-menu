# Playbooks — qr-menu

Reusable step-by-step workflows. Append only. Reuse existing playbooks before creating new ones.

## PB-20260907-001 — Deploy + verify a frontend change on GitHub Pages with Supabase
1. Make changes; test locally via `C:\Users\HP\AppData\Local\Temp\opencode\server.js` on `http://localhost:8088`.
2. Commit + push to `main`.
3. Check Pages build status: `gh api repos/amworx/qr-menu/pages/builds --jq '.[0] | {status,commit: .commit[0:7],error: .error.message}'`; wait until `status == "built"` (usually ~20–60s; needs `.nojekyll` at root now that `.ts` files exist).
4. Verify raw content matches commit: `curl https://raw.githubusercontent.com/amworx/qr-menu/main/<file>` and grep for new markers.
5. Verify live with a cache-buster: `curl "https://amworx.github.io/qr-menu/<file>?ts=$(Get-Date -Format yyyyMMddHHmmss)"` then in-browser end-to-end.
6. Update memory (events/lessons/patterns).

## PB-20260907-002 — Interim email-only admin login (until custom SMTP)
- Login form: Email field + Login button → POST to edge function `admin-login-gate` → `sb.auth.setSession(...)` → dashboard.
- Edge function does the server-side email check + creates/confirms the auth user + mints/exchanges a magic-link token (no email sent).
- Wrong email → 403 "This email is not the admin". Admin email → full dashboard with RLS.
- When SMTP is configured later, restore true OTP-code emails (or keep email-only). See EVT-20260907-0006.
