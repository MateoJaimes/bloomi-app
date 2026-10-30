-- Bloomi initial schema for Supabase PostgreSQL.
-- Apply to a NEW/empty Bloomi project using the Supabase SQL Editor.
-- This script is intentionally not destructive and does not seed fake users.

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;

create type public.blood_type as enum ('O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+');
create type public.document_type as enum ('cc', 'ce', 'passport', 'other');
create type public.donation_status as enum ('scheduled', 'confirmed', 'rejected', 'cancelled');
create type public.institution_role as enum ('owner', 'admin', 'staff');
create type public.reward_status as enum ('draft', 'active', 'paused', 'archived');
create type public.redemption_status as enum ('pending', 'approved', 'delivered', 'cancelled', 'expired');
create type public.questionnaire_status as enum ('draft', 'submitted', 'reviewed');
create type public.points_entry_type as enum ('donation', 'redemption', 'adjustment', 'reversal');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  second_name text,
  last_name text,
  second_last_name text,
  phone text,
  birth_date date,
  blood_type public.blood_type,
  gender text,
  address text,
  city text,
  department text,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_first_name_length check (first_name is null or char_length(first_name) between 1 and 100),
  constraint profiles_second_name_length check (second_name is null or char_length(second_name) between 1 and 100),
  constraint profiles_last_name_length check (last_name is null or char_length(last_name) between 1 and 100),
  constraint profiles_second_last_name_length check (second_last_name is null or char_length(second_last_name) between 1 and 100)
);

-- Self-reported medical details are separated from the general profile and are
-- visible only to the authenticated account that owns them.
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

