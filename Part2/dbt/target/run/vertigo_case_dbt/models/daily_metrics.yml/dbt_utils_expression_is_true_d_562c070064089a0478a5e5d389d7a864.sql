
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `vertigo-483902`.`vertigo_case`.`daily_metrics`

where not(defeat_ratio defeat_ratio between 0 and 1)


  
  
      
    ) dbt_internal_test