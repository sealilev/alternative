-- סקריפט 2 (שלב 3): פונקציות לדף הלקוחה
-- בטוח להריץ מיד: רק מוסיף פונקציות, לא חוסם ולא משנה נתונים.
--
-- security definer = הפונקציה רצה עם ההרשאות של מי שיצר אותה, ולכן היא יכולה
-- לקרוא את הטבלאות גם אחרי שנחסום אותן. היא מחזירה רק את מה שמותר:
-- הנתונים של הלקוחה שהטוקן שלה נשלח, ורק השדות שהדף מציג
-- (בלי ת.ז., טלפון, רקע רפואי וכו').


-- קריאה: כל מה שדף הלקוחה מציג, לפי הטוקן
create or replace function public.get_client_portal(p_token text)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_client clients%rowtype;
begin
  if p_token is null or length(p_token) < 8 then
    return null;
  end if;

  select * into v_client from clients where token::text = p_token;
  if not found then
    return null;
  end if;

  return json_build_object(
    'client', json_build_object(
      'name',  v_client.name,
      'notes', v_client.notes
    ),
    'oils', coalesce((
      select json_agg(json_build_object(
               'id',           o.id,
               'name',         o.name,
               'purpose',      o.purpose,
               'ingredients',  o.ingredients,
               'instructions', o.instructions,
               'created_at',   o.created_at
             ) order by o.created_at)
      from oils o
      where o.client_id = v_client.id
    ), '[]'::json),
    'progress', coalesce((
      select json_agg(json_build_object(
               'feeling',     p.feeling,
               'update_text', p.update_text,
               'created_at',  p.created_at,
               'oil_name',    o.name
             ) order by p.created_at desc)
      from progress_updates p
      left join oils o on o.id = p.oil_id
      where p.client_id = v_client.id
    ), '[]'::json)
  );
end;
$$;


-- כתיבה: הוספת עדכון ליומן, רק ללקוחה שהטוקן שלה נשלח
create or replace function public.add_progress_update(
  p_token   text,
  p_oil_id  uuid,
  p_text    text,
  p_feeling int
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_client_id clients.id%type;
begin
  if p_token is null or length(p_token) < 8 then
    raise exception 'invalid token';
  end if;

  select id into v_client_id from clients where token::text = p_token;
  if v_client_id is null then
    raise exception 'invalid token';
  end if;

  if p_text is null or length(trim(p_text)) = 0 or length(p_text) > 5000 then
    raise exception 'invalid text';
  end if;

  if p_feeling is not null and p_feeling not between 1 and 5 then
    raise exception 'invalid feeling';
  end if;

  -- השמן חייב להיות של אותה לקוחה
  if p_oil_id is not null and not exists (
    select 1 from oils where id = p_oil_id and client_id = v_client_id
  ) then
    raise exception 'invalid oil';
  end if;

  insert into progress_updates (client_id, oil_id, update_text, feeling)
  values (v_client_id, p_oil_id, trim(p_text), p_feeling);
end;
$$;


-- מי מורשה להפעיל את הפונקציות: כולם (גם בלי התחברות), כי הלקוחה לא מתחברת.
-- ההגנה היא הטוקן: בלי טוקן נכון הפונקציה לא מחזירה כלום.
revoke all on function public.get_client_portal(text) from public;
revoke all on function public.add_progress_update(text, uuid, text, int) from public;
grant execute on function public.get_client_portal(text) to anon, authenticated;
grant execute on function public.add_progress_update(text, uuid, text, int) to anon, authenticated;
