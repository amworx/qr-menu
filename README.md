# QR Menu — Judy Joy (جودي جوي)

Digital QR menu + WhatsApp ordering for cafés & restaurants. Customers scan a QR code,
browse a bilingual (EN/AR, RTL) menu, build an order — items plus live offers — review
the subtotal/discounts/total, and send it straight to the shop's WhatsApp. A built-in
admin dashboard lets the owner manage the shop profile, categories, items, prices, and offers.

- Live menu: https://amworx.github.io/qr-menu/
- Admin: https://amworx.github.io/qr-menu/admin.html

## Features

- **Bilingual EN/AR with RTL**, Arabic-first, dark/light theme, mobile-first.
- **Public menu**: categories, items with multi-currency prices, list/grid toggle.
- **Offers**: percent, fixed, BOGO, bundle, min-spend — added to the order and applied
  to the total by a pricing engine.
- **Order sheet**: subtotal → per-offer discounts → total; one-tap remove; notes.
- **Orders**: every order gets a sequential number (`#N`) and is stored in Supabase.
- **WhatsApp delivery**: numbered message with itemized lines and discount breakdown.
- **Admin**: email-only login (no password/OTP — SMTP not configured), CRUD for
  shop/categories/items/prices/deals, search/filter/sort/pagination.

## Stack

Vanilla HTML/CSS/JS (no frameworks, no build step) + Supabase
(Postgres, Auth, Edge Functions) + GitHub Pages.

## Run locally

Serve this folder statically and open it in a browser
(e.g. `npx serve .` or a local static server on port 8088).
Add `#en` / `#ar` to switch language (default Arabic).

## Deploy

`git push origin main` → GitHub Pages rebuilds automatically (~20–60 s).
`.nojekyll` is kept at root on purpose (the repo contains a `.ts` edge function).

## Project structure

| Path | Role |
|---|---|
| `index.html` | Public menu + cart + order flow (single file) |
| `admin.html` | Admin dashboard |
| `config.js` | Supabase URL + anon key |
| `docs/schema.sql` | Canonical schema + RLS (source of truth) |
| `supabase/functions/admin-login-gate/` | Email-only login Edge Function |
| `memory/` | events / lessons / patterns / decisions / playbooks (+ gitignored credentials) |
| `AGENTS.md` | Rules for AI agents |
| `ASSISTANT_PROMPT.md` | Paste-ready briefing for any new AI assistant |

## Docs

- Schema/RLS: `docs/schema.sql`
- Agent onboarding: `AGENTS.md`, `ASSISTANT_PROMPT.md`
- Project history & lessons: `memory/` (`events.md`, `lessons.md`, `patterns.md`, `decisions.md`, `playbooks.md`)

MIT — free to use and adapt.