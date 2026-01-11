



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`daily_metrics` where defeat_ratio is not null) dbt_subquery

where not(defeat_ratio between 0 and 1)

