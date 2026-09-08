with payments as (
    select * from {{ ref('stg_stripe__payments') }}
)
select sum(amount) as total_revenue
from payments
where status = 'success'