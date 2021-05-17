psql $DATABASE_URL -f /sql/fasstr_calc_longterm_daily_stats.sql
psql $DATABASE_URL -f /sql/fasstr_calc_annual_lowflows.sql
psql $DATABASE_URL -f /sql/fasstr_compute_frequency_quantile.sql
