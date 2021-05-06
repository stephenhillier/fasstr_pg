create table if not exists plr_modules (modseq int4, modsrc text);

insert into plr_modules 
select (select max(modseq) + 1 from plr_modules), 'library("fasstr")'
where not exists (
  select * from plr_modules where modsrc = 'library("fasstr")'
);

drop table if exists fasstr_flows;

create table fasstr_flows as (
  with flows as (
    select
      station_number,
      year,
      month,
      flow1,
      flow2,
      flow3,
      flow4,
      flow5,
      flow6,
      flow7,
      flow8,
      flow9,
      flow10,
      flow11,
      flow12,
      flow13,
      flow14,
      flow15,
      flow16,
      flow17,
      flow18,
      flow19,
      flow20,
      flow21,
      flow22,
      flow23,
      flow24,
      flow25,
      flow26,
      flow27,
      flow28,
      flow29,
      flow30,
      flow31
    from dly_flows
  ),
  kv as (
    select station_number, year, month, each(hstore(flows)) as kv from flows
  )
  select
    station_number,
    to_date(concat(year::text, lpad(month::text, 2, '0'), lpad(replace((kv).key, 'flow', '')::text, 2, '0')), 'YYYYMMDD') as date,
    (kv).value::numeric as value
  from kv where (kv).key like 'flow%' and (kv).value is not null
);
create index fasstr_flows_stn_num_idx on fasstr_flows (station_number);
