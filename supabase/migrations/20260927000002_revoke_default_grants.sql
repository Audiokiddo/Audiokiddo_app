-- Defence in depth: whatever the project's default exposure setting, anonymous clients get
-- nothing and signed-in users get only what 20260926000001_init.sql grants explicitly.
-- RLS still decides which rows those grants reach.

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

grant select on public.accounts, public.entitlements to authenticated;
grant select on public.admins, public.catalog_versions, public.catalog_pointer to authenticated;
grant select, insert, update, delete on public.packs, public.content_items, public.store_products to authenticated;
grant execute on function public.is_admin() to authenticated;

-- Tables and functions added by later migrations start closed too.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
