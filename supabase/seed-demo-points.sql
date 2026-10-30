-- DEVELOPMENT ONLY. Replace the email with the account you just registered.
-- Never run this in production and never treat the balance as earned points.
insert into public.points_ledger (user_id, entry_type, points, description)
select u.id, 'adjustment', 100, 'Saldo ficticio para prueba local'
from auth.users u
where lower(u.email) = lower('REEMPLAZAR_POR_CORREO_DE_PRUEBA@example.com')
  and not exists (
    select 1 from public.points_ledger l
    where l.user_id = u.id and l.description = 'Saldo ficticio para prueba local'
  );
