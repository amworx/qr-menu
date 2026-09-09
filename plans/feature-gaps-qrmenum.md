# Feature Gap Analysis — QR Menu (Judy Joy) vs qrmenum.app

Date: 2026-09-08
Status: Active (implementation queue)
Source analyzed: https://aurora.qrmenum.app/restaurant (Aurora Kitchen & Bar live demo, Istanbul / TRY)

## 1. Objective

Find out how a professional QR-menu SaaS platform does the job, compare it with our
qr-menu app (public `index.html` + admin `admin.html` + Supabase), organize missing
features into a ranked plan, and implement them one by one.

## 2. Professional feature inventory (evidence from the demo)

### 2.1 Catalog / menu engine
- Menu grouped into 3 accordion groups (Food / Beverages / Alcoholic Drinks), each with
  4–8 categories; each category has its own URL route: `/restaurant/menu/{group}/{category}`.
- **Category hero**: cover image, heading, description, "X items" count (e.g. Breakfast
  & Brunch "7 items").
- Category anchor jump tabs at top of category page (`#category-1` ...).
- **Featured items rail** — horizontal scroll carousel of featured products with thumbnails.
- Product cards (list layout): image, name, description, price, **kcal**, **allergen icons**.
- Product detail page per product (SEO-friendly URL `/restaurant/product/{slug}`):
  - breadcrumb (Group / Category)
  - multi-image gallery with Previous / Next + full image
  - Share button, Add to favorites (per-user)
  - name, price, **badges** (Popular, New, Chef's Choice)
  - **dietary attribute badges** (Vegetarian, Gluten-Free)
  - description, **nutritional values block** (calories / fat / carbs / protein, "per portion")
  - **preparation time** ("Preparation Time: 20 min")
  - **allergens section** (14 EU allergens with names)
  - **similar products** carousel
- **Size/price variants** with per-option price, list shows "From X₺": e.g. Cappuccino
  Small 110,00₺ / Large 130,00₺.
- Item not-available / price-from states.

### 2.2 Search & AI
- Full-screen **instant search overlay** ("Search or ask Aura"):
  - text input + **voice search** button (Web Speech API)
  - AI concierge greeting with quick chips: "Today's pick", "Vegan & vegetarian",
    "Something light", "Something sweet" → returns curated product lists
  - Browse rails: category buttons with item counts, FEATURED / MOST POPULAR / MOST LIKED
    product rails (with kcal, badges, "From" prices)
- (Aura = AI assistant over the menu; classification of requests, not just keyword search.)

### 2.3 Info / trust layer
- Info modal/page (bottom-nav "Info"): logo, about text, **service hours** (per day
  ranges), **address + Get Directions** (Google Maps), **phone (tel:)**,
  **social links** (Instagram / Facebook / Tripadvisor), **legal note** ("All prices
  include VAT", "Please inform us if you have any allergies").
- **WiFi connect** block: network name, password, Copy button, "Connect with QR".
- **Satisfaction survey** link ("Your feedback matters, takes 1 min").
- **Install as app** (PWA add-to-home-screen) prompt.

### 2.4 Platform / SEO
- **PWA**: manifest + service worker + install prompt.
- **SEO**: meta description, Open Graph, Twitter cards, canonical, per-page titles;
  **JSON-LD `Restaurant` schema** with name, url, image, address, telephone, priceRange.
- Tenant theming via `:root` CSS custom properties (primary/secondary/footer colors,
  fonts Roboto+Lato) — each restaurant gets a custom skin.
- Multi-language selector (TR/EN/...; our app already has AR/EN + RTL which is stronger
  for our market).
- Bottom navigation: MENU / Info / Language.
- Desktop presentation: phone-mockup "stage" layout.
- Feature modules in CSS reveal additional capabilities: cart sheet, takeaway mode,
  outlet picker (multi-location), campaign modal, survey widget, info page, motion &
  view-transitions.

## 3. Current Judy Joy baseline

- **Public** (`index.html`, single file): categories + items (name/name_ar, description,
  emoji icon or `image_url`, multi-currency `item_prices`), 5 deal types (percent, fixed,
  bogo, bundle, min_order), cart + order sheet + WhatsApp order submission, AR/EN toggle +
  RTL, dark/light theme, grid/list layout, sticky category rail, floating cart pill,
  featured flag, availability flag.
- **Admin** (`admin.html`): email-OTP auth (edge function), shop settings, categories
  CRUD, items CRUD, deals CRUD, currencies CRUD, orders view (shipped 2026-09-08).
- **DB** (`docs/schema.sql`): shops, categories, items, item_prices, deals, orders + RLS.
- No SEO/JSON-LD, no PWA, no search, no product detail, no variants/options, no allergens/
  nutrition, no badges, no info modal, no WiFi/socials/hours, no multi-outlet, no
  takeaway/survey, no share/favorites.

## 4. Gap list — ranked implementation queue

Legend: L/M/H = effort. Value: how much it improves professionalism/usability.

### PHASE 1 — bread & butter (do first, highest value/effort ratio)

| # | Feature | Evidence | Value | Effort | Notes |
|---|---------|----------|-------|--------|-------|
| P1.1 | SEO/OG/JSON-LD meta (Restaurant + ItemList) in `index.html` | HEAD of demo | High | L | Cheap, big shareability win (WhatsApp orders → shared links). Dynamic per-item share. |
| P1.2 | Product detail sheet (modal): image, desc, badges, allergens, nutrition, variants, qty, note, add-to-cart | product page | High | M | Fits our single-file app as a bottom-sheet/modal. Keeps card grid compact. |
| P1.3 | Item badges (New / Popular / Chef's Choice → `popular`, `chef_choice`, `is_new`) | product cards + search | High | L-M | schema + admin checkboxes + render chips. |
| P1.4 | kcal + prep time (+ optional nutrition block) | product page | Med | L | optional numeric columns; render on card + sheet. |
| P1.5 | Allergens (icon chips on card + section in sheet) | category page | Med-High | M | fixed 14-allergen list, per-item jsonb, AR/EN labels + emoji/icon rendering. |
| P1.6 | Size/price variants + "From X₺" | cappuccino | High | M | `variants jsonb` (name, name_ar, price per currency or multiplier); cart line carries chosen variant. |
| P1.7 | Category hero (image, description, item count) + intro on category section | category page | Med | L | categories gain `image_url`, `description`, `description_ar`. |
| P1.8 | Instant search overlay (text across name/name_ar/desc) | search overlay | High | M | no AI — fuzzy keyword; group results by category; no voice in v1. |
| P1.9 | Info modal: about, hours, address+directions, phone, socials, legal note | Info modal | High | M | shop settings fields + modal UI. |
| P1.10 | Share product (WhatsApp / copy link) | product page Share | Med | L | reuse WhatsApp channel. |
| P1.11 | Service hours + open/closed state | Info modal | Med | L | shops.hours jsonb; "Open now" chip on sheet. |

### PHASE 2 — engagement & ops (medium effort)

| # | Feature | Evidence | Value | Effort |
|---|---------|----------|-------|--------|
| P2.1 | Favorites (localStorage) + favorites rail | Add to favorites | Med | M |
| P2.2 | Voice search (Web Speech API wrapper) | Voice search button | Med | L-M |
| P2.3 | Similar products rail (same category) | Similar Products | Med | L |
| P2.4 | PWA: manifest + service worker + install prompt | "Install as app" | Med | M |
| P2.5 | WiFi info block (network/password/copy) | Info modal | Low | L |
| P2.6 | Takeaway/dine-in order mode toggle (affects WhatsApp message) | takeaway module | Med-High | M |
| P2.7 | Table/QR per-table attribution (query param → order note) | industry norm | Med | M |
| P2.8 | Multi-outlet selector (shop → outlets) | outlet-picker module | Med-High | H |
| P2.9 | Satisfaction survey (rate + comment → edge function → DB) | survey module | Med | M — ✅ DONE (EVT-2026-09-08-0036, ae23d1d) |
| P2.10 | Campaign/promo landing modal (one-time) | campaign module | Low | M — ✅ DONE (EVT-2026-09-08-0037, eb721f4) |

### PHASE 3 — platform / large (defer or explicit request)

| # | Feature | Evidence | Rationale |
|---|---------|----------|-----------|
| P3.1 | Aura-style AI concierge | Aura chef | Needs LLM API + edge function + moderation; recurring cost. Defer. |
| P3.2 | Full multi-language platform (beyond AR/EN) | Language selector | Architectural change to locale dictionaries; our market is AR/EN. Defer. |
| P3.3 | Tenant theme editor (colors/fonts via settings) | :root vars | Demo platform is multi-tenant; we are single-shop. Nice-to-have: ship as CSS-var from shop settings later. |
| P3.4 | Desktop phone-mockup stage | desktop stage | Cosmetic; single-file app fine on mobile-first. Defer. |
| P3.5 | Loyalty/accounts (favorites across devices, user profiles) | Add to favorites | Requires auth; out of scope now. |

## 5. Implementation order (one by one)

Recommended sequence (max value first, each is independently shippable):

1. **P1.1 SEO/OG/JSON-LD** (pure frontend, zero DB)
2. **P1.7 Category hero** (schema + admin + render)
3. **P1.3 Item badges** (schema + admin + render)
4. **P1.4 kcal + prep time + P1.5 allergens** (schema + admin + card/sheet render)
5. **P1.2 Product detail sheet** (modal; consumes badges/nutrition/allergens/variants)
6. **P1.6 Size/price variants + From X** (schema + admin + cart integration)
7. **P1.8 Instant search overlay**
8. **P1.9 Info modal + P1.10 share + P1.11 hours/open-close**
9. Phase 2 items.

Each task: docs/schema.sql → DB migration via Management API → admin.html UI → index.html
render → test AR/EN + RTL + 375px mobile → memory event/lesson → propose commit.

## 6. Decisions & rationale

- **Modal/bottom-sheet over separate product pages**: our app is single-file, mobile-first,
  and orders flow through WhatsApp; a modal keeps the flow fast and matches the demo's
  detail-mode (they also offer modal mode).
- **Skip AI concierge for now**: meaningful cost/complexity, not needed for the core
  "scan → browse → order" loop at our scale.
- **Keep AR/EN + RTL**: demo doesn't even have RTL; our localization is a strength.
- **Multi-outlet deferred**: schema would need outlets table + per-outlet pricing/RLS;
  high effort, single-location shop today.
- Currency symbol display (₺ without "TRY") can be added cheaply to the price renderer
  during P1.x work — we already have symbol map in config/deals.
- Nutrition values are optional; UI hides block when absent.

## 7. Verification checklist (per feature)

- [ ] EN desktop: renders, no console errors
- [ ] AR + RTL desktop: mirrored layout intact
- [ ] strict 375px mobile: no horizontal overflow (docScrollW == docClientW == 375)
- [ ] admin CRUD works for new fields
- [ ] memory updated (EVT + LSSN)
