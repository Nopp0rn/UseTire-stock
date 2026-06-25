-- ============================================================
-- ระบบบันทึกยางเก่า ดี/เสีย — Supabase Setup
-- รันใน Supabase Dashboard > SQL Editor
-- ============================================================

-- 1) ตารางหลัก
create table if not exists public.tire_records (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz default now(),
  record_date     date not null,
  month_key       text not null,          -- เช่น 2026-06 (ใช้แยก/ลบรายเดือน)
  branch          text not null,          -- 003,009,010,...
  tire_size       text,
  brand           text,
  qty_received    int default 0,          -- รับเข้าสต็อกยางเก่า
  qty_good        int default 0,          -- เข้าสต็อกยางดี
  qty_bad         int default 0,          -- เข้าสต็อกยางเสีย
  qty_customer_back int default 0,        -- ลูกค้านำกลับ
  qty_sold_good   int default 0,          -- ผู้รับเหมายางดีซื้อออก
  qty_sold_bad    int default 0,          -- ผู้รับเหมายางเสียซื้อออก
  qty_rejected    int default 0,          -- ยางดีถูกปฏิเสธ -> ย้ายเข้ายางเสีย
  reject_note     text,
  reject_photos   jsonb default '[]'::jsonb   -- [{url, path}, ...]
);

create index if not exists idx_tire_branch on public.tire_records(branch);
create index if not exists idx_tire_month  on public.tire_records(month_key);
create index if not exists idx_tire_date   on public.tire_records(record_date);

-- 2) เปิด RLS + นโยบายแบบเปิด (เครื่องมือภายใน ใช้ anon key)
alter table public.tire_records enable row level security;

drop policy if exists "tire read"   on public.tire_records;
drop policy if exists "tire insert" on public.tire_records;
drop policy if exists "tire update" on public.tire_records;
drop policy if exists "tire delete" on public.tire_records;

create policy "tire read"   on public.tire_records for select using (true);
create policy "tire insert" on public.tire_records for insert with check (true);
create policy "tire update" on public.tire_records for update using (true);
create policy "tire delete" on public.tire_records for delete using (true);

-- 3) Storage bucket สำหรับรูปถ่ายยางที่ถูกปฏิเสธ
insert into storage.buckets (id, name, public)
values ('tire-photos','tire-photos', true)
on conflict (id) do nothing;

drop policy if exists "tire-photos read"   on storage.objects;
drop policy if exists "tire-photos upload" on storage.objects;
drop policy if exists "tire-photos delete" on storage.objects;

create policy "tire-photos read"   on storage.objects for select using (bucket_id = 'tire-photos');
create policy "tire-photos upload" on storage.objects for insert with check (bucket_id = 'tire-photos');
create policy "tire-photos delete" on storage.objects for delete using (bucket_id = 'tire-photos');
