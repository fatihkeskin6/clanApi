



select
    1
from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`

where not(match_start_count match_start_count is null or match_start_count >= 0)

