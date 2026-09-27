-- audiokiddo.pl (WooCommerce) products → app scopes. IDs from the shop admin, 2026-09-27.
insert into public.store_products (product_ref, scopes) values
  ('woo:372',  '{pack:wyobraznia}'),                                   -- Pakiet Wyobraźnia, 10 audiozabaw
  ('woo:373',  '{pack:slowa-i-wiedza}'),                               -- Pakiet Słowa i Wiedza, 10 audiozabaw
  ('woo:7339', '{pack:detektyw}'),                                     -- Pakiet Detektywa, 5 audiozabaw + karty pracy
  ('woo:371',  '{pack:wyobraznia,pack:slowa-i-wiedza}'),               -- Zestaw dwóch zabaw
  ('woo:6235', '{pack:wyobraznia,pack:slowa-i-wiedza,pack:detektyw}')  -- Zestaw trzech zabaw
on conflict (product_ref) do update set scopes = excluded.scopes;
