
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from (select * from `vertigo-483902`.`vertigo_case`.`daily_metrics` where arpdau is not null) dbt_subquery

where not(arpdau >= 0)


  
  
      
    ) dbt_internal_test