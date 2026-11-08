-- סקריפט 1: בדיקת המצב הקיים (קריאה בלבד, לא משנה כלום)
-- מריצים ב-Supabase → SQL Editor, ושולחים ל-Claude את טבלת התוצאה.

select 'rls' as kind, c.relname as name, c.relrowsecurity::text as detail
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'

union all
select 'policy', tablename || ' / ' || policyname,
       cmd || ' to ' || array_to_string(roles, ',') ||
       ' | using: ' || coalesce(qual, '-') || ' | check: ' || coalesce(with_check, '-')
from pg_policies
where schemaname = 'public'

union all
select 'column', table_name || '.' || column_name,
       data_type || ' | default: ' || coalesce(column_default, '-')
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'clients' and column_name in ('id', 'token'))
    or (table_name = 'progress_updates' and column_name in ('client_id', 'oil_id', 'feeling')))

union all
select 'function', p.proname, pg_get_function_identity_arguments(p.oid)
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'

order by 1, 2;
