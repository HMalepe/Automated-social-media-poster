create table if not exists sales (
  id uuid primary key default gen_random_uuid(),
  local_id text unique not null,
  shop_id uuid references shops(id) on delete cascade not null,
  total_amount numeric(10,2) not null,
  payment_method text default 'cash' check (payment_method in ('cash', 'card', 'other')),
  cash_received numeric(10,2),
  change_given numeric(10,2),
  created_at timestamptz default now()
);

create index if not exists sales_shop_id_created_at_idx on sales(shop_id, created_at desc);

create table if not exists sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid references sales(id) on delete cascade not null,
  product_id uuid references products(id),
  product_name text not null,
  quantity integer not null,
  unit_price numeric(10,2) not null,
  line_total numeric(10,2) generated always as (quantity * unit_price) stored
);

create index if not exists sale_items_sale_id_idx on sale_items(sale_id);

alter table sales enable row level security;
alter table sale_items enable row level security;
