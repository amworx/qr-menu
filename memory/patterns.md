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
