-- Wander M3 backend foundation.
-- Clerk user ids are stored as text profile ids and read from the JWT `sub` claim.

create extension if not exists pgcrypto;
create extension if not exists postgis;

create schema if not exists app;

create or replace function app.current_user_id()
returns text
language sql
stable
as $$
  select nullif(coalesce(auth.jwt() ->> 'sub', current_setting('request.jwt.claim.sub', true)), '')
$$;

create or replace function app.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id text primary key,
  handle text not null,
  search_handle text generated always as (lower(handle)) stored,
  display_name text not null,
  avatar_url text,
  bio text,
  home_area text,
  default_visibility text not null default 'followers'
    check (default_visibility in ('followers', 'mutuals', 'self')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (length(handle) >= 2),
  check (handle = lower(handle)),
  check (handle ~ '^[a-z0-9_]+$')
);

create unique index profiles_search_handle_key on public.profiles (search_handle) where deleted_at is null;

create table public.follows (
  id uuid primary key default gen_random_uuid(),
  follower_user_id text not null references public.profiles(id) on delete cascade,
  followed_user_id text not null references public.profiles(id) on delete cascade,
  source text not null check (source in ('username', 'contacts', 'profile', 'invite_link_future')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (follower_user_id, followed_user_id),
  check (follower_user_id <> followed_user_id)
);

create table public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_user_id text not null references public.profiles(id) on delete cascade,
  blocked_user_id text not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blocker_user_id, blocked_user_id),
  check (blocker_user_id <> blocked_user_id)
);

create table public.places (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  category text not null,
  address text,
  locality text,
  region text,
  country text,
  latitude double precision not null,
  longitude double precision not null,
  geog geography(point, 4326) generated always as (
    st_setsrid(st_makepoint(longitude, latitude), 4326)::geography
  ) stored,
  source_provider text not null,
  source_provider_place_id text,
  confidence double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (latitude between -90 and 90),
  check (longitude between -180 and 180),
  unique (source_provider, source_provider_place_id)
);

create table public.source_artifacts (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('url', 'image', 'text', 'current_location')),
  original_input text not null,
  normalized_input text not null,
  normalized_source_hash text not null,
  local_asset_ref text,
  remote_asset_ref text,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, type, normalized_source_hash)
);

create table public.user_places (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles(id) on delete cascade,
  place_id uuid not null references public.places(id) on delete cascade,
  status text not null check (status in ('been', 'wanna_go')),
  note text,
  rating_signal text,
  visibility text not null check (visibility in ('followers', 'mutuals', 'self')),
  nearby_confirmed boolean not null default false,
  visited_at timestamptz,
  saved_at timestamptz not null default now(),
  source_type text not null check (source_type in ('current_location', 'link', 'manual', 'photo', 'social_save', 'social_seed')),
  source_artifact_id uuid references public.source_artifacts(id) on delete set null,
  source_user_place_id uuid references public.user_places(id) on delete set null,
  attribution_user_id text references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, place_id)
);

create table public.question_definitions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id text references public.profiles(id) on delete cascade,
  category text,
  question_key text not null,
  prompt text not null,
  value_type text not null check (value_type in ('emoji_scale', 'single_choice', 'multi_tag', 'price_scale', 'text', 'boolean')),
  options jsonb not null default '[]',
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((is_system and owner_user_id is null) or (not is_system and owner_user_id is not null))
);

create unique index question_definitions_owner_key
  on public.question_definitions (coalesce(owner_user_id, '__system__'), question_key);

create table public.place_attributes (
  id uuid primary key default gen_random_uuid(),
  user_place_id uuid not null references public.user_places(id) on delete cascade,
  question_definition_id uuid references public.question_definitions(id) on delete set null,
  question_key text not null,
  value_type text not null check (value_type in ('emoji_scale', 'single_choice', 'multi_tag', 'price_scale', 'text', 'boolean')),
  value jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_place_id, question_key)
);

