-- fasstr_calc_annual_lowflows
-- example: select * from fasstr_calc_annual_lowflows('08NM116')

drop function if exists r_fasstr_calc_annual_lowflows;
drop function if exists fasstr_calc_annual_lowflows(date[], numeric[], boolean);
drop function if exists fasstr_calc_annual_lowflows(text, boolean);
drop table if exists annual_lowflows;
drop table if exists r_fasstr_annual_lowflows;

create table annual_lowflows (
  year integer,
  min_1_day numeric,
  min_1_day_doy numeric,
  min_1_day_date date,
  min_3_day numeric,
  min_3_day_doy numeric,
  min_3_day_date date,
  min_7_day numeric,
  min_7_day_doy numeric,
  min_7_day_date date,
  min_30_day numeric,
  min_30_day_doy numeric,
  min_30_day_date date
);

-- helper table to read in the dates from R.
-- dates seem to come back to postgres as an offset from Jan 1 1970.
-- we'll add the day of year to the year to get the date instead
-- e.g. make_date(year, 1, 1) + min_1_day_doy::integer - 1 as min_1_day_date,
create table r_fasstr_annual_lowflows (
  year integer,
  min_1_day numeric,
  min_1_day_doy numeric,
  min_1_day_date text,
  min_3_day numeric,
  min_3_day_doy numeric,
  min_3_day_date text,
  min_7_day numeric,
  min_7_day_doy numeric,
  min_7_day_date text,
  min_30_day numeric,
  min_30_day_doy numeric,
  min_30_day_date text
);

-- because the min_x_date return value for this function isn't working in PL/R,
-- we'll add an r_ prefix to separate it from the other functions.
-- use the fasstr_ functions instead - there's a fasstr_calc_annual_lowflows
-- with the same signature (for the input arg types).
create or replace function r_fasstr_calc_annual_lowflows(
  dates date[],
  flows numeric[],
  ignore_missing boolean default TRUE
)
returns setof r_fasstr_annual_lowflows as
$$
  library(fasstr)

  flowdata <- data.frame(Date = dates, Value = flows)
  x <- fasstr::calc_annual_lowflows(
    data=flowdata,
    ignore_missing=ignore_missing
  )

  names(x) <- tolower(names(x))
  return(x)
$$
LANGUAGE 'plr' VOLATILE STRICT;

-- accepts two arrays for dates and args
create or replace function fasstr_calc_annual_lowflows(
  dates date[],
  flows numeric[],
  ignore_missing boolean default TRUE
) returns setof annual_lowflows as
$$
  select 
    year,
    min_1_day,
    min_1_day_doy,
    make_date(year, 1, 1) + min_1_day_doy::integer - 1 as min_1_day_date,
    min_3_day,
    min_3_day_doy,
    make_date(year, 1, 1) + min_3_day_doy::integer - 1 as min_3_day_date,
    min_7_day,
    min_7_day_doy,
    make_date(year, 1, 1) + min_7_day_doy::integer - 1 as min_7_day_date,
    min_30_day,
    min_30_day_doy,
    make_date(year, 1, 1) + min_30_day_doy::integer - 1 as min_30_day_date
  from r_fasstr_calc_annual_lowflows(dates, flows, ignore_missing)
$$
LANGUAGE 'sql'
;

-- accepts a `station_number` value from the fasstr_flows table.
-- this function creates arrays from the `fasstr_flows` table
-- and then calls the fasstr_calc_annual_lowflows(date[], numeric[], ...)
-- function. If you already have dates and values from another table,
-- you could modify this function or re-use this query.
create or replace function fasstr_calc_annual_lowflows(
  stn text,
  ignore_missing boolean default TRUE
)
returns setof annual_lowflows as
$$
  with flowdata as (
    select array_agg(value) as values, array_agg(date) as dates from fasstr_flows where station_number = stn
  )
  select fasstr_calc_annual_lowflows(dates, values) from flowdata
$$
LANGUAGE 'sql'
;
