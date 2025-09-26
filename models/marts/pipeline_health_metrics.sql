-- Pipeline Health Metrics Mart
-- This model provides comprehensive health metrics for all pipelines

with pipeline_executions as (
    select
        pipeline_name,
        run_id,
        status,
        started_at,
        completed_at,
        execution_time_seconds,
        execution_status,
        performance_category,
        is_failure
    from {{ ref('stg_pipeline_logs') }}
),

daily_metrics as (
    select
        pipeline_name,
        started_at::date as execution_date,
        count(*) as total_runs,
        sum(case when execution_status = 'success' then 1 else 0 end) as successful_runs,
        sum(case when execution_status = 'error' then 1 else 0 end) as failed_runs,
        avg(execution_time_seconds) as avg_execution_time,
        max(execution_time_seconds) as max_execution_time,
        min(execution_time_seconds) as min_execution_time
    from pipeline_executions
    group by pipeline_name, started_at::date
),

weekly_metrics as (
    select
        pipeline_name,
        date_trunc('week', execution_date) as week_start,
        count(*) as total_runs,
        sum(successful_runs) as successful_runs,
        sum(failed_runs) as failed_runs,
        avg(avg_execution_time) as avg_execution_time,
        max(max_execution_time) as max_execution_time,
        min(min_execution_time) as min_execution_time
    from daily_metrics
    group by pipeline_name, date_trunc('week', execution_date)
),

recent_failures as (
    select
        pipeline_name,
        count(*) as recent_failures
    from pipeline_executions
    where execution_status = 'error'
    and started_at >= current_timestamp - interval '7 days'
    group by pipeline_name
),

performance_trends as (
    select
        pipeline_name,
        execution_date,
        avg_execution_time,
        lag(avg_execution_time) over (
            partition by pipeline_name 
            order by execution_date
        ) as previous_avg_execution_time,
        case
            when lag(avg_execution_time) over (
                partition by pipeline_name 
                order by execution_date
            ) is not null
            then avg_execution_time - lag(avg_execution_time) over (
                partition by pipeline_name 
                order by execution_date
            )
            else null
        end as execution_time_change
    from daily_metrics
)

select
    d.pipeline_name,
    d.execution_date,
    d.total_runs,
    d.successful_runs,
    d.failed_runs,
    round((d.successful_runs::float / nullif(d.total_runs, 0)::float) * 100, 2) as success_rate,
    d.avg_execution_time,
    d.max_execution_time,
    d.min_execution_time,
    coalesce(f.recent_failures, 0) as recent_failures,
    pt.execution_time_change,
    case
        when coalesce(f.recent_failures, 0) > 3 then 'CRITICAL'
        when coalesce(f.recent_failures, 0) > 1 then 'WARNING'
        when round((d.successful_runs::float / nullif(d.total_runs, 0)::float) * 100, 2) < 95 then 'WARNING'
        else 'HEALTHY'
    end as health_status,
    current_timestamp as metrics_updated_at
from daily_metrics d
left join recent_failures f on d.pipeline_name = f.pipeline_name
left join performance_trends pt on d.pipeline_name = pt.pipeline_name 
    and d.execution_date = pt.execution_date
order by d.pipeline_name, d.execution_date desc

