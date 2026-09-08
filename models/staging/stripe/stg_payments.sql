with raw as 
    (
        select * from {{ source("stripe", "payment") }}
    ),

transformed as (

        select
            orderid as order_id,
            max(created) as payment_finalized_date,
            sum(amount) / 100.0 as total_amount_paid
        from raw
        where status <> 'fail'
        group by orderid

)

select * from transformed