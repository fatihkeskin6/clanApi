-- Aggregation user_level_daily_metrics by event_date, country, platform

with cte as ( -- cte
  select -- Preprocessing query for data cleansing
    user_id,
    event_date,

    -- GRUOP BY FIELDS
    -- some of country values are null, converting it to UNKNOWN to ensure data quality and avoid NULL groups
    coalesce(nullif(trim(country), ''), 'UNKNOWN') as country,
    -- standardize the platform, also null conversion to ensure group by consistency.
    coalesce(nullif(upper(trim(platform)), ''), 'UNKNOWN') as platform,

    -- for numeric fields conversion 'NULL' to 0 to secure calculations
    coalesce(iap_revenue, 0) as iap_revenue,
    coalesce(ad_revenue, 0) as ad_revenue,
    coalesce(match_start_count, 0) as match_start_count,
    coalesce(match_end_count, 0) as match_end_count,
    coalesce(victory_count, 0) as victory_count,
    coalesce(defeat_count, 0) as defeat_count,
    coalesce(server_connection_error, 0) as server_connection_error
  from {{ source('vertigo_case', 'user_level_daily_metrics') }}
  where event_date is not null --this is a daily metric and event_date column is the main purpose of this analytical calculation, cant include nulls in here.
)

select
  *
from cte
