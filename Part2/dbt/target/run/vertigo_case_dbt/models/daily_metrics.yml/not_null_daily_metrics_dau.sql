
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select dau
from `vertigo-483902`.`vertigo_case`.`daily_metrics`
where dau is null



  
  
      
    ) dbt_internal_test