



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`daily_metrics` where match_per_dau is not null) dbt_subquery

where not(match_per_dau >= 0)

