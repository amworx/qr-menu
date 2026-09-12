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

## DEC-20260907-003 — Admin dashboard default language Arabic with EN/AR toggle
- **Context**: Public menu already defaults to Arabic (`lang='ar'`), RTL first; admin was English-only with no language control.
- **Decision**: Admin now defaults to Arabic (`localStorage 'qm-admin-lang'`, default `'ar'`), identical to the menu. A compact EN/AR toggle pill is shown on both the auth screen and the dash header. Language choice is persisted and survives reload.
- **Impact**: Admin is consistent with the public menu UX for Arabic-speaking shop owners. English is one tap away. All dynamic UI (render functions, modals, toasts, confirms, server error messages) is translated via a single `I18N` dictionary.

## DEC-20260912-004 - Admin dashboard redesign: Tailwind Play CDN + Lucide web build
- **Context**: User asked for a complete, modern redesign ("use tailwind and get icons from lucide"). The repo deliberately has no build step — plain static HTML served from GitHub Pages.
- **Decision**: Use the Tailwind Play CDN (`cdn.tailwindcss.com`) with an inline `tailwind.config` for the utility layer, and the Lucide web build (unpkg UMD) for icons converted via `lucide.createIcons()` driven by a debounced MutationObserver. Font Awesome removed entirely. Known cost: Tailwind Play CDN logs a 'not for production' console warning — accepted for this repo since a PostCSS/CLI pipeline would add a build step against the project's design constraint.
- **Impact**: Zero-build modern styling available in utilities, crisp consistent 24px Lucide icons everywhere (auth, nav, buttons, toasts), consistent ember amber/orange accent system, animations guarded by prefers-reduced-motion. If the repo ever grows a build step, swap the Play CDN script + config for Tailwind v4 PostCSS and the tailwindcss-animate/lucide packages with near-identical markup.
