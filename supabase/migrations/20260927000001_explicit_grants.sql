-- The project is created with "Automatically expose new tables" off, so nothing is granted
-- by default: every privilege the app, Studio and server functions need is listed here.

-- Server functions (service role key) read and write everything; RLS does not apply to them.
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;

-- Policies call is_admin() as the signed-in user.
grant execute on function public.is_admin() to authenticated;
