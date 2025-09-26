-- Pipeline execution logs staging model
-- This model creates a staging table for pipeline execution logs

with pipeline_logs as (
    select
        run_id,
        pipeline_name,
        status,
        started_at,
        completed_at,
        message,
        case 
            when completed_at is not null and started_at is not null 
            then extract(epoch from (completed_at - started_at))
            else null
        end as execution_time_seconds,
        case
            when status = 'completed' then 'success'
            when status = 'failed' then 'error'
            else 'running'
        end as execution_status,
        current_timestamp as processed_at
    from {{ source('logs', 'pipeline_logs') }}
),

enriched_logs as (
    select
        *,
        case
            when execution_time_seconds > 3600 then 'slow'
            when execution_time_seconds > 1800 then 'medium'
            else 'fast'
        end as performance_category,
        case
            when execution_status = 'error' then 1
            else 0
        end as is_failure
    from pipeline_logs
)

select * from enriched_logs

