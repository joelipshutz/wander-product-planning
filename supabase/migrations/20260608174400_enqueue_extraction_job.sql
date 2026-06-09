begin;

create or replace function app.enqueue_extraction_job(
  input_source_artifact jsonb,
  input_job jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = app, public
as $$
declare
  viewer_id text := app.current_user_id();
  artifact_row public.source_artifacts;
  job_row public.extraction_jobs;
  artifact_type text;
  normalized_input text;
  normalized_hash text;
  source_type text;
  provider_steps jsonb;
begin
  if viewer_id is null then
    raise exception 'not_authenticated';
  end if;

  if coalesce(jsonb_typeof(input_source_artifact), '') <> 'object' then
    raise exception 'invalid_source_artifact_payload';
  end if;

  if coalesce(jsonb_typeof(input_job), '') <> 'object' then
    raise exception 'invalid_extraction_job_payload';
  end if;

  artifact_type := nullif(input_source_artifact->>'type', '');
  normalized_input := nullif(input_source_artifact->>'normalized_input', '');
  normalized_hash := nullif(input_source_artifact->>'normalized_source_hash', '');
  source_type := nullif(input_job->>'source_type', '');
  provider_steps := coalesce(input_job->'provider_steps_json', '["queued_for_backend_extraction"]'::jsonb);

  if artifact_type is null
     or artifact_type not in ('url', 'image', 'text', 'current_location') then
    raise exception 'invalid_source_artifact_type';
  end if;

  if normalized_input is null or normalized_hash is null then
    raise exception 'invalid_source_artifact_identity';
  end if;

  if source_type is null then
    raise exception 'invalid_source_type';
  end if;

  if coalesce(jsonb_typeof(provider_steps), '') <> 'array' then
    raise exception 'invalid_provider_steps';
  end if;

  insert into public.source_artifacts (
    user_id,
    type,
    original_input,
    normalized_input,
    normalized_source_hash,
    local_asset_ref,
    remote_asset_ref,
    deleted_at
  )
  values (
    viewer_id,
    artifact_type,
    coalesce(nullif(input_source_artifact->>'original_input', ''), normalized_input),
    normalized_input,
    normalized_hash,
    nullif(input_source_artifact->>'local_asset_ref', ''),
    nullif(input_source_artifact->>'remote_asset_ref', ''),
    null
  )
  on conflict (user_id, type, normalized_source_hash)
  do update set
    original_input = excluded.original_input,
    normalized_input = excluded.normalized_input,
    local_asset_ref = coalesce(public.source_artifacts.local_asset_ref, excluded.local_asset_ref),
    remote_asset_ref = coalesce(public.source_artifacts.remote_asset_ref, excluded.remote_asset_ref),
    deleted_at = null
  returning * into artifact_row;

  insert into public.extraction_jobs (
    source_artifact_id,
    owner_user_id,
    source_type,
    normalized_source_hash,
    status,
    attempt_count,
    provider_steps_json,
    extracted_candidates_json,
    confidence,
    error_code,
    error_message
  )
  values (
    artifact_row.id,
    viewer_id,
    source_type,
    normalized_hash,
    'pending',
    0,
    provider_steps,
    '[]'::jsonb,
    0,
    null,
    null
  )
  on conflict (owner_user_id, source_type, normalized_source_hash)
  do update set
    source_artifact_id = excluded.source_artifact_id,
    status = case
      when public.extraction_jobs.status in ('failed', 'no_place_found') then 'pending'
      else public.extraction_jobs.status
    end,
    attempt_count = case
      when public.extraction_jobs.status in ('failed', 'no_place_found') then public.extraction_jobs.attempt_count + 1
      else public.extraction_jobs.attempt_count
    end,
    provider_steps_json = case
      when public.extraction_jobs.status in ('failed', 'no_place_found') then excluded.provider_steps_json
      else public.extraction_jobs.provider_steps_json
    end,
    error_code = case
      when public.extraction_jobs.status in ('failed', 'no_place_found') then null
      else public.extraction_jobs.error_code
    end,
    error_message = case
      when public.extraction_jobs.status in ('failed', 'no_place_found') then null
      else public.extraction_jobs.error_message
    end,
    updated_at = now()
  returning * into job_row;

  return jsonb_build_object(
    'source_artifact_id', artifact_row.id,
    'extraction_job_id', job_row.id,
    'status', job_row.status,
    'attempt_count', job_row.attempt_count
  );
end;
$$;

create or replace function public.enqueue_extraction_job(
  input_source_artifact jsonb,
  input_job jsonb
)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select app.enqueue_extraction_job(input_source_artifact, input_job);
$$;

comment on function app.enqueue_extraction_job(jsonb, jsonb) is 'Idempotently upserts a source artifact and extraction job for the authenticated user.';
comment on function public.enqueue_extraction_job(jsonb, jsonb) is 'PostgREST wrapper for app.enqueue_extraction_job.';

revoke all on function app.enqueue_extraction_job(jsonb, jsonb) from public, anon;
revoke all on function public.enqueue_extraction_job(jsonb, jsonb) from public, anon;

grant execute on function app.enqueue_extraction_job(jsonb, jsonb) to authenticated;
grant execute on function public.enqueue_extraction_job(jsonb, jsonb) to authenticated;

commit;