create table public.extraction_jobs (
  id uuid primary key default gen_random_uuid(),
  source_artifact_id uuid not null references public.source_artifacts(id) on delete cascade,
  owner_user_id text not null references public.profiles(id) on delete cascade,
  source_type text not null,
  normalized_source_hash text not null,
  status text not null check (status in ('pending', 'running', 'needs_confirmation', 'complete', 'failed', 'no_place_found')),
  attempt_count integer not null default 0,
  provider_steps_json jsonb not null default '[]',
  extracted_candidates_json jsonb not null default '[]',
  selected_place_id uuid references public.places(id) on delete set null,
  confidence double precision not null default 0,
  error_code text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_user_id, source_type, normalized_source_hash)
);

create table public.sync_tombstones (
  id uuid primary key default gen_random_uuid(),
  owner_user_id text not null,
  entity_name text not null,
  entity_id text not null,
  reason text not null check (reason in ('delete', 'block', 'server_denied', 'merge')),
  created_at timestamptz not null default now(),
  unique (owner_user_id, entity_name, entity_id)
);

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id text references public.profiles(id) on delete set null,
  name text not null,
  properties jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index follows_followed_follower_idx on public.follows (followed_user_id, follower_user_id);
create index blocks_blocked_blocker_idx on public.blocks (blocked_user_id, blocker_user_id);
create index places_geog_idx on public.places using gist (geog);
create index user_places_place_visibility_status_idx on public.user_places (place_id, visibility, status) where deleted_at is null;
create index user_places_user_visibility_status_updated_idx on public.user_places (user_id, visibility, status, updated_at desc) where deleted_at is null;
create index place_attributes_user_place_idx on public.place_attributes (user_place_id);
create index source_artifacts_user_hash_idx on public.source_artifacts (user_id, type, normalized_source_hash) where deleted_at is null;
create index extraction_jobs_owner_hash_idx on public.extraction_jobs (owner_user_id, source_type, normalized_source_hash);
create index sync_tombstones_owner_entity_idx on public.sync_tombstones (owner_user_id, entity_name, entity_id);
create index analytics_events_user_created_idx on public.analytics_events (user_id, created_at desc);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function app.set_updated_at();
create trigger follows_updated_at before update on public.follows
  for each row execute function app.set_updated_at();
create trigger places_updated_at before update on public.places
  for each row execute function app.set_updated_at();
create trigger user_places_updated_at before update on public.user_places
  for each row execute function app.set_updated_at();
create trigger question_definitions_updated_at before update on public.question_definitions
  for each row execute function app.set_updated_at();
create trigger place_attributes_updated_at before update on public.place_attributes
  for each row execute function app.set_updated_at();
create trigger extraction_jobs_updated_at before update on public.extraction_jobs
  for each row execute function app.set_updated_at();

create or replace function app.is_blocked(user_a text, user_b text)
returns boolean
language sql
stable
security definer
set search_path = public, app
as $$
  select exists (
    select 1
    from public.blocks b
    where (b.blocker_user_id = user_a and b.blocked_user_id = user_b)
       or (b.blocker_user_id = user_b and b.blocked_user_id = user_a)
  )
$$;

create or replace function app.follows(viewer_id text, owner_id text)
returns boolean
language sql
stable
security definer
set search_path = public, app
as $$
  select exists (
    select 1
    from public.follows f
    where f.follower_user_id = viewer_id
      and f.followed_user_id = owner_id
  )
$$;

create or replace function app.is_mutual(viewer_id text, owner_id text)
returns boolean
language sql
stable
security definer
set search_path = public, app
as $$
  select app.follows(viewer_id, owner_id) and app.follows(owner_id, viewer_id)
$$;

create or replace function app.can_read_user_place(viewer_id text, owner_id text, visibility text)
returns boolean
language sql
stable
security definer
set search_path = public, app
as $$
  select case
    when viewer_id is null then false
    when app.is_blocked(viewer_id, owner_id) then false
    when viewer_id = owner_id then true
    when visibility = 'self' then false
    when visibility = 'followers' then app.follows(viewer_id, owner_id)
    when visibility = 'mutuals' then app.is_mutual(viewer_id, owner_id)
    else false
  end
$$;

create or replace function app.can_read_profile(profile_id text)
returns boolean
language sql
stable
as $$
  select app.current_user_id() is not null
     and profile_id <> ''
     and not app.is_blocked(app.current_user_id(), profile_id)
