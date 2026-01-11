



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics` where match_start_count is not null) dbt_subquery

where not(match_start_count >= 0)

