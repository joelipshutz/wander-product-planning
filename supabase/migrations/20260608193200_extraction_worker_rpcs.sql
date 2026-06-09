begin;

create or replace function app.extraction_job_result_payload(input_job public.extraction_jobs)
returns jsonb
language sql
stable
set search_path = app, public
as $$
  select jsonb_build_object(
    'extraction_job_id', input_job.id,
    'status', input_job.status,
    'attempt_count', input_job.attempt_count,
    'provider_steps_json', input_job.provider_steps_json,
    'extracted_candidates_json', input_job.extracted_candidates_json,
    'confidence', input_job.confidence,
    'error_code', input_job.error_code,
    'error_message', input_job.error_message
  );
$$;

create or replace function app.extraction_job_worker_payload(input_job public.extraction_jobs)
returns jsonb
language sql
stable
set search_path = app, public
as $$
  select jsonb_build_object(
    'job', jsonb_build_object(
      'id', input_job.id,
      'source_artifact_id', input_job.source_artifact_id,
      'owner_user_id', input_job.owner_user_id,
      'source_type', input_job.source_type,
      'normalized_source_hash', input_job.normalized_source_hash,
      'status', input_job.status,
      'attempt_count', input_job.attempt_count,
      'provider_steps_json', input_job.provider_steps_json,
      'extracted_candidates_json', input_job.extracted_candidates_json,
      'confidence', input_job.confidence,
      'error_code', input_job.error_code,
      'error_message', input_job.error_message
    ),
    'source_artifact', (
      select jsonb_build_object(
        'id', source_artifacts.id,
        'user_id', source_artifacts.user_id,
        'type', source_artifacts.type,
        'original_input', source_artifacts.original_input,
        'normalized_input', source_artifacts.normalized_input,
        'normalized_source_hash', source_artifacts.normalized_source_hash,
        'local_asset_ref', source_artifacts.local_asset_ref,
        'remote_asset_ref', source_artifacts.remote_asset_ref
      )
      from public.source_artifacts
      where source_artifacts.id = input_job.source_artifact_id
    )
  );
$$;