$$;

alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.blocks enable row level security;
alter table public.places enable row level security;
alter table public.source_artifacts enable row level security;
alter table public.user_places enable row level security;
alter table public.question_definitions enable row level security;
alter table public.place_attributes enable row level security;
alter table public.extraction_jobs enable row level security;
alter table public.sync_tombstones enable row level security;
alter table public.analytics_events enable row level security;

create policy "profiles readable when not blocked"
  on public.profiles for select
  using (deleted_at is null and app.can_read_profile(id));

create policy "profiles insert own clerk user"
  on public.profiles for insert
  with check (id = app.current_user_id());

create policy "profiles update own"
  on public.profiles for update
  using (id = app.current_user_id())
  with check (id = app.current_user_id());

create policy "follows readable when both users visible"
  on public.follows for select
  using (
    app.current_user_id() is not null
    and not app.is_blocked(app.current_user_id(), follower_user_id)
    and not app.is_blocked(app.current_user_id(), followed_user_id)
  );

create policy "follows insert self"
  on public.follows for insert
  with check (follower_user_id = app.current_user_id() and not app.is_blocked(follower_user_id, followed_user_id));

create policy "follows delete self"
  on public.follows for delete
  using (follower_user_id = app.current_user_id());

create policy "blocks readable by blocker"
  on public.blocks for select
  using (blocker_user_id = app.current_user_id());

create policy "blocks insert self"
  on public.blocks for insert
  with check (blocker_user_id = app.current_user_id());

create policy "blocks delete self"
  on public.blocks for delete
  using (blocker_user_id = app.current_user_id());

create policy "places readable through visible user places"
  on public.places for select
  using (
    exists (
      select 1
      from public.user_places up
      where up.place_id = places.id
        and up.deleted_at is null
        and app.can_read_user_place(app.current_user_id(), up.user_id, up.visibility)
    )
  );

create policy "places insert authenticated"
  on public.places for insert
  with check (app.current_user_id() is not null);

create policy "source artifacts owner only"
  on public.source_artifacts for all
  using (user_id = app.current_user_id())
  with check (user_id = app.current_user_id());

create policy "user places readable by visibility"
  on public.user_places for select
  using (
    deleted_at is null
    and app.can_read_user_place(app.current_user_id(), user_id, visibility)
  );

create policy "user places insert own"
  on public.user_places for insert
  with check (user_id = app.current_user_id());

create policy "user places update own"
  on public.user_places for update
  using (user_id = app.current_user_id())
  with check (user_id = app.current_user_id());

create policy "user places delete own"
  on public.user_places for delete
  using (user_id = app.current_user_id());

create policy "question definitions readable if system own or attached visible"
  on public.question_definitions for select
  using (
    is_system
    or owner_user_id = app.current_user_id()
    or exists (
      select 1
      from public.place_attributes pa
      join public.user_places up on up.id = pa.user_place_id
      where pa.question_definition_id = question_definitions.id
        and app.can_read_user_place(app.current_user_id(), up.user_id, up.visibility)
    )
  );

create policy "question definitions insert own custom"
  on public.question_definitions for insert
  with check (owner_user_id = app.current_user_id() and not is_system);

create policy "question definitions update own custom"
  on public.question_definitions for update
  using (owner_user_id = app.current_user_id() and not is_system)
  with check (owner_user_id = app.current_user_id() and not is_system);

create policy "question definitions delete own custom"
  on public.question_definitions for delete
  using (owner_user_id = app.current_user_id() and not is_system);

create policy "place attributes readable through user place"
  on public.place_attributes for select
  using (
    exists (
      select 1
      from public.user_places up
      where up.id = place_attributes.user_place_id
        and app.can_read_user_place(app.current_user_id(), up.user_id, up.visibility)
    )
  );

create policy "place attributes insert by user place owner"
  on public.place_attributes for insert
  with check (
    exists (
      select 1
      from public.user_places up
      where up.id = place_attributes.user_place_id
        and up.user_id = app.current_user_id()
    )
  );

