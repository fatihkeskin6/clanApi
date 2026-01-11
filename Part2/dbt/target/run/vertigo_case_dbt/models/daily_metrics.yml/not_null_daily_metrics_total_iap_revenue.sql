
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select total_iap_revenue
from `vertigo-483902`.`vertigo_case`.`daily_metrics`
where total_iap_revenue is null



  
  
      
    ) dbt_internal_test