# Decisions — qr-menu

Architectural / product decisions. Append only.

## DEC-20260907-001 — Email-only interim admin login via Edge Function (OTP disabled until SMTP)
- **Context**: User asked to disable OTP login until SMTP is set up, and make login require only the admin email.
- **Considered**: (a) relax RLS to public reads — rejected (open data, insecure); (b) ship service-role key in client — rejected (admin.html is publicly served, would expose full DB); (c) Supabase Edge Function minting a session server-side — chosen (secure, no email, RLS intact).
- **Decision**: Edge function `admin-login-gate` verifies the typed email == `shops.owner_email` server-side, creates/confirms the auth user, mints + exchanges a magic-link token server-side, returns a session to the client. Client uses `setSession`.
- **Impact**: Only the admin email can log in; no email is sent; RLS (`owner_email = auth.email()`) fully preserved. True OTP-code emails remain impossible on free tier + default provider until custom SMTP or a paid plan is configured.

## DEC-20260907-002 — GitHub Pages needs .nojekyll (repo now contains .ts / supabase/)
- **Context**: Adding a TypeScript edge function file to the repo caused GitHub Pages build errors.
- **Decision**: Added empty `.nojekyll` at repo root to serve raw static files without Jekyll.
- **Impact**: Future commits deploy reliably; source artifacts (`.ts`, `supabase/`) don't break the build.
