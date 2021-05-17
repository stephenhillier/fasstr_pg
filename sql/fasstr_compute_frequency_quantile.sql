-- fasstr_compute_frequency_quantile
-- 
-- examples:
-- 30 day average, 10 year return (30Q10-A)
-- select fasstr_compute_frequency_quantile('08NM116', roll_days => 30, return_period => 10 );
--
-- 7 day average, 10 year return (7Q10-A)
-- select fasstr_compute_frequency_quantile('08NM116', roll_days => 7, return_period => 10 );
--
-- 30 day average, 10 year return, Summer (30Q10-S)
-- select fasstr_compute_frequency_quantile('08NM116', roll_days => 7, return_period => 10, summer=> true );

drop function if exists fasstr_compute_frequency_quantile(date[], numeric[], integer, integer, boolean, boolean);
drop function if exists fasstr_compute_frequency_quantile(text, integer, integer, boolean, boolean);

create or replace function fasstr_compute_frequency_quantile(
  dates date[],
  flows numeric[],
  roll_days integer,
  return_period integer,
  summer boolean default FALSE,
  ignore_missing boolean default FALSE
)
returns numeric as
$$
  library(fasstr)

  months <- if (summer == TRUE) 7:9 else 1:12

  flowdata <- data.frame(Date = dates, Value = flows)
  x <- fasstr::compute_frequency_quantile(
    data=flowdata,
    roll_days=roll_days,
    return_period=return_period,
    months=months,
    ignore_missing=ignore_missing
  )

  return(x)
$$
LANGUAGE 'plr' VOLATILE STRICT;

-- accepts a `station_number` value from the fasstr_flows table.
-- this function creates arrays from the `fasstr_flows` table
-- and then calls the fasstr_compute_frequency_quantile(date[], numeric[], ...)
create or replace function fasstr_compute_frequency_quantile(
  stn text,
  roll_days integer,
  return_period integer,
  summer boolean default FALSE,
  ignore_missing boolean default FALSE
)
returns numeric as
$$
  with flowdata as (
    select array_agg(value) as values, array_agg(date) as dates from fasstr_flows where station_number = stn
  )
  select fasstr_compute_frequency_quantile(dates, values, roll_days, return_period, summer, ignore_missing) from flowdata
$$
LANGUAGE 'sql'
;
