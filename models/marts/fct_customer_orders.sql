-- Import CTEs
with
    customers as (select * from {{ source("jaffle_shop", "customers") }}),

    orders as (select * from {{ source("jaffle_shop", "orders") }}),

    payments as (select * from {{ source("stripe", "payment") }}),

    -- Logical CTEs
    payments_aggregated as (

        select
            payments.orderid as order_id,
            max(payments.created) as payment_finalized_date,
            sum(payments.amount) / 100.0 as total_amount_paid
        from payments
        where payments.status <> 'fail'
        group by payments.orderid

    ),

    paid_orders as (

        select
            orders.id as order_id,
            orders.user_id as customer_id,
            orders.order_date as order_placed_at,
            orders.status as order_status,
            payments_aggregated.total_amount_paid,
            payments_aggregated.payment_finalized_date,
            customers.first_name as customer_first_name,
            customers.last_name as customer_last_name
        from orders
        left join payments_aggregated on orders.id = payments_aggregated.order_id
        left join customers on orders.user_id = customers.id

    ),

    -- Final CTE
    final as (

        select
            paid_orders.*,

            -- Transaction sequence across all orders
            row_number() over (order by paid_orders.order_id) as transaction_seq,

            -- Transaction sequence within each customer
            row_number() over (
                partition by paid_orders.customer_id order by paid_orders.order_id
            ) as customer_sales_seq,

            -- First order date for each customer
            first_value(paid_orders.order_placed_at) over (
                partition by paid_orders.customer_id
                order by paid_orders.order_placed_at
                rows between unbounded preceding and unbounded following
            ) as fdos,

            -- New vs returning customer
            case
                when
                    paid_orders.order_placed_at
                    = first_value(paid_orders.order_placed_at) over (
                        partition by paid_orders.customer_id
                        order by paid_orders.order_placed_at
                        rows between unbounded preceding and unbounded following
                    )
                then 'new'
                else 'return'
            end as nvsr,

            -- Cumulative customer lifetime value
            sum(paid_orders.total_amount_paid) over (
                partition by paid_orders.customer_id
                order by paid_orders.order_id
                rows between unbounded preceding and current row
            ) as customer_lifetime_value

        from paid_orders

    )

select *
from final
