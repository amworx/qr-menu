# QR Menu — WhatsApp ordering

A single-file, no-backend digital menu for cafés & restaurants. Customers scan a QR code, browse a bilingual (EN/AR, RTL-ready) menu, build an order, and send it to the business over WhatsApp.

- **Zero backend** — orders go straight to the shop's WhatsApp.
- **Bilingual EN/AR** with RTL — built for the MENA market.
- **Config-driven** — edit the café name, WhatsApp number, currency, and menu items in `CONFIG`/`MENU` at the top of `index.html`.
- **Print-ready** — the browser's print view produces a clean paper menu.
- **QR button** — generates a QR code of the current URL (free public QR API, no key).

## Try it

Open `index.html` in any browser, or deploy the folder to GitHub Pages / Netlify / any static host and print/share the QR.

## Customize

1. Open `index.html`.
2. Edit `CONFIG` — shop name, WhatsApp number (digits only, no `+`), currency.
3. Edit `MENU` — categories and items with bilingual names/descriptions and prices.
4. Deploy. Done.

## Stack

Vanilla HTML/CSS/JS — no frameworks, no build step, no dependencies.

MIT — free to use and adapt.