-- Pack guides (PDF for parents) are free files: anyone may get a signed link.
insert into public.content_files (path, item_id, pack_id, free) values
  ('pdf/detektyw/przewodnik.pdf', 'guide:detektyw', 'detektyw', true),
  ('pdf/slowa-i-wiedza/przewodnik.pdf', 'guide:slowa-i-wiedza', 'slowa-i-wiedza', true),
  ('pdf/wyobraznia/przewodnik.pdf', 'guide:wyobraznia', 'wyobraznia', true)
on conflict (path) do update set item_id = excluded.item_id, pack_id = excluded.pack_id, free = excluded.free;
