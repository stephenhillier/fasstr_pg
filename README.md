# FASSTR for PostgreSQL

fasstr_pg provides functions for using the FASSTR R library from within PostgreSQL.

FASSTR: https://bcgov.github.io/fasstr/index.html

## HYDAT and other flow data

These PL/R functions were tested using flow data sourced from [Water Survey of Canada HYDAT data](https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html). However, each function includes a version that accepts arrays of dates and flow values (cubic metres per second).
If you provide flow data in metric m^3/s, the functions should work with data from other sources.

## Installation

If you already have a database with HYDAT data, skip to [Set up fasstr_flows table](#set-up-fasstr_flows-table-recommended-when-using-hydat). Otherwise, follow the steps to set up a new database and populate it with HYDAT data.

### Create a new PostgreSQL database
Start the database by using `docker-compose up`. This will build a container from an image that includes the PL/R extension,
and will also install the FASSTR package.

Download and unzip the HYDAT sqlite3 file from https://collaboration.cmc.ec.gc.ca/cmc/hydrometrics/www/.

Once the database is running, load the HYDAT data with pgloader:

```
pgloader \
    --type sqlite \
    ./Hydat.sqlite3 \
    postgres://fasstr:test_pw@localhost:5432/fasstr
```

### Set up fasstr_flows table (recommended when using HYDAT)
Hydat includes columns like `flow1, flow2, flow3, .... flow31` indicating the flows on different days.
Run the script that transforms the Hydat data into a table with a row for each daily value:

```sh
make setupdb
```

### Install `fasstr` functions.

```sh
make installfunctions
```

## Usage

### fasstr_calc_annual_lowflows

FASSTR docs:  [calc_annual_lowflows](https://bcgov.github.io/fasstr/reference/calc_annual_lowflows.html)

#### fasstr_calc_annual_lowflows(station_number text)

Requires the `fasstr_flows` table.  Accepts a station number and returns the output of `calc_annual_lowflows` for that station.

#### fasstr_calc_annual_lowflows(dates date[], values numeric[])

Accepts an array of dates and an array of values and calls the `calc_annual_lowflows` function.  This allows more flexibility
in filtering data using your own query.

To get inputs in the right format, use a query such as:
```sql
  with flows as (
    select array_agg(value) as values, array_agg(date) as dates from fasstr_flows where station_number = '08NM116'
  )
  select fasstr_calc_annual_lowflows(dates, values) from flows
```

#### Example
```sql
select * from fasstr_calc_annual_lowflows('08NM116')
;
 year |     min_1_day     | min_1_day_doy | min_1_day_date |     min_3_day      | ...
------+-------------------+---------------+----------------+--------------------+
 1949 | 0.623000025749207 |           272 | 1949-09-29     |  0.645666678746541 |
 1950 | 0.623000025749207 |           246 | 1950-09-03     |  0.645666678746541 |
 1951 | 0.623000025749207 |           228 | 1951-08-16     |  0.623000025749207 |
 1952 | 0.850000023841858 |            94 | 1952-04-03     |  0.850000023841858 |
 1953 | 0.340000003576279 |            91 | 1953-04-01     |  0.340000003576279 |
 ...
```

### fasstr_calc_longterm_daily_stats

FASSTR docs:  [calc_longterm_daily_stats](https://bcgov.github.io/fasstr/reference/calc_longterm_daily_stats.html)

#### fasstr_calc_longterm_daily_stats(station_number text)

Requires the `fasstr_flows` table.  Accepts a station number and returns the output of `calc_longterm_daily_stats` for that station.


#### fasstr_calc_longterm_daily_stats(dates date[], values numeric[])

Accepts an array of dates and an array of values and calls the `calc_longterm_daily_stats` function.

To get inputs in the right format, use a query such as:
```sql
  with flows as (
    select array_agg(value) as values, array_agg(date) as dates from fasstr_flows where station_number = '08NM116'
  )
  select fasstr_calc_longterm_daily_stats(dates, values) from flows
```

#### Example

```sql
select * from fasstr_calc_longterm_daily_stats('08NM116');
   month   |       mean       |      median       |     maximum      |      minimum      |        p10        |       p90        
-----------+------------------+-------------------+------------------+-------------------+-------------------+------------------
 Jan       | 1.09058498838921 | 0.906000018119812 |              9.5 | 0.159999996423721 | 0.537999987602234 | 1.68900004625321
 Feb       |  1.1039543917201 | 0.925999999046326 | 5.80999994277954 | 0.140000000596046 | 0.509999990463257 |  1.8400000333786
 Mar       | 1.72325613348269 |  1.21000003814697 |             17.5 | 0.379999995231628 |  0.71839998960495 | 3.32599992752075
 Apr       | 7.06154597225279 |  4.46000003814697 |             53.5 | 0.340000003576279 |  1.20000004768372 |               16
 May       | 23.8497517273223 |  21.5500001907349 |             87.5 | 0.820999979972839 |  9.15999984741211 |            40.75
 Jun       | 22.0711929331011 |  19.7999992370605 | 86.1999969482422 | 0.449999988079071 |  6.09000015258789 | 40.2999992370605
 Jul       | 5.79640939418912 |  3.61999988555908 | 76.8000030517578 | 0.331999987363815 |  1.02699997425079 | 12.8300000190735
 Aug       | 2.04346867684087 |  1.45000004768372 | 22.3999996185303 | 0.310999989509583 | 0.706199979782105 | 3.95000004768372
 Sep       | 2.36324444348397 |  1.54999995231628 | 18.2999992370605 | 0.354000002145767 | 0.694899994134903 | 4.84999990463257
 Oct       | 2.09998844200609 |  1.62999999523163 | 15.1999998092651 | 0.025000000372529 | 0.794000029563904 | 4.05000019073486
 Nov       | 1.88178050293113 |  1.55499994754791 | 11.6999998092651 | 0.259999990463257 | 0.607999980449677 | 3.48000001907349
 Dec       |  1.2504601344439 |  1.07000005245209 | 7.30000019073486 | 0.244000002741814 | 0.540000021457672 | 2.15800008773804
 Long-term | 6.54281997467418 |  1.83000004291534 |             87.5 | 0.025000000372529 | 0.700999975204468 |               21
 ```
 
### fasstr_compute_frequency_quantile

 FASSTR docs: [compute_frequency_quantile](https://bcgov.github.io/fasstr/reference/compute_frequency_quantile.html)

#### fasstr_compute_frequency_quantile(station_number text, ...)
```sql
fasstr_compute_frequency_quantile(
  stn text,
  roll_days integer,
  return_period integer,
  summer boolean default FALSE,
  ignore_missing boolean default FALSE
)
```

Requires the `fasstr_flows` table.  Accepts a station number, the number of days for a rolling mean (`roll_days`), and a return period (`return_period`); returns the output of `compute_frequency_quantile` for that station.

`roll_days`: Number of days for a rolling mean (required).

`return_period`: Return period in years  (required).

`summer`: boolean flag to indicate whether to calculate for all months or only summer months:  **note**: this is a hack to get around weird behavior going from PostgreSQL arrays to R vectors in PL/R. Summer is Jul-Sept (i.e. `7:9` in the FASSTR R package argument format). Default `FALSE`.
In the future, I hope to support input of months directly.


#### fasstr_compute_frequency_quantile(dates date[], values numeric[], ...)
```sql
fasstr_compute_frequency_quantile(
  dates date[],
  flows numeric[],
  roll_days integer,
  return_period integer,
  summer boolean default FALSE,
  ignore_missing boolean default FALSE
)
```

Accepts an array of dates and an array of values and calls the `compute_frequency_quantile` function. The other arguments are the same as above.

#### Example

Computing the 7 day 10 year return flow (7Q10):

```sql
select fasstr_compute_frequency_quantile('08NM116', roll_days => 7, return_period => 10 ) as "7q10";
       7q10        
-------------------
 0.334462171450288
(1 row)
```

