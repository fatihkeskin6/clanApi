
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`user_level_daily_metrics` where iap_revenue is not null) dbt_subquery

where not(iap_revenue >= 0)


  
  
      
    ) dbt_internal_test