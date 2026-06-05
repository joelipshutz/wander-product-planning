begin;

create or replace function app.save_own_place(
  input_place jsonb,
  input_user_place jsonb,
  input_attributes jsonb default '[]'::jsonb
)
returns public.user_places
language plpgsql
security invoker
as $$
declare
  viewer_id text := app.current_user_id();
  provider text;
  provider_place_id text;
  place_row public.places;
  saved_row public.user_places;
  attr jsonb;
  attr_question_key text;
  attr_value_type text;
  attr_question_definition_id uuid;
begin
  if viewer_id is null then
    raise exception 'not_authenticated';
  end if;

  if coalesce(jsonb_typeof(input_place), '') <> 'object' then
    raise exception 'invalid_place_payload';
  end if;

  if coalesce(jsonb_typeof(input_user_place), '') <> 'object' then
    raise exception 'invalid_user_place_payload';
  end if;

  if coalesce(jsonb_typeof(input_attributes), 'array') <> 'array' then
    raise exception 'invalid_attributes_payload';
  end if;

  provider := coalesce(nullif(input_place->>'source_provider', ''), 'manual');
  provider_place_id := nullif(input_place->>'source_provider_place_id', '');

  if provider_place_id is null then
    provider_place_id := 'generated:' || md5(
      provider || ':' ||
      coalesce(input_place->>'canonical_name', '') || ':' ||
      coalesce(input_place->>'latitude', '') || ':' ||
      coalesce(input_place->>'longitude', '')
    );
  end if;

  insert into public.places (
    canonical_name,
    category,
    address,
    locality,
    region,
    country,
    latitude,
    longitude,
    source_provider,
    source_provider_place_id,
    confidence
  )
  values (
    input_place->>'canonical_name',
    coalesce(nullif(input_place->>'category', ''), 'place'),
    nullif(input_place->>'address', ''),
    nullif(input_place->>'locality', ''),
    nullif(input_place->>'region', ''),
    nullif(input_place->>'country', ''),
    (input_place->>'latitude')::double precision,
    (input_place->>'longitude')::double precision,
    provider,
    provider_place_id,
    nullif(input_place->>'confidence', '')::double precision
  )
  on conflict (source_provider, source_provider_place_id)
  do update set
    canonical_name = excluded.canonical_name,
    category = excluded.category,
    address = excluded.address,
    locality = excluded.locality,
    region = excluded.region,
    country = excluded.country,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    confidence = excluded.confidence,
    updated_at = now()
  returning * into place_row;

  insert into public.user_places (
    user_id,
    place_id,
    status,
    note,
    rating_signal,
    visibility,
    nearby_confirmed,
    source_type
  )
  values (
    viewer_id,
    place_row.id,
    input_user_place->>'status',
    nullif(input_user_place->>'note', ''),
    nullif(input_user_place->>'rating_signal', ''),
    input_user_place->>'visibility',
    coalesce((input_user_place->>'nearby_confirmed')::boolean, false),
    input_user_place->>'source_type'
  )
  on conflict (user_id, place_id)
  do update set
    status = excluded.status,
    note = excluded.note,
    rating_signal = excluded.rating_signal,
    visibility = excluded.visibility,
    nearby_confirmed = excluded.nearby_confirmed,
    source_type = excluded.source_type,
    deleted_at = null,
    updated_at = now()
  returning * into saved_row;

  delete from public.place_attributes pa
  where pa.user_place_id = saved_row.id
    and not exists (
      select 1
      from jsonb_array_elements(input_attributes) as incoming(attr)
      where incoming.attr->>'question_key' = pa.question_key
    );

  for attr in select value from jsonb_array_elements(input_attributes)
  loop
    attr_question_key := nullif(attr->>'question_key', '');
    attr_value_type := nullif(attr->>'value_type', '');

    if attr_question_key is null
       or attr_value_type is null
       or not (attr ? 'value')
       or attr->'value' = 'null'::jsonb then
      continue;
    end if;

    select qd.id
    into attr_question_definition_id
    from public.question_definitions qd
    where qd.question_key = attr_question_key
      and (qd.owner_user_id = viewer_id or qd.is_system)
    order by (qd.owner_user_id = viewer_id) desc, qd.is_system desc
    limit 1;

    insert into public.place_attributes (
      user_place_id,
      question_definition_id,
      question_key,
      value_type,
      value
    )
    values (
      saved_row.id,
      attr_question_definition_id,
      attr_question_key,
      attr_value_type,
      attr->'value'
    )
    on conflict (user_place_id, question_key)
    do update set
      question_definition_id = excluded.question_definition_id,
      value_type = excluded.value_type,
      value = excluded.value,
      updated_at = now();
  end loop;

  return saved_row;
end;
$$;

create or replace function public.save_own_place(
  input_place jsonb,
  input_user_place jsonb,
  input_attributes jsonb default '[]'::jsonb
)
returns jsonb
language sql
security invoker
set search_path = app, public
as $$
  select jsonb_build_object(
    'user_place_id', saved.id,
    'place_id', saved.place_id
  )
  from app.save_own_place(input_place, input_user_place, input_attributes) as saved;
$$;

comment on function public.save_own_place(jsonb, jsonb, jsonb) is 'PostgREST wrapper for app.save_own_place that returns the iOS direct own-place save response shape.';

revoke all on function app.save_own_place(jsonb, jsonb, jsonb) from public, anon;
revoke all on function public.save_own_place(jsonb, jsonb, jsonb) from public, anon;

grant execute on function app.save_own_place(jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.save_own_place(jsonb, jsonb, jsonb) to authenticated;

commit;
