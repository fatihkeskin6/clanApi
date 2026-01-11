-- models/daily_metrics.sql
-- Aggregates user_level_daily_metrics by event_date, country, platform

with base as (
  select
    user_id,
    event_date,

    -- country can be null -> bucket it
    coalesce(country, 'UNKNOWN') as country,

    -- normalize platform (e.g., "Android", " IOS ")
    upper(trim(platform)) as platform,

    -- numeric fields: treat null as 0 for sums
    coalesce(iap_revenue, 0) as iap_revenue,
    coalesce(ad_revenue, 0) as ad_revenue,

    coalesce(match_start_count, 0) as match_start_count,
    coalesce(match_end_count, 0) as match_end_count,
    coalesce(victory_count, 0) as victory_count,
    coalesce(defeat_count, 0) as defeat_count,
    coalesce(server_connection_error, 0) as server_connection_error
  from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`
  where event_date is not null
    and platform is not null
),

filtered as (
  select *
  from base
  where platform in ('ANDROID', 'IOS')
),

agg as (
  select
    event_date,
    country,
    platform,

    count(distinct user_id) as dau,

    sum(iap_revenue) as total_iap_revenue,
    sum(ad_revenue) as total_ad_revenue,

    sum(match_start_count) as matches_started,

    -- needed for ratios
    sum(match_end_count) as match_end_count,
    sum(victory_count) as victory_count,
    sum(defeat_count) as defeat_count,

    sum(server_connection_error) as server_connection_error
  from filtered
  group by 1, 2, 3
)

select
  event_date,
  country,
  platform,

  dau,

  total_iap_revenue,
  total_ad_revenue,

  safe_divide(total_iap_revenue + total_ad_revenue, dau) as arpdau,

  matches_started,
  safe_divide(matches_started, dau) as match_per_dau,

  safe_divide(victory_count, match_end_count) as win_ratio,
  safe_divide(defeat_count, match_end_count) as defeat_ratio,

  safe_divide(server_connection_error, dau) as server_error_per_dau
from agg