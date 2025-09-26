-- Sales Summary Mart
-- This model provides aggregated sales metrics for reporting

with sales_data as (
    select * from {{ ref('stg_sales') }}
),

daily_sales as (
    select
        order_date,
        year,
        month,
        day_of_week,
        count(*) as total_orders,
        count(distinct customer_id) as unique_customers,
        count(distinct product_id) as unique_products,
        sum(order_amount) as total_revenue,
        avg(order_amount) as avg_order_value,
        sum(quantity) as total_quantity_sold,
        sum(case when order_status = 'delivered' then order_amount else 0 end) as delivered_revenue,
        sum(case when order_status = 'cancelled' then order_amount else 0 end) as cancelled_revenue,
        sum(has_data_quality_issues) as data_quality_issues
    from sales_data
    where order_date is not null
    group by order_date, year, month, day_of_week
),

monthly_sales as (
    select
        year,
        month,
        count(*) as total_orders,
        count(distinct customer_id) as unique_customers,
        count(distinct product_id) as unique_products,
        sum(order_amount) as total_revenue,
        avg(order_amount) as avg_order_value,
        sum(quantity) as total_quantity_sold,
        sum(case when order_status = 'delivered' then order_amount else 0 end) as delivered_revenue,
        sum(case when order_status = 'cancelled' then order_amount else 0 end) as cancelled_revenue,
        sum(has_data_quality_issues) as data_quality_issues,
        round((sum(case when order_status = 'delivered' then order_amount else 0 end)::float / 
               nullif(sum(order_amount), 0)::float) * 100, 2) as delivery_rate
    from sales_data
    where order_date is not null
    group by year, month
),

customer_metrics as (
    select
        customer_id,
        count(*) as total_orders,
        sum(order_amount) as total_spent,
        avg(order_amount) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(distinct order_date) as active_days,
        sum(case when order_status = 'delivered' then 1 else 0 end) as successful_orders,
        sum(case when order_status = 'cancelled' then 1 else 0 end) as cancelled_orders
    from sales_data
    group by customer_id
),

product_metrics as (
    select
        product_id,
        count(*) as total_orders,
        sum(quantity) as total_quantity_sold,
        sum(order_amount) as total_revenue,
        avg(unit_price) as avg_unit_price,
        count(distinct customer_id) as unique_customers,
        count(distinct order_date) as active_days
    from sales_data
    group by product_id
)

select
    'daily' as metric_type,
    order_date as metric_date,
    year,
    month,
    day_of_week,
    total_orders,
    unique_customers,
    unique_products,
    total_revenue,
    avg_order_value,
    total_quantity_sold,
    delivered_revenue,
    cancelled_revenue,
    data_quality_issues,
    null as delivery_rate
from daily_sales

union all

select
    'monthly' as metric_type,
    make_date(year, month, 1) as metric_date,
    year,
    month,
    null as day_of_week,
    total_orders,
    unique_customers,
    unique_products,
    total_revenue,
    avg_order_value,
    total_quantity_sold,
    delivered_revenue,
    cancelled_revenue,
    data_quality_issues,
    delivery_rate
from monthly_sales

order by metric_type, metric_date desc

