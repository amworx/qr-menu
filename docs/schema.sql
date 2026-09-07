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

-- ─── DEALS ──────────────────────────────────────────────────
create table if not exists deals (
  id uuid primary key default uuid_generate_v4(),
  shop_id uuid references shops(id) on delete cascade,
  title text not null,
  title_ar text default '',
  description text default '',
  description_ar text default '',
  discount_type text default 'percent',          -- 'percent' or 'fixed'
  discount_value numeric(10,2) default 0,
  currency text default 'SYP',                   -- for fixed discounts
  min_qty int default 1,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- ─── INDEXES ────────────────────────────────────────────────
create index if not exists idx_categories_shop on categories(shop_id);
create index if not exists idx_items_shop on items(shop_id);
create index if not exists idx_items_category on items(category_id);
create index if not exists idx_item_prices_item on item_prices(item_id);
create index if not exists idx_deals_shop on deals(shop_id);

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
