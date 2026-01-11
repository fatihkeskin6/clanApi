
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_ad_revenue
from `vertigo-483902`.`vertigo_case`.`daily_metrics`
where total_ad_revenue is null



  
  
      
    ) dbt_internal_test