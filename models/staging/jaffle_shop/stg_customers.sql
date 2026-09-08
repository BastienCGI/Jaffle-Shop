with raw as 
    (
        select * from {{ source("jaffle_shop", "customers") }}
    ),

transformed as (


)

select * from transformed