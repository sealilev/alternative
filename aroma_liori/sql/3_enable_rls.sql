-- סקריפט 3 (שלב 2): נעילת הטבלאות
-- מריצים רק אחרי שדף הלקוחה החדש (שעובד דרך הפונקציות) עלה לאתר החי.
-- אחרת דף הלקוחה יפסיק לעבוד.


-- א. מוחקים כללים קיימים על ארבע הטבלאות (אם יש), כדי שלא יישאר כלל פתוח מדי.
do $$
declare
  r record;
begin
  for r in
    select tablename, policyname from pg_policies
    where schemaname = 'public'
      and tablename in ('clients', 'oils', 'progress_updates', 'inventory')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;


-- ב. מפעילים RLS: מעכשיו כל בקשה נחסמת, חוץ ממה שכלל מתיר במפורש.
alter table public.clients          enable row level security;
alter table public.oils             enable row level security;
alter table public.progress_updates enable row level security;
alter table public.inventory        enable row level security;


-- ג. כלל אחד לכל טבלה: מנהלת מחוברת (authenticated) מורשית לעשות הכול.
--    אין הרשמה ציבורית, ולכן כל מחוברת היא מישהי שהוזמנה.
create policy "admin full access" on public.clients
  for all to authenticated using (true) with check (true);

create policy "admin full access" on public.oils
  for all to authenticated using (true) with check (true);

create policy "admin full access" on public.progress_updates
  for all to authenticated using (true) with check (true);

create policy "admin full access" on public.inventory
  for all to authenticated using (true) with check (true);


-- ד. שכבה נוספת: מי שלא מחוברת (anon) לא מקבלת שום הרשאה על הטבלאות.
--    גם אם בטעות ייווצר בעתיד כלל פתוח, anon עדיין לא תוכל לגשת.
revoke all on public.clients, public.oils, public.progress_updates, public.inventory from anon;
