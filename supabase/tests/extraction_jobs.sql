begin;

create extension if not exists pgtap;

select plan(16);

insert into public.profiles (id, handle, display_name)
values ('user_extract', 'extractor', 'Extractor');

set local role authenticated;
select set_config('request.jwt.claim.sub', 'user_extract', true);

select ok(
  (public.enqueue_extraction_job(
    '{
      "type": "url",
      "original_input": "https://maps.app.goo.gl/example",
      "normalized_input": "https://maps.app.goo.gl/example",
      "normalized_source_hash": "hash_maps_example"
    }'::jsonb,
    '{
      "source_type": "link",
      "provider_steps_json": ["queued_for_backend_extraction"]
    }'::jsonb
  )->>'extraction_job_id') is not null,
  'enqueue_extraction_job returns a job id'
);

select is(
  (select count(*)::int from public.source_artifacts),
  1,
  'first enqueue creates one source artifact'
);

select is(
  (select count(*)::int from public.extraction_jobs),
  1,
  'first enqueue creates one extraction job'
);

select is(
  (public.enqueue_extraction_job(
    '{
      "type": "url",
      "original_input": "https://maps.app.goo.gl/example",
      "normalized_input": "https://maps.app.goo.gl/example",
      "normalized_source_hash": "hash_maps_example"
    }'::jsonb,
    '{
      "source_type": "link",
      "provider_steps_json": ["queued_for_backend_extraction"]
    }'::jsonb
  )->>'extraction_job_id'),
  (select id::text from public.extraction_jobs limit 1),
  'duplicate enqueue returns the existing job'
);

select is(
  (select count(*)::int from public.source_artifacts),
  1,
  'duplicate enqueue does not duplicate source artifacts'
);

select is(
  (select count(*)::int from public.extraction_jobs),
  1,
  'duplicate enqueue does not duplicate extraction jobs'
);

update public.extraction_jobs
set status = 'failed',
    attempt_count = 2,
    error_code = 'provider_timeout',
    error_message = 'provider timed out'
where owner_user_id = 'user_extract';

select is(
  (public.enqueue_extraction_job(
    '{
      "type": "url",
      "original_input": "https://maps.app.goo.gl/example",
      "normalized_input": "https://maps.app.goo.gl/example",
      "normalized_source_hash": "hash_maps_example"
    }'::jsonb,
    '{
      "source_type": "link",
      "provider_steps_json": ["queued_for_backend_extraction", "retry_after_failure"]
    }'::jsonb
  )->>'status'),
  'pending',
  'failed jobs are reset to pending on retry'
);

select is(
  (select attempt_count::int from public.extraction_jobs where owner_user_id = 'user_extract'),
  3,
  'retry increments attempt count for failed jobs'
);

select is(
  (select error_code from public.extraction_jobs where owner_user_id = 'user_extract'),
  null::text,
  'retry clears failed job error code'
);

select is(
  (public.claim_extraction_job((select id from public.extraction_jobs where owner_user_id = 'user_extract'))->'job'->>'status'),
  'running',
  'authenticated owner can claim a pending extraction job'
);

select is(
  (select attempt_count::int from public.extraction_jobs where owner_user_id = 'user_extract'),
  4,
  'claim increments worker attempt count'
);

reset role;

select is(
  (public.complete_extraction_job(
    (select id from public.extraction_jobs where owner_user_id = 'user_extract'),
    'needs_confirmation',
    '[
      {
        "id": "extracted_hash_maps_example",
        "name": "Maru Coffee",
        "category": "coffee",
        "latitude": 34.0836,
        "longitude": -118.3614,
        "source_provider": "google_maps_link",
        "source_provider_place_id": "https://google.com/maps/place/Maru+Coffee",
        "confidence": 0.86
      }
    ]'::jsonb,
    0.86,
    '["worker_started", "google_maps_coordinate_candidate"]'::jsonb,
    null,
    null
  )->>'status'),
  'needs_confirmation',
  'service worker can complete a claimed job with confirmation candidates'
);

select is(
  (select count(*)::int from public.places),
  0,
  'extraction completion does not auto-create canonical places'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', 'user_extract', true);

select is(
  (public.get_extraction_job((select id from public.extraction_jobs where owner_user_id = 'user_extract'))->>'status'),
  'needs_confirmation',
  'owner can fetch completed extraction job status'
);

select is(
  jsonb_array_length(public.get_extraction_job((select id from public.extraction_jobs where owner_user_id = 'user_extract'))->'extracted_candidates_json'),
  1,
  'owner can fetch extracted candidates'
);

select is(
  (public.get_extraction_job((select id from public.extraction_jobs where owner_user_id = 'user_extract'))->>'confidence')::double precision,
  0.86::double precision,
  'owner can fetch extraction confidence'
);

select * from finish();

rollback;
