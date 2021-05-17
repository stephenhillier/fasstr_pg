-- fasstr_calc_longterm_daily_stats
-- example: select * from fasstr_calc_longterm_daily_stats('08NM116')

drop function if exists fasstr_calc_longterm_daily_stats(date[], numeric[], boolean, boolean);
drop function if exists fasstr_calc_longterm_daily_stats(text, boolean, boolean);
drop table if exists longterm_stats;

create table longterm_stats (
  month text,
  mean numeric,
  median numeric,
  maximum numeric,
  minimum numeric,
  p10 numeric,
  p90 numeric
);

-- accepts two arrays for dates and args
create or replace function fasstr_calc_longterm_daily_stats(
  dates date[],
  flows numeric[],
  ignore_missing boolean default FALSE,
  complete_years boolean default FALSE
)
returns setof longterm_stats as
$$
  library(fasstr)

  flowdata <- data.frame(Date = dates, Value = flows)
  x <- fasstr::calc_longterm_daily_stats(
    data=flowdata,
    ignore_missing=ignore_missing,
    complete_years=complete_years
  )

  names(x) <- tolower(names(x))
  return(x)
$$
LANGUAGE 'plr' VOLATILE STRICT;

-- accepts a `station_number` value from the fasstr_flows table.
create or replace function fasstr_calc_longterm_daily_stats(
  stn text,
  ignore_missing boolean default FALSE,
  complete_years boolean default FALSE
)
returns setof longterm_stats as
$$
  with flowdata as (
    select array_agg(value) as values, array_agg(date) as dates from fasstr_flows where station_number = stn
  )
  select fasstr_calc_longterm_daily_stats(dates, values, ignore_missing, complete_years) from flowdata
$$
LANGUAGE 'sql'
;
