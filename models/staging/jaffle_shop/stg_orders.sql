with raw as 
    (
        select * from {{ source("jaffle_shop", "orders") }}
    ),

transformed as (


)

select * from transformed