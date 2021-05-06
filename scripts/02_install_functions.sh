psql $DATABASE_URL -f /sql/fasstr_calc_longterm_daily_stats.sql
psql $DATABASE_URL -f /sql/fasstr_calc_annual_lowflows.sql
