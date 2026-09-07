// Interim admin login gate — email-only, no OTP email.
// 1. Verifies the typed email against the shop's owner_email (server-side).
// 2. Ensures the auth user exists/confirmed (createUser, no email sent).
// 3. Mints a magic-link token (generateLink) and exchanges it server-side
//    exactly like clicking the email link (GET /auth/v1/verify).
// 4. Returns a ready-to-use session (access_token + refresh_token).
// The client then calls supabase.auth.setSession(...) — RLS stays intact
// because it is a real session owned by auth.email().
// Supabase Edge Runtime auto-injects SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

// Must be in the project's URI allow-list
const REDIRECT_TO = 'https://amworx.github.io/qr-menu/admin.html'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(obj: unknown, status: number) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const body = await req.json()
    const email = (body?.email || '').toString().trim().toLowerCase()
    if (!email) return json({ error: 'Email is required' }, 400)

    // Only the shop's admin email may sign in
    const { data: shops } = await admin
      .from('shops')
      .select('owner_email')
      .eq('is_active', true)
      .limit(1)
    const owner = (shops?.[0]?.owner_email || '').toLowerCase()
    if (!owner || email !== owner) return json({ error: 'This email is not the admin' }, 403)

    // Ensure the auth user exists and is confirmed (no email is actually sent)
    const { error: createdError } = await admin.auth.admin.createUser({ email, email_confirm: true })
    if (createdError && !/already/i.test(createdError.message || '')) {
      return json({ error: createdError.message }, 500)
    }

    // Mint a one-time magic-link token
    const { data: link, error: linkError } = await admin.auth.admin.generateLink({
      type: 'magiclink',
      email,
    })
    if (linkError || !link?.properties?.hashed_token) {
      return json({ error: linkError?.message || 'Could not generate token' }, 500)
    }

    // Exchange the token server-side — same 303 response a browser gets when
    // clicking the emailed link: Location: <redirect>#access_token=...&refresh_token=...
    const verifyUrl =
      `${supabaseUrl}/auth/v1/verify?token=${link.properties.hashed_token}` +
      `&type=magiclink&redirect_to=${encodeURIComponent(REDIRECT_TO)}`

    const vr = await fetch(verifyUrl, {
      redirect: 'manual',
      headers: { apikey: serviceRoleKey },
    })
    const fragment = (vr.headers.get('location') || '').split('#')[1] || ''
    const params = new URLSearchParams(fragment)
    const access_token = params.get('access_token')
    const refresh_token = params.get('refresh_token')
    const expires_in = Number(params.get('expires_in') || 3600)

    if (!access_token || !refresh_token) {
      return json({ error: 'Could not complete the sign-in exchange' }, 500)
    }

    return json({ email, access_token, refresh_token, expires_in }, 200)
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    return json({ error: msg }, 500)
  }
})