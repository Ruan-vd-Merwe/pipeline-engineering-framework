-- Sales data staging model
-- This model cleans and standardizes sales data from the source

with source_sales as (
    select * from {{ source('raw', 'sales') }}
),

cleaned_sales as (
    select
        -- Primary key
        order_id,
        
        -- Foreign keys
        customer_id,
        product_id,
        
        -- Dimensions
        order_date,
        order_status,
        
        -- Measures
        order_amount,
        quantity,
        unit_price,
        
        -- Metadata
        created_at,
        updated_at,
        
        -- Data quality flags
        case 
            when order_id is null then 1 
            else 0 
        end as has_null_order_id,
        
        case 
            when order_amount < 0 then 1 
            else 0 
        end as has_negative_amount,
        
        case 
            when order_date > current_date then 1 
            else 0 
        end as has_future_date,
        
        -- Calculated fields
        case 
            when quantity > 0 and unit_price > 0 
            then round(quantity * unit_price, 2)
            else order_amount
        end as calculated_amount,
        
        case 
            when order_date is not null 
            then extract(dow from order_date)
            else null
        end as day_of_week,
        
        case 
            when order_date is not null 
            then extract(month from order_date)
            else null
        end as month,
        
        case 
            when order_date is not null 
            then extract(year from order_date)
            else null
        end as year
        
    from source_sales
),

final as (
    select
        *,
        case 
            when has_null_order_id = 1 or has_negative_amount = 1 or has_future_date = 1 
            then 1 
            else 0 
        end as has_data_quality_issues
    from cleaned_sales
)

select * from final

