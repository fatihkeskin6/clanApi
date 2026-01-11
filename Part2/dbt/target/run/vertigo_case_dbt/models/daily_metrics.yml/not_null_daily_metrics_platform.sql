
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select platform
from `vertigo-483902`.`vertigo_case`.`daily_metrics`
where platform is null



  
  
      
    ) dbt_internal_test