create table public.medical_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  medications text not null default '',
  conditions text not null default '',
  allergies text not null default '',
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint medical_profiles_medications_length check (char_length(medications) <= 4000),
  constraint medical_profiles_conditions_length check (char_length(conditions) <= 4000),
  constraint medical_profiles_allergies_length check (char_length(allergies) <= 4000)
);

create trigger medical_profiles_set_updated_at
before update on public.medical_profiles
for each row execute function private.set_updated_at();

alter table public.medical_profiles enable row level security;
create policy medical_profiles_select_self on public.medical_profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy medical_profiles_insert_self on public.medical_profiles
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy medical_profiles_update_self on public.medical_profiles
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.medical_profiles from anon, authenticated;
grant select, insert, update on public.medical_profiles to authenticated;
grant all on public.medical_profiles to service_role;
