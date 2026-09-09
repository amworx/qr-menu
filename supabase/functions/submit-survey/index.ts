// P2.9 — Satisfaction survey submission.
// POST { shop_id, rating (1-5), comment? } -> inserts into surveys (via service role).
// Validates input server-side so anon clients can't spam junk rows through the anon key.
// Deploy: supabase functions deploy submit-survey --project-ref pxgwxcurhzphmtvowdri
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

const isUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: HEADERS, status: 204 });

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ ok: false, error: 'method not allowed' }), { headers: HEADERS, status: 405 });
  }

  let body: any = {};
  try { body = await req.json(); } catch { /* invalid json -> default */ }

  const shop_id = String(body.shop_id || '');
  const rating = Number(body.rating);
  const comment = String(body.comment ?? '').slice(0, 500).trim();

  if (!isUuid(shop_id)) {
    return new Response(JSON.stringify({ ok: false, error: 'invalid shop_id' }), { headers: HEADERS, status: 400 });
  }
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return new Response(JSON.stringify({ ok: false, error: 'rating must be an integer 1..5' }), { headers: HEADERS, status: 400 });
  }

  const { data, error } = await supabase
    .from('surveys')
    .insert({ shop_id, rating, comment })
    .select('id')
    .single();

  if (error) {
    return new Response(JSON.stringify({ ok: false, error: error.message }), { headers: HEADERS, status: 500 });
  }
  return new Response(JSON.stringify({ ok: true, id: data.id }), { headers: HEADERS, status: 201 });
});