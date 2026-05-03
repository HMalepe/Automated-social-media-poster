create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  barcode text unique not null,
  name text not null,
  category text,
  default_price numeric(10,2) not null,
  image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists products_barcode_idx on products(barcode);

alter table products enable row level security;
