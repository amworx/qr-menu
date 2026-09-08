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
