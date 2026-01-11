
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_id
from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`
where user_id is null



  
  
      
    ) dbt_internal_test