create or replace function app.get_extraction_job(input_job_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = app, public
as $$
declare
  v_viewer_id text := app.current_user_id();
  v_job public.extraction_jobs;
begin
  if v_viewer_id is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into v_job
  from public.extraction_jobs
  where id = input_job_id
    and owner_user_id = v_viewer_id;

  if v_job.id is null then
    raise exception 'extraction_job_not_found';
  end if;

  return app.extraction_job_result_payload(v_job);
end;
$$;

create or replace function public.get_extraction_job(input_job_id uuid)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select app.get_extraction_job(input_job_id);
$$;

create or replace function app.claim_extraction_job(input_job_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = app, public
as $$
declare
  v_viewer_id text := app.current_user_id();
  v_job public.extraction_jobs;
begin
  if v_viewer_id is null then
    raise exception 'not_authenticated';
  end if;

  update public.extraction_jobs
  set status = 'running',
      attempt_count = attempt_count + 1,
      provider_steps_json = provider_steps_json || jsonb_build_array('worker_claimed'),
      error_code = null,
      error_message = null,
      updated_at = now()
  where id = input_job_id
    and owner_user_id = v_viewer_id
    and status in ('pending', 'failed', 'no_place_found')
  returning * into v_job;

  if v_job.id is null then
    select *
      into v_job
    from public.extraction_jobs
    where id = input_job_id
      and owner_user_id = v_viewer_id;
  end if;

  if v_job.id is null then
    raise exception 'extraction_job_not_found';
  end if;

  return app.extraction_job_worker_payload(v_job);
end;
$$;

create or replace function public.claim_extraction_job(input_job_id uuid)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select app.claim_extraction_job(input_job_id);
$$;

create or replace function app.claim_next_extraction_job()
returns jsonb
language plpgsql
security definer
set search_path = app, public
as $$
declare
  v_job public.extraction_jobs;
begin
  with next_job as (
    select id
    from public.extraction_jobs
    where status = 'pending'
       or (status = 'running' and updated_at < now() - interval '5 minutes')
    order by created_at
    for update skip locked
    limit 1
  )
  update public.extraction_jobs
  set status = 'running',
      attempt_count = attempt_count + 1,
      provider_steps_json = provider_steps_json || jsonb_build_array('worker_claimed'),
      error_code = null,
      error_message = null,
      updated_at = now()
  from next_job
  where public.extraction_jobs.id = next_job.id
  returning public.extraction_jobs.* into v_job;

  if v_job.id is null then
    return null;
  end if;

  return app.extraction_job_worker_payload(v_job);
end;
$$;

create or replace function public.claim_next_extraction_job()
returns jsonb
language sql
security definer
set search_path = app, public
as $$
  select app.claim_next_extraction_job();
$$;

create or replace function app.complete_extraction_job(
  input_job_id uuid,
  input_status text,
  input_candidates jsonb default '[]'::jsonb,
  input_confidence double precision default 0,
  input_provider_steps jsonb default '[]'::jsonb,
  input_error_code text default null,
  input_error_message text default null
)
returns jsonb
language plpgsql
security definer
set search_path = app, public
as $$
declare
  v_job public.extraction_jobs;
  v_candidates jsonb := coalesce(input_candidates, '[]'::jsonb);
  v_steps jsonb := coalesce(input_provider_steps, '[]'::jsonb);
begin
  if input_status not in ('needs_confirmation', 'complete', 'failed', 'no_place_found') then
    raise exception 'invalid_extraction_completion_status';
  end if;

  if coalesce(jsonb_typeof(v_candidates), '') <> 'array' then
    raise exception 'invalid_extraction_candidates';
  end if;

  if coalesce(jsonb_typeof(v_steps), '') <> 'array' then
    raise exception 'invalid_extraction_provider_steps';
  end if;

  update public.extraction_jobs
  set status = input_status,
      extracted_candidates_json = v_candidates,
      confidence = greatest(0, least(coalesce(input_confidence, 0), 1)),
      provider_steps_json = case
        when jsonb_array_length(v_steps) = 0 then provider_steps_json
        else v_steps
      end,
      error_code = input_error_code,
      error_message = input_error_message,
      updated_at = now()
  where id = input_job_id
  returning * into v_job;

  if v_job.id is null then
    raise exception 'extraction_job_not_found';
  end if;

  return app.extraction_job_result_payload(v_job);
end;
$$;

create or replace function public.complete_extraction_job(
  input_job_id uuid,
  input_status text,
  input_candidates jsonb default '[]'::jsonb,
  input_confidence double precision default 0,
  input_provider_steps jsonb default '[]'::jsonb,
  input_error_code text default null,
  input_error_message text default null
)
returns jsonb
language sql
security definer
set search_path = app, public
as $$
  select app.complete_extraction_job(
    input_job_id,
    input_status,
    input_candidates,
    input_confidence,
    input_provider_steps,
    input_error_code,
    input_error_message
  );
$$;

comment on function public.get_extraction_job(uuid) is 'Authenticated app RPC to fetch the current user extraction job result.';
comment on function public.claim_extraction_job(uuid) is 'Authenticated app-triggered claim for the current user extraction job.';
comment on function public.claim_next_extraction_job() is 'Service-role extraction worker claim for the next pending job.';
comment on function public.complete_extraction_job(uuid, text, jsonb, double precision, jsonb, text, text) is 'Service-role extraction worker completion RPC.';

revoke all on function app.extraction_job_result_payload(public.extraction_jobs) from public, anon, authenticated;
revoke all on function app.extraction_job_worker_payload(public.extraction_jobs) from public, anon, authenticated;
revoke all on function app.get_extraction_job(uuid) from public, anon;
revoke all on function public.get_extraction_job(uuid) from public, anon;
revoke all on function app.claim_extraction_job(uuid) from public, anon;
revoke all on function public.claim_extraction_job(uuid) from public, anon;
revoke all on function app.claim_next_extraction_job() from public, anon, authenticated;
revoke all on function public.claim_next_extraction_job() from public, anon, authenticated;
revoke all on function app.complete_extraction_job(uuid, text, jsonb, double precision, jsonb, text, text) from public, anon, authenticated;
revoke all on function public.complete_extraction_job(uuid, text, jsonb, double precision, jsonb, text, text) from public, anon, authenticated;

grant execute on function app.get_extraction_job(uuid) to authenticated;
grant execute on function public.get_extraction_job(uuid) to authenticated;
grant execute on function app.claim_extraction_job(uuid) to authenticated;
grant execute on function public.claim_extraction_job(uuid) to authenticated;
grant execute on function app.claim_next_extraction_job() to service_role;
grant execute on function public.claim_next_extraction_job() to service_role;
grant execute on function app.complete_extraction_job(uuid, text, jsonb, double precision, jsonb, text, text) to service_role;
grant execute on function public.complete_extraction_job(uuid, text, jsonb, double precision, jsonb, text, text) to service_role;

commit;
