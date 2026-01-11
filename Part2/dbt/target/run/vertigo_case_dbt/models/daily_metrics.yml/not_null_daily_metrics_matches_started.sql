
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select matches_started
from `vertigo-483902`.`vertigo_case`.`daily_metrics`
where matches_started is null



  
  
      
    ) dbt_internal_test