create policy "place attributes update by user place owner"
  on public.place_attributes for update
  using (
    exists (
      select 1
      from public.user_places up
      where up.id = place_attributes.user_place_id
        and up.user_id = app.current_user_id()
    )
  )
  with check (
    exists (
      select 1
      from public.user_places up
      where up.id = place_attributes.user_place_id
        and up.user_id = app.current_user_id()
    )
  );

create policy "place attributes delete by user place owner"
  on public.place_attributes for delete
  using (
    exists (
      select 1
      from public.user_places up
      where up.id = place_attributes.user_place_id
        and up.user_id = app.current_user_id()
    )
  );

create policy "extraction jobs owner only"
  on public.extraction_jobs for all
  using (owner_user_id = app.current_user_id())
  with check (owner_user_id = app.current_user_id());

create policy "sync tombstones owner only"
  on public.sync_tombstones for all
  using (owner_user_id = app.current_user_id())
  with check (owner_user_id = app.current_user_id());

create policy "analytics insert authenticated self"
  on public.analytics_events for insert
  with check (user_id is null or user_id = app.current_user_id());

create policy "analytics read own"
  on public.analytics_events for select
  using (user_id = app.current_user_id());

grant usage on schema app to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.question_definitions to anon;

create or replace function app.visible_places_in_view(
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
as $$
  select
    up.id,
    p.id,
    up.user_id,
    owner.handle,
    owner.display_name,
    p.canonical_name,
    p.category,
    p.latitude,
    p.longitude,
    up.status,
    up.visibility,
    up.note,
    up.rating_signal,
    up.source_type,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'question_definition_id', pa.question_definition_id,
          'question_key', pa.question_key,
          'value_type', pa.value_type,
          'value', pa.value,
          'prompt', qd.prompt,
          'options', coalesce(qd.options, '[]'::jsonb),
          'is_system', coalesce(qd.is_system, false)
        )
      ) filter (where pa.id is not null),
      '[]'::jsonb
    ) as attributes
  from public.user_places up
  join public.places p on p.id = up.place_id
  join public.profiles owner on owner.id = up.user_id
  left join public.place_attributes pa on pa.user_place_id = up.id
  left join public.question_definitions qd on qd.id = pa.question_definition_id
  where up.deleted_at is null
    and p.latitude between min_lat and max_lat
    and p.longitude between min_lng and max_lng
    and (status_filter is null or up.status = any(status_filter))
    and (category_filter is null or p.category = any(category_filter))
    and (
      owner_scope is null
      or ('you' = any(owner_scope) and up.user_id = app.current_user_id())
      or ('following' = any(owner_scope) and up.user_id <> app.current_user_id() and app.follows(app.current_user_id(), up.user_id))
      or ('friends' = any(owner_scope) and up.user_id <> app.current_user_id() and app.is_mutual(app.current_user_id(), up.user_id))
      or ('social' = any(owner_scope) and up.user_id <> app.current_user_id())
    )
  group by up.id, p.id, owner.id;
$$;

create or replace function app.search_profiles_by_handle(query text)
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
as $$
  with normalized as (
    select lower(trim(replace(query, '@', ''))) as q
  )
  select p.id, p.handle, p.display_name, p.avatar_url, p.bio, p.home_area
  from public.profiles p, normalized n
  where length(n.q) >= 2
    and p.search_handle like n.q || '%'
    and p.deleted_at is null
  order by p.search_handle
  limit 20;
$$;

create or replace function app.profile_visible_places(
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
as $$
  select
    up.id,
    p.id,
    up.user_id,
    owner.handle,
    owner.display_name,
    p.canonical_name,
    p.category,
    p.latitude,
    p.longitude,
    up.status,
    up.visibility,
    up.note,
    up.rating_signal,
    up.source_type,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'question_definition_id', pa.question_definition_id,
          'question_key', pa.question_key,
          'value_type', pa.value_type,
          'value', pa.value,
          'prompt', qd.prompt,
          'options', coalesce(qd.options, '[]'::jsonb),
          'is_system', coalesce(qd.is_system, false)
        )
      ) filter (where pa.id is not null),
      '[]'::jsonb
    ) as attributes
  from public.user_places up
  join public.places p on p.id = up.place_id
  join public.profiles owner on owner.id = up.user_id
  left join public.place_attributes pa on pa.user_place_id = up.id
  left join public.question_definitions qd on qd.id = pa.question_definition_id
  where up.user_id = profile_id
    and up.deleted_at is null
    and (status_filter is null or up.status = any(status_filter))
    and (category_filter is null or p.category = any(category_filter))
  group by up.id, p.id, owner.id
  order by up.updated_at desc;
