-- Optional fictitious records for manual integration tests. Safe to run more than once.
-- These are not real centers, rewards, institutions or medical questions.

insert into public.institutions (id, legal_name, display_name, status)
values ('10000000-0000-4000-8000-000000000001', 'Institución de prueba Bloomi S.A.S.', 'Institución Demo Bloomi', 'active')
on conflict (id) do nothing;

insert into public.donation_centers (id, institution_id, name, description, address, city, department, latitude, longitude, phone, is_published)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'Centro de prueba Bloomi',
  'Registro ficticio para verificar la API. No es un punto real de donación.',
  'Dirección de prueba', 'Bogotá', 'Cundinamarca', 4.7110, -74.0721, null, true
)
on conflict (id) do nothing;

insert into public.rewards (id, name, description, points_cost, inventory, terms, status)
values
  ('30000000-0000-4000-8000-000000000001', 'Recompensa de prueba: botella', 'Artículo ficticio para probar la consulta del catálogo.', 100, 10, 'Registro de demostración; no reclamable fuera de pruebas.', 'active'),
  ('30000000-0000-4000-8000-000000000002', 'Recompensa de prueba: café', 'Artículo ficticio para probar saldos insuficientes.', 250, 10, 'Registro de demostración; no reclamable fuera de pruebas.', 'active')
on conflict (id) do nothing;

insert into public.health_questionnaire_versions (id, version, language, status, effective_at)
values ('40000000-0000-4000-8000-000000000001', 'demo-0.1', 'es-CO', 'active', now())
on conflict (id) do nothing;

insert into public.health_questions (id, version_id, code, category, prompt, answer_type, options, is_required, display_order)
values (
  '50000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000001',
  'demo_acknowledgement', 'demostracion',
  'Pregunta técnica de prueba: ¿confirmas que esta información es ficticia?',
  'boolean', '[]'::jsonb, true, 1
)
on conflict (id) do nothing;
