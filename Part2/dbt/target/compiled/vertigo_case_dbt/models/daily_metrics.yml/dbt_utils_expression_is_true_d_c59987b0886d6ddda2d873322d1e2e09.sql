



select
    1
from `vertigo-483902`.`vertigo_case`.`daily_metrics`

where not(win_ratio win_ratio between 0 and 1)

