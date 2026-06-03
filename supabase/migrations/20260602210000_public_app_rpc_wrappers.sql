begin;

create or replace function app.block_user(profile_id text)
returns void
language plpgsql
security definer
set search_path = public, app
as $$
begin
  if app.current_user_id() is null then
    raise exception 'not_authenticated';
  end if;

  if app.current_user_id() = profile_id then
    raise exception 'cannot_block_self';
  end if;

  insert into public.blocks (blocker_user_id, blocked_user_id)
  values (app.current_user_id(), profile_id)
  on conflict (blocker_user_id, blocked_user_id) do nothing;

  delete from public.follows
  where (follower_user_id = app.current_user_id() and followed_user_id = profile_id)
     or (follower_user_id = profile_id and followed_user_id = app.current_user_id());
end;
$$;

create or replace function app.unblock_user(profile_id text)
returns void
language sql
security invoker
set search_path = public, app
as $$
  delete from public.blocks
  where blocker_user_id = app.current_user_id()
    and blocked_user_id = profile_id;
$$;

create or replace function public.visible_places_in_view(
  min_lat double precision,
  min_lng double precision,
  max_lat double precision,
  max_lng double precision,
  status_filter text[] default null,
  category_filter text[] default null,
  owner_scope text[] default null
)
returns table (
  user_place_id uuid,
  place_id uuid,
  owner_user_id text,
  owner_handle text,
  owner_display_name text,
  canonical_name text,
  category text,
  latitude double precision,
  longitude double precision,
  status text,
  visibility text,
  note text,
  rating_signal text,
  source_type text,
  attributes jsonb
)
language sql
stable
security invoker
set search_path = app, public
as $$
  select *
  from app.visible_places_in_view(
    min_lat,
    min_lng,
    max_lat,
    max_lng,
    status_filter,
    category_filter,
    owner_scope
  );
$$;

create or replace function public.search_profiles_by_handle(query text)
returns table (
  id text,
  handle text,
  display_name text,
  avatar_url text,
  bio text,
  home_area text
)
language sql
stable
security invoker
set search_path = app, public
as $$
  select *
  from app.search_profiles_by_handle(query);
$$;

create or replace function public.profile_visible_places(
  profile_id text,
  status_filter text[] default null,
  category_filter text[] default null
)
returns table (
  user_place_id uuid,
  place_id uuid,
  owner_user_id text,
  owner_handle text,
  owner_display_name text,
  canonical_name text,
  category text,
  latitude double precision,
  longitude double precision,
  status text,
  visibility text,
  note text,
  rating_signal text,
  source_type text,
  attributes jsonb
)
language sql
stable
security invoker
set search_path = app, public
as $$
  select *
  from app.profile_visible_places(profile_id, status_filter, category_filter);
$$;

create or replace function public.follow_user(profile_id text, source text default 'profile')
returns void
language plpgsql
security invoker
set search_path = app, public
as $$
begin
  perform app.follow_user(profile_id, source);
end;
$$;

create or replace function public.unfollow_user(profile_id text)
returns void
language plpgsql
security invoker
set search_path = app, public
as $$
begin
  perform app.unfollow_user(profile_id);
end;
$$;

create or replace function public.block_user(profile_id text)
returns void
language plpgsql
security invoker
set search_path = app, public
as $$
begin
  perform app.block_user(profile_id);
end;
$$;

create or replace function public.unblock_user(profile_id text)
returns void
language plpgsql
security invoker
set search_path = app, public
as $$
begin
  perform app.unblock_user(profile_id);
end;
$$;

create or replace function public.save_visible_place(
  input_place_id uuid,
  input_source_user_place_id uuid
)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select jsonb_build_object('user_place_id', saved.id)
  from app.save_visible_place(input_place_id, input_source_user_place_id) as saved;
$$;

create or replace function public.claim_guest_records(local_records jsonb)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select app.claim_guest_records(local_records);
$$;

comment on function public.visible_places_in_view(double precision, double precision, double precision, double precision, text[], text[], text[]) is 'PostgREST wrapper for app.visible_places_in_view.';
comment on function public.search_profiles_by_handle(text) is 'PostgREST wrapper for app.search_profiles_by_handle.';
comment on function public.profile_visible_places(text, text[], text[]) is 'PostgREST wrapper for app.profile_visible_places.';
comment on function public.follow_user(text, text) is 'PostgREST wrapper for app.follow_user.';
comment on function public.unfollow_user(text) is 'PostgREST wrapper for app.unfollow_user.';
comment on function public.block_user(text) is 'PostgREST wrapper for app.block_user.';
comment on function public.unblock_user(text) is 'PostgREST wrapper for app.unblock_user.';
comment on function public.save_visible_place(uuid, uuid) is 'PostgREST wrapper for app.save_visible_place that returns the iOS response shape.';
comment on function public.claim_guest_records(jsonb) is 'PostgREST wrapper for app.claim_guest_records.';

revoke all on function app.block_user(text) from public, anon;
revoke all on function app.unblock_user(text) from public, anon;
revoke all on function public.visible_places_in_view(double precision, double precision, double precision, double precision, text[], text[], text[]) from public, anon;
revoke all on function public.search_profiles_by_handle(text) from public, anon;
revoke all on function public.profile_visible_places(text, text[], text[]) from public, anon;
revoke all on function public.follow_user(text, text) from public, anon;
revoke all on function public.unfollow_user(text) from public, anon;
revoke all on function public.block_user(text) from public, anon;
revoke all on function public.unblock_user(text) from public, anon;
revoke all on function public.save_visible_place(uuid, uuid) from public, anon;
revoke all on function public.claim_guest_records(jsonb) from public, anon;

grant execute on function app.block_user(text) to authenticated;
grant execute on function app.unblock_user(text) to authenticated;
grant execute on function public.visible_places_in_view(double precision, double precision, double precision, double precision, text[], text[], text[]) to authenticated;
grant execute on function public.search_profiles_by_handle(text) to authenticated;
grant execute on function public.profile_visible_places(text, text[], text[]) to authenticated;
grant execute on function public.follow_user(text, text) to authenticated;
grant execute on function public.unfollow_user(text) to authenticated;
grant execute on function public.block_user(text) to authenticated;
grant execute on function public.unblock_user(text) to authenticated;
grant execute on function public.save_visible_place(uuid, uuid) to authenticated;
grant execute on function public.claim_guest_records(jsonb) to authenticated;

commit;
