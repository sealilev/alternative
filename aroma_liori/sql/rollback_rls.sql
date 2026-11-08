-- חירום בלבד: מבטל את סקריפט 3 ומחזיר את המצב הפתוח הקודם.
-- להריץ רק אם משהו נשבר אחרי הנעילה ואין זמן לתקן. אחרי זה הנתונים שוב חשופים!

grant select, insert, update, delete on public.clients, public.oils, public.progress_updates, public.inventory to anon;

alter table public.clients          disable row level security;
alter table public.oils             disable row level security;
alter table public.progress_updates disable row level security;
alter table public.inventory        disable row level security;
