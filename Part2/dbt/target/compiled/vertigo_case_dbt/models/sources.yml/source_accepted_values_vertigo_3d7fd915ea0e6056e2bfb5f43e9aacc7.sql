
    
    

with all_values as (

    select
        platform as value_field,
        count(*) as n_records

    from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`
    group by platform

)

select *
from all_values
where value_field not in (
    'ANDROID','IOS'
)


