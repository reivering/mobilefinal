-- Run this in the Supabase SQL editor after configuring the Clerk JWT
-- template. The Clerk user id is stored as text because Clerk IDs are not
-- UUIDs.

create table if not exists public.transactions (
  id text primary key,
  user_id text not null default (auth.jwt() ->> 'sub'),
  title text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  category text not null,
  date timestamptz not null,
  type text not null check (type in ('income', 'expense')),
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id text primary key,
  user_id text not null default (auth.jwt() ->> 'sub'),
  name text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  renewal_date timestamptz not null,
  category text not null,
  created_at timestamptz not null default now()
);

alter table public.transactions enable row level security;
alter table public.subscriptions enable row level security;

create policy "users can read their transactions"
  on public.transactions for select
  using (user_id = (auth.jwt() ->> 'sub'));

create policy "users can create their transactions"
  on public.transactions for insert
  with check (user_id = (auth.jwt() ->> 'sub'));

create policy "users can update their transactions"
  on public.transactions for update
  using (user_id = (auth.jwt() ->> 'sub'))
  with check (user_id = (auth.jwt() ->> 'sub'));

create policy "users can delete their transactions"
  on public.transactions for delete
  using (user_id = (auth.jwt() ->> 'sub'));

create policy "users can read their subscriptions"
  on public.subscriptions for select
  using (user_id = (auth.jwt() ->> 'sub'));

create policy "users can create their subscriptions"
  on public.subscriptions for insert
  with check (user_id = (auth.jwt() ->> 'sub'));

create policy "users can update their subscriptions"
  on public.subscriptions for update
  using (user_id = (auth.jwt() ->> 'sub'))
  with check (user_id = (auth.jwt() ->> 'sub'));

create policy "users can delete their subscriptions"
  on public.subscriptions for delete
  using (user_id = (auth.jwt() ->> 'sub'));