-- Store only a keyed HMAC of a normalized document number, never the raw ID.
-- The HMAC secret belongs only in the NestJS environment.
create table public.identity_documents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  document_type public.document_type not null,
  document_hash text not null unique,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint identity_documents_hash_format check (document_hash ~ '^[a-f0-9]{64}$')
);

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  display_name text not null,
  tax_id_hash text unique,
  contact_email text,
  contact_phone text,
  status text not null default 'pending' check (status in ('pending', 'active', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.institution_memberships (
  institution_id uuid not null references public.institutions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.institution_role not null default 'staff',
  created_at timestamptz not null default now(),
  primary key (institution_id, user_id)
);

create table public.donation_centers (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete restrict,
  name text not null,
  description text,
  address text not null,
  city text not null,
  department text not null,
  latitude double precision,
  longitude double precision,
  phone text,
  email text,
  opening_hours jsonb not null default '{}'::jsonb,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint donation_centers_latitude check (latitude is null or latitude between -90 and 90),
  constraint donation_centers_longitude check (longitude is null or longitude between -180 and 180)
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  center_id uuid not null references public.donation_centers(id) on delete restrict,
  status public.donation_status not null default 'scheduled',
  scheduled_at timestamptz,
  donated_at timestamptz,
  volume_ml integer,
  institution_reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint donations_volume_positive check (volume_ml is null or volume_ml > 0),
  constraint donations_confirmed_has_date check (status <> 'confirmed' or donated_at is not null)
);

create table public.points_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete restrict,
  entry_type public.points_entry_type not null,
  points integer not null check (points <> 0),
  donation_id uuid references public.donations(id) on delete restrict,
  redemption_id uuid,
  description text not null,
  actor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint points_ledger_reference check (
    (entry_type = 'donation' and donation_id is not null and points > 0) or
    (entry_type = 'redemption' and redemption_id is not null and points < 0) or
    (entry_type in ('adjustment', 'reversal'))
  )
);

create unique index points_ledger_donation_once on public.points_ledger(donation_id)
  where entry_type = 'donation';

create table public.rewards (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references public.institutions(id) on delete set null,
  name text not null,
  description text not null default '',
  points_cost integer not null check (points_cost > 0),
  inventory integer check (inventory is null or inventory >= 0),
  terms text,
  image_path text,
  status public.reward_status not null default 'draft',
  available_from timestamptz,
  available_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rewards_availability_dates check (available_until is null or available_from is null or available_until > available_from)
);

create table public.reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  reward_id uuid not null references public.rewards(id) on delete restrict,
  points_spent integer not null check (points_spent > 0),
  status public.redemption_status not null default 'pending',
  redemption_code text not null unique default upper(replace(gen_random_uuid()::text, '-', '')),
  expires_at timestamptz,
  fulfilled_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.points_ledger add constraint points_ledger_redemption_fk
  foreign key (redemption_id) references public.reward_redemptions(id) on delete restrict;
create unique index points_ledger_redemption_once on public.points_ledger(redemption_id)
  where entry_type = 'redemption';

create table public.health_questionnaire_versions (
  id uuid primary key default gen_random_uuid(),
  version text not null unique,
  language text not null default 'es-CO',
  status text not null default 'draft' check (status in ('draft', 'active', 'retired')),
  effective_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.health_questions (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.health_questionnaire_versions(id) on delete cascade,
  code text not null,
  category text not null,
  prompt text not null,
  answer_type text not null check (answer_type in ('boolean', 'text', 'date', 'choice', 'multi_choice')),
  options jsonb not null default '[]'::jsonb,
  is_required boolean not null default false,
  display_order integer not null,
  created_at timestamptz not null default now(),
  unique (version_id, code),
  unique (version_id, display_order)
);

create table public.health_questionnaire_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  version_id uuid not null references public.health_questionnaire_versions(id) on delete restrict,
  status public.questionnaire_status not null default 'draft',
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewer_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.health_questionnaire_answers (
  submission_id uuid not null references public.health_questionnaire_submissions(id) on delete cascade,
  question_id uuid not null references public.health_questions(id) on delete restrict,
  answer jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (submission_id, question_id)
);

create index donation_centers_city_department_idx on public.donation_centers(city, department) where is_published;
create index donation_centers_institution_idx on public.donation_centers(institution_id);
create index donations_user_created_idx on public.donations(user_id, created_at desc);
create index donations_center_status_idx on public.donations(center_id, status, donated_at desc);
create index donations_created_by_idx on public.donations(created_by);
create index points_ledger_user_created_idx on public.points_ledger(user_id, created_at desc);
create index points_ledger_actor_idx on public.points_ledger(actor_user_id);
create index reward_redemptions_user_created_idx on public.reward_redemptions(user_id, created_at desc);
create index reward_redemptions_reward_idx on public.reward_redemptions(reward_id);
create index reward_redemptions_fulfilled_by_idx on public.reward_redemptions(fulfilled_by);
create index rewards_institution_idx on public.rewards(institution_id);
create index health_submissions_user_created_idx on public.health_questionnaire_submissions(user_id, created_at desc);
create index health_submissions_version_idx on public.health_questionnaire_submissions(version_id);
create index health_submissions_reviewer_idx on public.health_questionnaire_submissions(reviewer_user_id);
create index health_answers_question_idx on public.health_questionnaire_answers(question_id);
create index institution_memberships_user_idx on public.institution_memberships(user_id, institution_id);

create or replace function private.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.create_user_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

create or replace function private.record_confirmed_donation_points()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.user_id is distinct from new.user_id or old.center_id is distinct from new.center_id then
    raise exception 'No se puede cambiar el donante o centro de una donación existente';
  end if;
  if old.status <> 'confirmed' and new.status = 'confirmed' then
    insert into public.points_ledger (user_id, entry_type, points, donation_id, description, actor_user_id)
    values (new.user_id, 'donation', 100, new.id, 'Puntos por donación confirmada', new.created_by)
    on conflict (donation_id) where entry_type = 'donation' do nothing;
  elsif old.status = 'confirmed' and new.status <> 'confirmed' then
    raise exception 'Una donación confirmada no se puede cambiar de estado';
  end if;
  return new;
end;
$$;

create or replace function private.validate_and_post_redemption()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_cost integer;
  v_inventory integer;
  v_balance bigint;
begin
  if (select auth.uid()) is distinct from new.user_id then
    raise exception 'No puedes canjear puntos para otra cuenta' using errcode = '42501';
  end if;

  -- Serialize redemptions per user so simultaneous requests cannot overspend.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(new.user_id::text, 0));
  select r.points_cost, r.inventory into v_cost, v_inventory
  from public.rewards r
  where r.id = new.reward_id and r.status = 'active'
    and (r.available_from is null or r.available_from <= now())
    and (r.available_until is null or r.available_until > now())
  for update;
  if not found then raise exception 'La recompensa no está disponible' using errcode = 'P0002'; end if;
  if new.points_spent <> v_cost then raise exception 'El costo de puntos no coincide' using errcode = '23514'; end if;
  if v_inventory is not null and v_inventory <= 0 then raise exception 'Recompensa agotada' using errcode = 'P0001'; end if;

  select coalesce(sum(l.points), 0) into v_balance
  from public.points_ledger l where l.user_id = new.user_id;
  if v_balance < v_cost then raise exception 'Saldo insuficiente' using errcode = 'P0001'; end if;

  if v_inventory is not null then
    update public.rewards set inventory = inventory - 1 where id = new.reward_id;
  end if;

  insert into public.points_ledger (user_id, entry_type, points, redemption_id, description)
  values (new.user_id, 'redemption', -new.points_spent, new.id, 'Canje de recompensa');
  return new;
end;
$$;

create trigger auth_user_profile_created after insert on auth.users
for each row execute function private.create_user_profile();

do $$
declare t text;
begin
  foreach t in array array['profiles','medical_profiles','institutions','donation_centers','donations','rewards','reward_redemptions','health_questionnaire_submissions','health_questionnaire_answers'] loop
    execute format('create trigger %I before update on public.%I for each row execute function private.set_updated_at()', t || '_set_updated_at', t);
  end loop;
end;
$$;

create trigger donations_award_points before update on public.donations
for each row execute function private.record_confirmed_donation_points();
create trigger reward_redemptions_validate after insert on public.reward_redemptions
for each row execute function private.validate_and_post_redemption();

alter table public.profiles enable row level security;
alter table public.medical_profiles enable row level security;
alter table public.identity_documents enable row level security;
alter table public.institutions enable row level security;
alter table public.institution_memberships enable row level security;
alter table public.donation_centers enable row level security;
alter table public.donations enable row level security;
alter table public.points_ledger enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_redemptions enable row level security;
alter table public.health_questionnaire_versions enable row level security;
alter table public.health_questions enable row level security;
alter table public.health_questionnaire_submissions enable row level security;
alter table public.health_questionnaire_answers enable row level security;

create policy profiles_select_self on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_insert_self on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy profiles_update_self on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy medical_profiles_select_self on public.medical_profiles for select to authenticated using (user_id = (select auth.uid()));
create policy medical_profiles_insert_self on public.medical_profiles for insert to authenticated with check (user_id = (select auth.uid()));
create policy medical_profiles_update_self on public.medical_profiles for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy institutions_select_active on public.institutions for select to authenticated using (status = 'active');
create policy institution_memberships_select_self on public.institution_memberships for select to authenticated using (user_id = (select auth.uid()));

create policy centers_select_published on public.donation_centers for select to anon, authenticated using (is_published);
create policy centers_staff_insert on public.donation_centers for insert to authenticated
  with check (exists (select 1 from public.institution_memberships m where m.institution_id = donation_centers.institution_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')));
create policy centers_staff_update on public.donation_centers for update to authenticated
  using (exists (select 1 from public.institution_memberships m where m.institution_id = donation_centers.institution_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.institution_memberships m where m.institution_id = donation_centers.institution_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')));
create policy centers_staff_delete on public.donation_centers for delete to authenticated
  using (exists (select 1 from public.institution_memberships m where m.institution_id = donation_centers.institution_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')));

create policy donations_select_own on public.donations for select to authenticated using (user_id = (select auth.uid()));
create policy donations_insert_institution on public.donations for insert to authenticated
  with check (status = 'scheduled' and created_by = (select auth.uid()) and exists (select 1 from public.donation_centers c join public.institution_memberships m on m.institution_id = c.institution_id where c.id = donations.center_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')));
create policy donations_update_institution on public.donations for update to authenticated
  using (exists (select 1 from public.donation_centers c join public.institution_memberships m on m.institution_id = c.institution_id where c.id = donations.center_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')))
  with check (exists (select 1 from public.donation_centers c join public.institution_memberships m on m.institution_id = c.institution_id where c.id = donations.center_id and m.user_id = (select auth.uid()) and m.role in ('owner','admin','staff')));

create policy points_select_own on public.points_ledger for select to authenticated using (user_id = (select auth.uid()));
create policy rewards_select_active on public.rewards for select to anon, authenticated using (status = 'active' and (available_from is null or available_from <= now()) and (available_until is null or available_until > now()));
create policy redemptions_select_own on public.reward_redemptions for select to authenticated using (user_id = (select auth.uid()));
create policy redemptions_insert_own on public.reward_redemptions for insert to authenticated with check (user_id = (select auth.uid()));

create policy questionnaire_versions_select_active on public.health_questionnaire_versions for select to authenticated using (status = 'active');
create policy questions_select_active on public.health_questions for select to authenticated using (exists (select 1 from public.health_questionnaire_versions v where v.id = version_id and v.status = 'active'));
create policy questionnaire_submissions_select_own on public.health_questionnaire_submissions for select to authenticated using (user_id = (select auth.uid()));
create policy questionnaire_submissions_insert_own on public.health_questionnaire_submissions for insert to authenticated with check (user_id = (select auth.uid()) and status = 'draft' and exists (select 1 from public.health_questionnaire_versions v where v.id = version_id and v.status = 'active'));
create policy questionnaire_submissions_update_own_draft on public.health_questionnaire_submissions for update to authenticated using (user_id = (select auth.uid()) and status = 'draft') with check (user_id = (select auth.uid()) and status in ('draft','submitted'));
create policy questionnaire_answers_select_own on public.health_questionnaire_answers for select to authenticated using (exists (select 1 from public.health_questionnaire_submissions s where s.id = submission_id and s.user_id = (select auth.uid())));
create policy questionnaire_answers_insert_own on public.health_questionnaire_answers for insert to authenticated with check (exists (select 1 from public.health_questionnaire_submissions s where s.id = submission_id and s.user_id = (select auth.uid()) and s.status = 'draft'));
create policy questionnaire_answers_update_own on public.health_questionnaire_answers for update to authenticated using (exists (select 1 from public.health_questionnaire_submissions s where s.id = submission_id and s.user_id = (select auth.uid()) and s.status = 'draft')) with check (exists (select 1 from public.health_questionnaire_submissions s where s.id = submission_id and s.user_id = (select auth.uid()) and s.status = 'draft'));

-- Explicit least-privilege grants; RLS then scopes every row.
revoke all on all tables in schema public from anon, authenticated;
grant select on public.donation_centers, public.rewards to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.medical_profiles to authenticated;
grant select on public.institutions, public.institution_memberships, public.donations, public.points_ledger, public.reward_redemptions to authenticated;
grant insert, update on public.donations to authenticated;
grant insert (user_id, reward_id, points_spent) on public.reward_redemptions to authenticated;
grant select on public.health_questionnaire_versions, public.health_questions, public.health_questionnaire_submissions, public.health_questionnaire_answers to authenticated;
grant insert, update on public.health_questionnaire_submissions, public.health_questionnaire_answers to authenticated;
grant usage, select on sequence public.points_ledger_id_seq to authenticated;
grant all on all tables in schema public to service_role;

-- Private user avatars and public reward artwork. Institution uploads are server-only for now.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('bloomi-profile-avatars', 'bloomi-profile-avatars', false, 5242880, array['image/jpeg','image/png','image/webp']),
  ('bloomi-reward-images', 'bloomi-reward-images', true, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy bloomi_avatar_select_own on storage.objects for select to authenticated
  using (bucket_id = 'bloomi-profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy bloomi_avatar_insert_own on storage.objects for insert to authenticated
  with check (bucket_id = 'bloomi-profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy bloomi_avatar_update_own on storage.objects for update to authenticated
  using (bucket_id = 'bloomi-profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'bloomi-profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy bloomi_avatar_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'bloomi-profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy bloomi_reward_images_read_public on storage.objects for select to anon, authenticated
  using (bucket_id = 'bloomi-reward-images');

-- Internal trigger functions must never be exposed as callable RPCs.
revoke all on function private.set_updated_at() from public, anon, authenticated;
revoke all on function private.create_user_profile() from public, anon, authenticated;
revoke all on function private.record_confirmed_donation_points() from public, anon, authenticated;
revoke all on function private.validate_and_post_redemption() from public, anon, authenticated;

commit;
