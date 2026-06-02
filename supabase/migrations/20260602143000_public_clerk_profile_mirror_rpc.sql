begin;

create or replace function public.mirror_clerk_profile(
  event_id text,
  event_type text,
  event_timestamp timestamptz,
  profile_id text,
  desired_handle text default null,
  desired_display_name text default null,
  desired_avatar_url text default null
)
returns jsonb
language sql
security definer
set search_path = app, public
as $$
  select app.mirror_clerk_profile(
    event_id,
    event_type,
    event_timestamp,
    profile_id,
    desired_handle,
    desired_display_name,
    desired_avatar_url
  );
$$;

comment on function public.mirror_clerk_profile(
  text,
  text,
  timestamptz,
  text,
  text,
  text,
  text
) is 'Service-role PostgREST wrapper for Clerk profile mirroring. Logic lives in app.mirror_clerk_profile.';

revoke all on function public.mirror_clerk_profile(
  text,
  text,
  timestamptz,
  text,
  text,
  text,
  text
) from public;

grant execute on function public.mirror_clerk_profile(
  text,
  text,
  timestamptz,
  text,
  text,
  text,
  text
) to service_role;

commit;
