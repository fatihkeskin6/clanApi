-- Aggregation user_level_daily_metrics by event_date, country, platform

with cte as ( -- cte
  select -- Preprocessing query for data cleansing
    *
  from {{ ref('stg_user_level_daily_metrics') }}
),

agg as ( -- aggregation based on event_date, country, platform 
  select
    event_date,
    country,
    platform,

    count(distinct user_id) as dau, -- how many active user based on day+country+platform aggregation

    sum(iap_revenue) as total_iap_revenue,
    sum(ad_revenue) as total_ad_revenue,

    sum(match_start_count) as matches_started,

    -- needed for ratios
    sum(match_end_count) as match_end_count,
    sum(victory_count) as victory_count,
    sum(defeat_count) as defeat_count,

    sum(server_connection_error) as server_connection_error
  from cte
  group by event_date, country, platform
)

select
  *
from agg
