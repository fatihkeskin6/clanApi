
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `vertigo-483902`.`vertigo_case`.`daily_metrics`

where not(matches_started >= 0)


  
  
      
    ) dbt_internal_test