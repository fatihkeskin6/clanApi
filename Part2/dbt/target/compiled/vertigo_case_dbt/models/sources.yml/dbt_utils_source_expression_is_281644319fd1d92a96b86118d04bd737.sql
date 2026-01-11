



select
    1
from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`

where not(iap_revenue  is null OR  >= 0)

