-- ============================================================
-- QR Menu — Supabase Schema
-- Run this in the SQL Editor to create all tables + RLS policies.
-- ============================================================

-- Enable UUID extension (should already be enabled)
create extension if not exists "uuid-ossp";

-- ─── SHOPS ──────────────────────────────────────────────────
create table if not exists shops (
  id uuid primary key default uuid_generate_v4(),
  owner_email text not null,                    -- admin email (OTP login)
  name text not null default 'My Shop',
  name_ar text default '',
  tagline text default '',
  tagline_ar text default '',
  whatsapp text default '',                     -- WhatsApp number (with country code)
  phone text default '',
  email text default '',
  address text default '',
  address_ar text default '',
  logo_url text default '',
  primary_color text default '#D97706',         -- amber-600
  accent_color text default '#92400E',          -- amber-800
  currency_default text default 'SYP',          -- default display currency
  currencies text[] default '{SYP,USD,TRY}',    -- enabled currencies
  show_currency_selector boolean default true,
  footer_text text default '',
  footer_text_ar text default '',
  is_active boolean default true,
  -- P1.9 Info modal fields
  about text default '',                    -- about (EN)
  about_ar text default '',                 -- about (AR)
  instagram text default '',
  facebook text default '',
  tripadvisor text default '',
  legal_note text default '',               -- legal note (EN), e.g. "All prices include VAT"
  legal_note_ar text default '',            -- legal note (AR)
  wifi_name text default '',                -- P2.5 WiFi network name shown in Info modal
  wifi_pass text default '',                -- P2.5 WiFi password (copy button)
  hours jsonb,                              -- P1.11: 7 entries Mon..Sun [{open:'08:00',close:'23:00'}, ...] or null = closed
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─── CATEGORIES ─────────────────────────────────────────────
create table if not exists categories (
  id uuid primary key default uuid_generate_v4(),
  shop_id uuid references shops(id) on delete cascade,
  name text not null,
  name_ar text default '',
  image_url text default '',                    -- category hero image (P1.7)
  description text default '',                  -- category hero description EN (P1.7)
  description_ar text default '',               -- category hero description AR (P1.7)
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ─── ITEMS ──────────────────────────────────────────────────
create table if not exists items (
  id uuid primary key default uuid_generate_v4(),
  shop_id uuid references shops(id) on delete cascade,
  category_id uuid references categories(id) on delete set null,
  name text not null,
  name_ar text default '',
  description text default '',
  description_ar text default '',
  image_url text default '',
  is_available boolean default true,
  is_featured boolean default false,
  popular boolean default false,                 -- badge "Popular" (P1.3)
  chef_choice boolean default false,             -- badge "Chef's Choice" (P1.3)
  is_new boolean default false,                  -- badge "New" (P1.3)
  kcal integer,                                  -- calories per portion (P1.4)
  prep_time_min integer,                         -- preparation time in minutes (P1.4)
  allergens jsonb,                               -- array of allergen codes from fixed 14 list (P1.5)
  variants jsonb,                                -- size/option variants: [{name, name_ar, prices:{SYP,USD,TRY}}] (P1.6)
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─── ITEM PRICES (multi-currency) ──────────────────────────
create table if not exists item_prices (
  id uuid primary key default uuid_generate_v4(),
  item_id uuid references items(id) on delete cascade,
  currency text not null,                        -- 'SYP', 'USD', 'TRY'
  price numeric(12,2) not null default 0,
  is_visible boolean default true,               -- admin toggle per currency
  unique(item_id, currency)
);

-- ─── DEALS / OFFERS ────────────────────────────────────────
-- deal_type: percent | fixed | bogo | bundle | min_order
--   percent   — X% off (scope: a single item, a category, or all)
--   fixed     — X fixed amount off (scope: item / category / all)
--   bogo      — Buy X Get Y Free (applies to one item: item_id + buy_qty/get_qty)
--   bundle    — Combo: chosen items (bundle_items jsonb[]) sold at bundle_price
--   min_order — Spend min_total → reward (reward_type percent|fixed, value in discount_value)
create table if not exists deals (
  id uuid primary key default uuid_generate_v4(),
  shop_id uuid references shops(id) on delete cascade,
  title text not null,
  title_ar text default '',
  description text default '',
  description_ar text default '',
  deal_type text default 'percent',
  discount_value numeric(10,2) default 0,
  currency text default 'SYP',
  applies_to text default 'all',                 -- item | category | all
  item_id uuid,                                  -- when applies_to='item' (also bogo)
  category_id uuid,                              -- when applies_to='category'
  buy_qty int,                                   -- bogo: buy X
  get_qty int,                                   -- bogo: get Y free
  min_total numeric(12,2),                       -- min_order threshold
  reward_type text,                              -- min_order: percent | fixed
  bundle_price numeric(12,2),                    -- bundle set price
  bundle_items jsonb,                            -- bundle: array of item ids
  min_qty int default 1,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now(),
  constraint deals_deal_type_check check (deal_type in ('percent','fixed','bogo','bundle','min_order')),
  constraint deals_applies_to_check check (applies_to in ('item','category','all')),
  constraint deals_reward_type_check check (reward_type is null or reward_type in ('percent','fixed'))
);

-- ─── ORDERS (placed from the public menu) ──────────────────
-- Each order gets a sequential id (bigserial) shown to the customer as
-- "Order #<id>" and recorded here so the owner can review history.
-- Public (anon) may insert; only the shop owner may select/manage.
create table if not exists orders (
  id bigserial primary key,
  shop_id uuid references shops(id) on delete cascade,
  currency text not null default 'SYP',
  subtotal numeric(12,2) not null default 0,     -- before discounts
  discount numeric(12,2) not null default 0,     -- total applied discount
  total numeric(12,2) not null default 0,        -- subtotal - discount
  items jsonb not null default '[]',             -- [{id,name,name_ar,qty,unit_price}]
  offers jsonb not null default '[]',            -- [{id,title,title_ar,summary,savings}]
  discount_lines jsonb not null default '[]',    -- [{id,title,title_ar,amount}]
  note text default '',                          -- customer order note
  order_mode text default 'dinein',              -- P2.6: dinein | takeaway (toggle in order sheet)
  table_label text default '',                    -- P2.7: table/QR attribution from ?table=<id>
  outlet_id uuid references outlets(id),          -- P2.8: selected outlet (nullable)
  outlet_label text default '',                   -- P2.8: snapshot of outlet display name at order time
  created_at timestamptz not null default now()
);

-- ─── MIGRATION (2026-09-07) — existing DBs that had the old deals table ──
-- The original table used `discount_type` ('percent'|'fixed'). This adds the
-- extended deal model and backfills deal_type. Idempotent; safe on 0 rows.
-- alter table deals add column if not exists deal_type text;
-- alter table deals add column if not exists applies_to text;
-- alter table deals add column if not exists item_id uuid;
-- alter table deals add column if not exists category_id uuid;
-- alter table deals add column if not exists buy_qty int;
-- alter table deals add column if not exists get_qty int;
-- alter table deals add column if not exists min_total numeric(12,2);
-- alter table deals add column if not exists reward_type text;
-- alter table deals add column if not exists bundle_price numeric(12,2);
-- alter table deals add column if not exists bundle_items jsonb;
-- update deals set deal_type = coalesce(nullif(discount_type,''),'percent') where deal_type is null;
-- update deals set applies_to = coalesce(applies_to,'all');
-- alter table deals alter column deal_type set not null;
-- alter table deals alter column deal_type set default 'percent';
-- alter table deals alter column applies_to set default 'all';
-- alter table deals drop constraint if exists deals_deal_type_check;
-- alter table deals drop constraint if exists deals_applies_to_check;
-- alter table deals drop constraint if exists deals_reward_type_check;
-- alter table deals add constraint deals_deal_type_check check (deal_type in ('percent','fixed','bogo','bundle','min_order'));
-- alter table deals add constraint deals_applies_to_check check (applies_to in ('item','category','all'));
-- alter table deals add constraint deals_reward_type_check check (reward_type is null or reward_type in ('percent','fixed'));

-- ─── MIGRATION (2026-09-08) — category hero fields (P1.7) ──
-- alter table categories add column if not exists image_url text default '';
-- alter table categories add column if not exists description text default '';
-- alter table categories add column if not exists description_ar text default '';

-- ─── MIGRATION (2026-09-08) — item badges (P1.3) ─────────
-- alter table items add column if not exists popular boolean default false;
-- alter table items add column if not exists chef_choice boolean default false;
-- alter table items add column if not exists is_new boolean default false;

-- ─── MIGRATION (2026-09-08) — kcal + prep time (P1.4) ────
-- alter table items add column if not exists kcal integer;
-- alter table items add column if not exists prep_time_min integer;

-- ─── MIGRATION (2026-09-08) — allergens (P1.5) ────────────
-- alter table items add column if not exists allergens jsonb;
-- Fixed 14-allergen codes stored as a jsonb array: gluten, crustaceans, eggs,
-- fish, peanuts, soy, milk, nuts, celery, mustard, sesame, sulphites, lupin,
-- molluscs. AR/EN labels + icons live in the frontend ALLERGENS constants.

-- ─── MIGRATION (2026-09-08) — size/price variants (P1.6) ──
-- alter table items add column if not exists variants jsonb;
-- Variant shape: [{ "name":"Small","name_ar":"صغير","prices":{"SYP":15000,"USD":1.5,"TRY":45} }, ...]
-- Cards show "From <min>" when variants exist; the product sheet forces a choice.

-- ─── INDEXES ────────────────────────────────────────────────
create index if not exists idx_categories_shop on categories(shop_id);
create index if not exists idx_items_shop on items(shop_id);
create index if not exists idx_items_category on items(category_id);
create index if not exists idx_item_prices_item on item_prices(item_id);
create index if not exists idx_deals_shop on deals(shop_id);
create index if not exists idx_orders_shop on orders(shop_id);

-- ─── UPDATED_AT TRIGGER ────────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger shops_updated_at before update on shops
  for each row execute function update_updated_at();

create trigger items_updated_at before update on items
  for each row execute function update_updated_at();

-- ─── ROW LEVEL SECURITY ────────────────────────────────────
alter table shops enable row level security;
alter table categories enable row level security;
alter table items enable row level security;
alter table item_prices enable row level security;
alter table deals enable row level security;
alter table orders enable row level security;

-- Public can read active shops and their data
create policy "Public can view active shops"
  on shops for select using (is_active = true);

create policy "Public can view categories"
  on categories for select using (is_active = true);

create policy "Public can view available items"
  on items for select using (is_available = true);

create policy "Public can view visible prices"
  on item_prices for select using (is_visible = true);

create policy "Public can view active deals"
  on deals for select using (is_active = true);

-- Authenticated users can manage their own shop
create policy "Owner can manage their shop"
  on shops for all using (owner_email = auth.email());

create policy "Owner can manage categories"
  on categories for all using (
    shop_id in (select id from shops where owner_email = auth.email())
  );

create policy "Owner can manage items"
  on items for all using (
    shop_id in (select id from shops where owner_email = auth.email())
  );

create policy "Owner can manage item prices"
  on item_prices for all using (
    item_id in (
      select i.id from items i
      join shops s on i.shop_id = s.id
      where s.owner_email = auth.email()
    )
  );

create policy "Owner can manage deals"
  on deals for all using (
    shop_id in (select id from shops where owner_email = auth.email())
  );

-- Anyone can place an order (public form); the owner manages all their orders
create policy "Public can place orders"
  on orders for insert with check (true);

create policy "Owner can manage orders"
  on orders for all using (
    shop_id in (select id from shops where owner_email = auth.email())
  );

-- ─── SEED DATA ─────────────────────────────────────────────
-- Creates a default shop for amworxx@gmail.com
insert into shops (owner_email, name, name_ar, tagline, tagline_ar, whatsapp, currency_default, currencies)
values (
  'amworxx@gmail.com',
  'Al-Sahari Café',
  'مقهى الصحراء',
  'Fresh coffee & light bites',
  'قهوة طازجة ووجبات خفيفة',
  '963992656853',
  'SYP',
  '{SYP,USD,TRY}'
) on conflict do nothing;

-- Creates default categories
do $$
declare
  v_shop_id uuid;
begin
  select id into v_shop_id from shops where owner_email = 'amworxx@gmail.com' limit 1;
  if v_shop_id is not null then
    insert into categories (shop_id, name, name_ar, sort_order) values
      (v_shop_id, 'Hot Drinks', 'المشروبات الساخنة', 1),
      (v_shop_id, 'Cold Drinks', 'المشروبات الباردة', 2),
      (v_shop_id, 'Food', 'الطعام', 3),
      (v_shop_id, 'Desserts', 'الحلويات', 4)
    on conflict do nothing;
  end if;
end $$;

-- ─── MIGRATIONS ─────────────────────────────────────────────
-- P1.6 (2026-09-08): item size/price variants (jsonb array
--   [{name, name_ar, prices:{SYP,USD,TRY}}]); card shows "From X";
--   cart line carries the chosen variant.
--   alter table items add column if not exists variants jsonb;

-- P1.9 (2026-09-08): public Info modal data on shops —
--   about/about_ar (EN/AR text), social links (instagram/facebook/tripadvisor),
--   legal note (EN/AR). Rendered by index.html #info-modal.
--   alter table shops add column if not exists about text default '',
--     add column if not exists about_ar text default '',
--     add column if not exists instagram text default '',
--     add column if not exists facebook text default '',
--     add column if not exists tripadvisor text default '',
--     add column if not exists legal_note text default '',
--     add column if not exists legal_note_ar text default '';

-- P1.11 (2026-09-08): service hours jsonb on shops — 7 entries Mon..Sun,
--   each `[{open:'08:00', close:'23:00'}, ...]`, null entry = closed that day;
--   drives the "Open now / Closed" chip + hours table in the public info modal
--   (isNowOpen()/infoHoursHTML()) and the admin Shop Settings hours editor
--   (s.hours persisted by saveShop → hoursEditorRows()/collectHours()).
--   alter table shops add column if not exists hours jsonb;

-- P2.5 (2026-09-08): WiFi info block — shops.wifi_name (SSID) + shops.wifi_pass,
--   rendered as a "واي فاي / WiFi" section in the public Info modal with a copy
--   button; edited from the admin Shop Settings WiFi card (saveShop persists).
--   alter table shops add column if not exists wifi_name text default '',
--     add column if not exists wifi_pass text default '';

-- P2.6 (2026-09-08): order mode — orders.order_mode ('dinein'|'takeaway'), picked
--   from the order sheet toggle (🍽️ في المكان / 🥡 سفري) and sent at the top of
--   the WhatsApp message; persisted per device via localStorage 'qm-order-mode'.
--   alter table orders add column if not exists order_mode text default 'dinein';

-- P2.7 (2026-09-08): table/QR attribution — orders.table_label. The public page
--   reads ?table=<id> (any label: "5", "A12", "balcony") and prints it in the
--   order sheet ("الطاولة / Table" chip), in the WhatsApp message right after
--   the mode line, and into orders.table_label. Post-GA, per-table QR codes are
--   simply menu URLs with ?table=<id>.
--   alter table orders add column if not exists table_label text default '';

-- P2.8 (2026-09-08): multi-outlet — `outlets` table (shop → many outlets), public
--   branch selector in the order sheet, per-outlet WhatsApp routing, orders gets
--   outlet_id + outlet_label snapshot. RLS: anyone can select; owner (via shops.
--   owner_email = auth.email()) can insert/update/delete. Applied via Management
--   API; seeded 2 demo outlets for amworx (Main Branch / الفرع الرئيسي, Branch 2 /
--   الفرع الثاني, both 963992656853).
-- create table if not exists outlets (
--   id uuid primary key default gen_random_uuid(),
--   shop_id uuid not null references shops(id) on delete cascade,
--   name text not null default '',
--   name_ar text not null default '',
--   whatsapp text default '',
--   address text default '',
--   address_ar text default '',
--   sort_order int not null default 0,
--   is_active boolean not null default true,
--   created_at timestamptz not null default now()
-- );
-- create index if not exists outlets_shop_id_idx on outlets(shop_id);
-- alter table outlets enable row level security;
-- create policy outlets_select on outlets for select using (true);
-- create policy outlets_owner_insert on outlets for insert with check
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- create policy outlets_owner_update on outlets for update using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- create policy outlets_owner_delete on outlets for delete using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
--   alter table orders add column if not exists outlet_id uuid references outlets(id);
--   alter table orders add column if not exists outlet_label text default '';

-- P2.9 (2026-09-08): satisfaction survey — `surveys` table + edge function
--   submit-survey (deployed --no-verify-jwt, public). The public app shows a
--   star-rating modal ~1s after an order is sent; the edge function validates
--   (uuid shop_id, integer 1..5, comment <= 500 chars) and inserts via the
--   service role. RLS: anon insert allowed (server-side validation), owner can
--   select (used with the Management API / dashboard for now; a Surveys tab in
--   the admin can read owner-only later).
-- create table if not exists surveys (
--   id bigserial primary key,
--   shop_id uuid not null references shops(id) on delete cascade,
--   rating int not null check (rating between 1 and 5),
--   comment text default '',
--   created_at timestamptz not null default now()
-- );
-- create index if not exists surveys_shop_id_idx on surveys(shop_id);
-- alter table surveys enable row level security;
-- create policy surveys_insert on surveys for insert with check
--   (rating between 1 and 5 and comment is null or comment = '' or length(comment) <= 500);
-- create policy surveys_owner_select on surveys for select using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- create policy surveys_owner_delete on surveys for delete using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- (2026-09-10: Reviews tab added to admin — list/avg/star bars + delete. Policy applied.)
-- Edge function: supabase/functions/submit-survey/index.ts
--   supabase functions deploy submit-survey --project-ref pxgwxcurhzphmtvowdri --no-verify-jwt

-- P3 (2026-09-08): Badges + Allergens catalogs + Orders interaction (admin).
--   A1 Badges: `shop_badges` catalog table (per shop), items.custom_badges jsonb
--   holds an ARRAY OF BADGE IDS (rename-safe). The three built-in booleans
--   (popular / chef_choice / is_new) stay; custom badges render in addition.
--   Deleting a badge strips its id from every item.custom_badges.
-- create table if not exists shop_badges (
--   id uuid primary key default gen_random_uuid(),
--   shop_id uuid not null references shops(id) on delete cascade,
--   label text not null default '',
--   label_ar text not null default '',
--   color text not null default '#D97706',
--   emoji text not null default '',
--   is_active boolean not null default true,
--   sort_order int not null default 0,
--   created_at timestamptz not null default now(),
--   updated_at timestamptz not null default now()
-- );
-- create index if not exists shop_badges_shop_id_idx on shop_badges(shop_id);
-- alter table shop_badges enable row level security;
-- create policy shop_badges_public_select on shop_badges for select using (true);
-- create policy shop_badges_owner_insert on shop_badges for insert with check
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- create policy shop_badges_owner_update on shop_badges for update using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- create policy shop_badges_owner_delete on shop_badges for delete using
--   (exists (select 1 from shops where shops.id = shop_id and shops.owner_email = auth.email()));
-- alter table items add column if not exists custom_badges jsonb default '[]'::jsonb;
--
--   A2 Allergens: `shop_allergens` catalog (per shop); items.allergens stays an
--   ARRAY OF CODES that resolve against the catalog (frontend falls back to the
--   built-in 14 EU FIC list for legacy codes). The 14 EU allergens are seeded per
--   shop; unique(shop_id, code). Deleting an allergen strips its code from items.
-- create table if not exists shop_allergens (
--   id uuid primary key default gen_random_uuid(),
--   shop_id uuid not null references shops(id) on delete cascade,
--   code text not null,
--   name text not null default '',
--   name_ar text not null default '',
--   icon text not null default '',
--   is_active boolean not null default true,
--   sort_order int not null default 0,
--   created_at timestamptz not null default now(),
--   updated_at timestamptz not null default now(),
--   unique (shop_id, code)
-- );
-- create index if not exists shop_allergens_shop_id_idx on shop_allergens(shop_id);
-- alter table shop_allergens enable row level security;
-- (same public-select + owner-write policy pattern as shop_badges)
--
--   A3 Orders interaction: orders.status (check constraint) + orders.customer_phone.
--   The public order sheet has an optional phone field (persisted per device in
--   localStorage 'qm-phone'); the admin Orders tab has a status filter + per-row
--   status select + Reply button that opens wa.me with a pre-filled message using
--   the customer's phone (copy button; phone persisted back onto the order).
-- alter table orders add column if not exists status text not null default 'new'
--   constraint orders_status_check check
--   (status in ('new','confirmed','preparing','ready','delivered','cancelled'));
-- alter table orders add column if not exists customer_phone text default '';
--
--   Note: an `item_allergens` junction table was created during the first
--   migration attempt then dropped — items.allergens (jsonb codes) is the
--   source of truth, no junction table is used.
--
-- ─── P3.1 (2026-09-09): STORE LOCATION + CUSTOMER DELIVERY ─────────
-- Owner sets the store pin from the Shop Settings "Store location" card
-- (Leaflet + OSM + Nominatim reverse geocode); public order sheet adds a
-- third order mode `'delivery'` with a customer pin on the same map.
-- Directions buttons use the shop pin (Google Maps q=lat,lng) when set.
-- alter table shops add column if not exists location_lat double precision;
-- alter table shops add column if not exists location_lng double precision;
-- alter table orders add column if not exists delivery_address text default '';
-- alter table orders add column if not exists delivery_lat double precision;
-- alter table orders add column if not exists delivery_lng double precision;
-- alter table orders drop constraint if exists orders_order_mode_check;
-- alter table orders add constraint orders_order_mode_check check
--   (order_mode in ('dinein','takeaway','delivery'));
