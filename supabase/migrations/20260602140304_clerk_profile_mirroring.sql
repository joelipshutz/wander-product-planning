-- Clerk profile mirroring support.
-- The Edge Function verifies Svix signatures; Postgres owns idempotency, ordering, and handle allocation.

alter table public.profiles
  add column if not exists clerk_updated_at timestamptz,
  add column if not exists last_clerk_event_id text;

create table if not exists public.clerk_webhook_events (
  svix_id text primary key,
  event_type text not null,
  clerk_user_id text not null,
  event_timestamp timestamptz not null,
  processed_at timestamptz not null default now()
);

create table if not exists public.clerk_profile_mirror_state (
  clerk_user_id text primary key,
  last_event_id text not null,
  last_event_type text not null,
  last_event_timestamp timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table public.clerk_webhook_events enable row level security;
alter table public.clerk_profile_mirror_state enable row level security;

create or replace function app.normalize_profile_handle(raw_handle text, fallback_user_id text)
returns text
language sql
immutable
as $$
  with normalized as (
    select trim(both '_' from regexp_replace(lower(coalesce(nullif(raw_handle, ''), 'user_' || right(fallback_user_id, 8))), '[^a-z0-9_]+', '_', 'g')) as value
  )
  select case
    when length(value) >= 2 then value
    else 'user_' || lower(regexp_replace(right(fallback_user_id, 8), '[^a-z0-9_]+', '', 'g'))
  end
  from normalized
$$;

create or replace function app.available_profile_handle(base_handle text, profile_id text)
returns text
language plpgsql
stable
security definer
set search_path = public, app
as $$
declare
  candidate text := app.normalize_profile_handle(base_handle, profile_id);
  suffix_seed text := lower(regexp_replace(right(profile_id, 6), '[^a-z0-9_]+', '', 'g'));
  attempt integer := 0;
begin
  if not exists (
    select 1
    from public.profiles p
    where p.search_handle = lower(candidate)
      and p.id <> profile_id
      and p.deleted_at is null
  ) then
    return candidate;
  end if;

  candidate := left(app.normalize_profile_handle(base_handle, profile_id), 54) || '_' || suffix_seed;

  while exists (
    select 1
    from public.profiles p
    where p.search_handle = lower(candidate)
      and p.id <> profile_id
      and p.deleted_at is null
  ) loop
    attempt := attempt + 1;
    candidate := left(app.normalize_profile_handle(base_handle, profile_id), 50) || '_' || suffix_seed || '_' || attempt::text;
  end loop;

  return candidate;
end;
$$;

create or replace function app.mirror_clerk_profile(
  event_id text,
  event_type text,
  event_timestamp timestamptz,
  profile_id text,
  desired_handle text,
  desired_display_name text,
  desired_avatar_url text
)
returns jsonb
language plpgsql
security definer
set search_path = public, app
as $$
declare
  existing_profile public.profiles;
  existing_state public.clerk_profile_mirror_state;
  allocated_handle text;
begin
  if event_id is null or event_id = '' then
    raise exception 'missing_event_id';
  end if;

  if profile_id is null or profile_id = '' then
    raise exception 'missing_profile_id';
  end if;

  insert into public.clerk_webhook_events (svix_id, event_type, clerk_user_id, event_timestamp)
  values (event_id, event_type, profile_id, event_timestamp)
  on conflict (svix_id) do nothing;

  if not found then
    return jsonb_build_object('action', 'duplicate_ignored', 'profile_id', profile_id);
  end if;

  select *
  into existing_state
  from public.clerk_profile_mirror_state s
  where s.clerk_user_id = profile_id
  for update;

  if existing_state.clerk_user_id is not null
    and event_timestamp < existing_state.last_event_timestamp then
    return jsonb_build_object('action', 'stale_ignored', 'profile_id', profile_id);
  end if;

  insert into public.clerk_profile_mirror_state (
    clerk_user_id,
    last_event_id,
    last_event_type,
    last_event_timestamp
  )
  values (
    profile_id,
    event_id,
    event_type,
    event_timestamp
  )
  on conflict (clerk_user_id) do update set
    last_event_id = excluded.last_event_id,
    last_event_type = excluded.last_event_type,
    last_event_timestamp = excluded.last_event_timestamp,
    updated_at = now();

  select *
  into existing_profile
  from public.profiles p
  where p.id = profile_id
  for update;

  if event_type = 'user.deleted' then
    update public.profiles
    set
      deleted_at = coalesce(deleted_at, now()),
      clerk_updated_at = event_timestamp,
      last_clerk_event_id = event_id,
      updated_at = now()
    where id = profile_id;

    return jsonb_build_object('action', 'soft_deleted', 'profile_id', profile_id);
  end if;

  if event_type not in ('user.created', 'user.updated') then
    return jsonb_build_object('action', 'ignored', 'profile_id', profile_id, 'event_type', event_type);
  end if;

  allocated_handle := case
    when existing_profile.id is not null and existing_profile.deleted_at is null then existing_profile.handle
    else app.available_profile_handle(desired_handle, profile_id)
  end;

  insert into public.profiles (
    id,
    handle,
    display_name,
    avatar_url,
    deleted_at,
    clerk_updated_at,
    last_clerk_event_id
  )
  values (
    profile_id,
    allocated_handle,
    coalesce(nullif(desired_display_name, ''), allocated_handle),
    desired_avatar_url,
    null,
    event_timestamp,
    event_id
  )
  on conflict (id) do update set
    handle = allocated_handle,
    display_name = excluded.display_name,
    avatar_url = excluded.avatar_url,
    deleted_at = null,
    clerk_updated_at = excluded.clerk_updated_at,
    last_clerk_event_id = excluded.last_clerk_event_id,
    updated_at = now();

  return jsonb_build_object('action', 'upserted', 'profile_id', profile_id, 'handle', allocated_handle);
end;
$$;

grant execute on function app.mirror_clerk_profile(text, text, timestamptz, text, text, text, text) to service_role;
