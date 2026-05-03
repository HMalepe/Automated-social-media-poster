create table if not exists shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  address text,
  created_at timestamptz default now()
);

alter table shops enable row level security;
