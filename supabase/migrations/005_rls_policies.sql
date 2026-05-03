-- Shops: owner sees and manages only their shop
create policy "shops_owner_all" on shops
  for all using (owner_id = auth.uid());

-- Products: any authenticated user can read (shared product catalogue)
create policy "products_authenticated_read" on products
  for select using (auth.role() = 'authenticated');

-- Products: any authenticated user can insert (contributing to shared catalogue)
create policy "products_authenticated_insert" on products
  for insert with check (auth.role() = 'authenticated');

-- Inventory: shop owner manages their own inventory
create policy "inventory_owner_all" on inventory
  for all using (
    shop_id in (select id from shops where owner_id = auth.uid())
  );

-- Sales: shop owner manages their own sales
create policy "sales_owner_all" on sales
  for all using (
    shop_id in (select id from shops where owner_id = auth.uid())
  );

-- Sale items: accessible if the parent sale belongs to owner's shop
create policy "sale_items_owner_all" on sale_items
  for all using (
    sale_id in (
      select id from sales
      where shop_id in (select id from shops where owner_id = auth.uid())
    )
  );
