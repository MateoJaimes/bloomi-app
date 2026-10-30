alter table public.profiles
  add column second_name text,
  add column second_last_name text;

alter table public.profiles
  add constraint profiles_second_name_length
    check (second_name is null or char_length(second_name) between 1 and 100),
  add constraint profiles_second_last_name_length
    check (second_last_name is null or char_length(second_last_name) between 1 and 100);
