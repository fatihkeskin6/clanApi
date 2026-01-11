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
