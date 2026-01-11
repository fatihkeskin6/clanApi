
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `vertigo-483902`.`vertigo_case`.`daily_metrics`

where not(server_error_per_dau server_error_per_dau >= 0)


  
  
      
    ) dbt_internal_test