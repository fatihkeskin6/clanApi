-- Aggregation user_level_daily_metrics by event_date, country, platform

with agg as (
  select
    *
  from {{ ref('int_daily_metrics_agg') }}
)

select -- kpi, finalize
  event_date,
  country,
  platform,

  dau,

  total_iap_revenue,
  total_ad_revenue,

  safe_divide(total_iap_revenue + total_ad_revenue, dau) as arpdau,

  matches_started,
  safe_divide(matches_started, dau) as match_per_dau, -- safe divide to ensure during a/b: if a or b = 0 then instead of infinity, just return NULL

  safe_divide(victory_count, match_end_count) as win_ratio,
  safe_divide(defeat_count, match_end_count) as defeat_ratio,

  safe_divide(server_connection_error, dau) as server_error_per_dau
from agg
