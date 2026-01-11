
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics`

where not(ad_revenue  is null OR  >= 0)


  
  
      
    ) dbt_internal_test