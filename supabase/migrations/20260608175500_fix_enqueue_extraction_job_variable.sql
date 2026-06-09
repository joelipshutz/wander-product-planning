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
  v_viewer_id text := app.current_user_id();
  v_artifact_row public.source_artifacts;
  v_job_row public.extraction_jobs;
  v_artifact_type text;
  v_normalized_input text;
  v_normalized_hash text;
  v_source_type text;
  v_provider_steps jsonb;
begin
  if v_viewer_id is null then
    raise exception 'not_authenticated';
  end if;

  if coalesce(jsonb_typeof(input_source_artifact), '') <> 'object' then
    raise exception 'invalid_source_artifact_payload';
  end if;

  if coalesce(jsonb_typeof(input_job), '') <> 'object' then
    raise exception 'invalid_extraction_job_payload';
  end if;

  v_artifact_type := nullif(input_source_artifact->>'type', '');
  v_normalized_input := nullif(input_source_artifact->>'normalized_input', '');
  v_normalized_hash := nullif(input_source_artifact->>'normalized_source_hash', '');
  v_source_type := nullif(input_job->>'source_type', '');
  v_provider_steps := coalesce(input_job->'provider_steps_json', '["queued_for_backend_extraction"]'::jsonb);

  if v_artifact_type is null
     or v_artifact_type not in ('url', 'image', 'text', 'current_location') then
    raise exception 'invalid_source_artifact_type';
  end if;

  if v_normalized_input is null or v_normalized_hash is null then
    raise exception 'invalid_source_artifact_identity';
  end if;

  if v_source_type is null then
    raise exception 'invalid_source_type';
  end if;

  if coalesce(jsonb_typeof(v_provider_steps), '') <> 'array' then
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
    v_viewer_id,
    v_artifact_type,
    coalesce(nullif(input_source_artifact->>'original_input', ''), v_normalized_input),
    v_normalized_input,
    v_normalized_hash,
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
  returning * into v_artifact_row;

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
    v_artifact_row.id,
    v_viewer_id,
    v_source_type,
    v_normalized_hash,
    'pending',
    0,
    v_provider_steps,
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
  returning * into v_job_row;

  return jsonb_build_object(
    'source_artifact_id', v_artifact_row.id,
    'extraction_job_id', v_job_row.id,
    'status', v_job_row.status,
    'attempt_count', v_job_row.attempt_count
  );
end;
$$;

commit;
