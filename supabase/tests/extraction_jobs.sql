begin;

create extension if not exists pgtap;

select plan(9);

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

select * from finish();

rollback;
