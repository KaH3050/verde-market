-- =====================================================================
-- Verde Market — customer accounts (Supabase)
-- Paste everything into Supabase → SQL Editor → Run.
-- Safe to run again: it skips what already exists and fills in what is missing.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PROFILES: one row per customer (name, phone, saved address)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text check (char_length(full_name) <= 120),
  phone       text check (char_length(phone) <= 30),
  address     text check (char_length(address) <= 200),
  city        text check (char_length(city) <= 80),
  state       text check (state is null or state ~ '^[A-Z]{2}$'),
  zip         text check (zip is null or zip ~ '^[0-9]{5}$'),
  lang        text not null default 'en' check (lang in ('en', 'pt')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- each customer can only see and edit their own profile
drop policy if exists "profiles: read own"   on public.profiles;
drop policy if exists "profiles: insert own" on public.profiles;
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: read own"   on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profiles: insert own" on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles: update own" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- create the profile automatically when someone signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, lang)
  values (
    new.id,
    left(new.raw_user_meta_data ->> 'full_name', 120),
    case when new.raw_user_meta_data ->> 'lang' = 'pt' then 'pt' else 'en' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- accounts created before the trigger existed also get a profile
insert into public.profiles (id, full_name)
select u.id, left(u.raw_user_meta_data ->> 'full_name', 120)
from auth.users u
on conflict (id) do nothing;

-- keep updated_at fresh
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch
  before update on public.profiles
  for each row execute procedure public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 2. ORDERS: saved at checkout (payment is still simulated in the demo)
-- ---------------------------------------------------------------------
create table if not exists public.orders (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique check (code ~ '^VM-[0-9]{5}$'),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  status          text not null default 'confirmed'
                  check (status in ('confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled')),
  items           jsonb not null check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) between 1 and 60),
  subtotal        numeric(10,2) not null check (subtotal >= 0),
  discount        numeric(10,2) not null default 0 check (discount >= 0),
  shipping        numeric(10,2) not null default 0 check (shipping >= 0),
  total           numeric(10,2) not null check (total >= 0),
  coupon          text check (char_length(coupon) <= 20),
  ship_method     text check (ship_method in ('local', 'std', 'exp')),
  ship_address    jsonb,
  payment_method  text check (payment_method in ('card', 'apple', 'paypal')),
  created_at      timestamptz not null default now()
);

create index if not exists orders_user_created on public.orders (user_id, created_at desc);

alter table public.orders enable row level security;

-- customers can read their own orders and create new ones (always starting as "confirmed").
-- there is no update/delete policy: customers can't change an order after placing it.
drop policy if exists "orders: read own"   on public.orders;
drop policy if exists "orders: insert own" on public.orders;
create policy "orders: read own"   on public.orders for select to authenticated using ((select auth.uid()) = user_id);
create policy "orders: insert own" on public.orders for insert to authenticated with check ((select auth.uid()) = user_id and status = 'confirmed');

-- ---------------------------------------------------------------------
-- 3. TABLE PRIVILEGES for signed-in customers
-- Newer Supabase projects don't expose new tables automatically, so grant them explicitly.
-- Visitors who are not signed in (anon) get no access at all. RLS above still limits each customer to their own rows.
-- ---------------------------------------------------------------------
grant usage on schema public to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert on public.orders to authenticated;

-- ---------------------------------------------------------------------
-- 4. DELETE MY ACCOUNT
-- A signed-in customer can delete their own login. Their profile and orders go with it (on delete cascade).
-- It only ever touches the caller's own user id.
-- ---------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