$$;

create or replace function app.follow_user(profile_id text, source text default 'profile')
returns public.follows
language plpgsql
security invoker
as $$
declare
  created_follow public.follows;
begin
  if app.current_user_id() is null then
    raise exception 'not_authenticated';
  end if;

  if app.current_user_id() = profile_id then
    raise exception 'cannot_follow_self';
  end if;

  if app.is_blocked(app.current_user_id(), profile_id) then
    raise exception 'blocked';
  end if;

  insert into public.follows (follower_user_id, followed_user_id, source)
  values (app.current_user_id(), profile_id, source)
  on conflict (follower_user_id, followed_user_id)
  do update set source = excluded.source, updated_at = now()
  returning * into created_follow;

  return created_follow;
end;
$$;

create or replace function app.unfollow_user(profile_id text)
returns void
language sql
security invoker
as $$
  delete from public.follows
  where follower_user_id = app.current_user_id()
    and followed_user_id = profile_id;
$$;

create or replace function app.block_user(profile_id text)
returns void
language plpgsql
security invoker
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

create or replace function app.save_visible_place(input_place_id uuid, input_source_user_place_id uuid)
returns public.user_places
language plpgsql
security invoker
as $$
declare
  source_row public.user_places;
  saved_row public.user_places;
begin
  if app.current_user_id() is null then
    raise exception 'not_authenticated';
  end if;

  select *
  into source_row
  from public.user_places up
  where up.id = input_source_user_place_id
    and up.place_id = input_place_id
    and up.deleted_at is null;

  if source_row.id is null then
    raise exception 'source_not_visible';
  end if;

  insert into public.user_places (
    user_id,
    place_id,
    status,
    note,
    rating_signal,
    visibility,
    source_type,
    source_user_place_id,
    attribution_user_id
  )
  values (
    app.current_user_id(),
    input_place_id,
    'wanna_go',
    source_row.note,
    source_row.rating_signal,
    'followers',
    'social_save',
    source_row.id,
    source_row.user_id
  )
  on conflict (user_id, place_id)
  do update set
    status = excluded.status,
    note = excluded.note,
    rating_signal = excluded.rating_signal,
    source_type = excluded.source_type,
    source_user_place_id = excluded.source_user_place_id,
    attribution_user_id = excluded.attribution_user_id,
    deleted_at = null,
    updated_at = now()
  returning * into saved_row;

  insert into public.place_attributes (user_place_id, question_definition_id, question_key, value_type, value)
  select saved_row.id, pa.question_definition_id, pa.question_key, pa.value_type, pa.value
  from public.place_attributes pa
  where pa.user_place_id = source_row.id
  on conflict (user_place_id, question_key)
  do update set
    question_definition_id = excluded.question_definition_id,
    value_type = excluded.value_type,
    value = excluded.value,
    updated_at = now();

  return saved_row;
end;
$$;

create or replace function app.claim_guest_records(local_records jsonb)
returns jsonb
language sql
security invoker
as $$
  select jsonb_build_object(
    'accepted_count', 0,
    'status', 'stubbed_until_sync_worker',
    'received_count', coalesce(jsonb_array_length(local_records), 0)
  )
$$;

grant execute on function app.visible_places_in_view(double precision, double precision, double precision, double precision, text[], text[], text[]) to authenticated;
grant execute on function app.search_profiles_by_handle(text) to authenticated;
grant execute on function app.profile_visible_places(text, text[], text[]) to authenticated;
grant execute on function app.follow_user(text, text) to authenticated;
grant execute on function app.unfollow_user(text) to authenticated;
grant execute on function app.block_user(text) to authenticated;
grant execute on function app.save_visible_place(uuid, uuid) to authenticated;
grant execute on function app.claim_guest_records(jsonb) to authenticated;
