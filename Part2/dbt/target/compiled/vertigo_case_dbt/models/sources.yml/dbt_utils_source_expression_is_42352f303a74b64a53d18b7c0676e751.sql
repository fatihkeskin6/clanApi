



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics` where ad_revenue is not null) dbt_subquery

where not(ad_revenue >= 0)

