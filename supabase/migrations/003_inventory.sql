create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops(id) on delete cascade not null,
  product_id uuid references products(id) on delete cascade not null,
  quantity integer not null default 0,
  cost_price numeric(10,2),
  selling_price numeric(10,2),
  expiry_date date,
  low_stock_threshold integer default 5,
  updated_at timestamptz default now(),
  unique(shop_id, product_id)
);

create index if not exists inventory_shop_id_idx on inventory(shop_id);
create index if not exists inventory_expiry_date_idx on inventory(expiry_date) where expiry_date is not null;

alter table inventory enable row level security;
