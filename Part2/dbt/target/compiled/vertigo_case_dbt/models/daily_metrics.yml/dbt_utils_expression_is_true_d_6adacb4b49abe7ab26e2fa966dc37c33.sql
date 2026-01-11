



select
    1
from `vertigo-483902`.`vertigo_case`.`daily_metrics`

where not(server_error_per_dau server_error_per_dau >= 0)

