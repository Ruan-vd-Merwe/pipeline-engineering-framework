-- Observability and Monitoring Helper Macros
-- These macros provide utilities for pipeline monitoring and alerting

{% macro log_pipeline_start(pipeline_name, run_id=none) %}
  {# 
    Logs the start of a pipeline run
    Usage: {{ log_pipeline_start('sales_pipeline', 'run_123') }}
  #}
  {% if run_id is none %}
    {% set run_id = modules.datetime.datetime.now().strftime('%Y%m%d_%H%M%S') %}
  {% endif %}
  
  insert into {{ ref('pipeline_logs') }} (
    run_id,
    pipeline_name,
    status,
    started_at,
    message
  ) values (
    '{{ run_id }}',
    '{{ pipeline_name }}',
    'started',
    current_timestamp,
    'Pipeline {{ pipeline_name }} started at {{ current_timestamp }}'
  );
{% endmacro %}

{% macro log_pipeline_end(pipeline_name, run_id, status='completed', message=none) %}
  {# 
    Logs the end of a pipeline run
    Usage: {{ log_pipeline_end('sales_pipeline', 'run_123', 'completed', 'All models processed successfully') }}
  #}
  {% if message is none %}
    {% set message = 'Pipeline {{ pipeline_name }} {{ status }} at {{ current_timestamp }}' %}
  {% endif %}
  
  insert into {{ ref('pipeline_logs') }} (
    run_id,
    pipeline_name,
    status,
    completed_at,
    message
  ) values (
    '{{ run_id }}',
    '{{ pipeline_name }}',
    '{{ status }}',
    current_timestamp,
    '{{ message }}'
  );
{% endmacro %}

{% macro log_model_execution(model_name, status, rows_affected=none, execution_time=none) %}
  {# 
    Logs model execution details
    Usage: {{ log_model_execution('stg_orders', 'success', 1000, 30.5) }}
  #}
  insert into {{ ref('model_execution_logs') }} (
    model_name,
    status,
    rows_affected,
    execution_time_seconds,
    executed_at
  ) values (
    '{{ model_name }}',
    '{{ status }}',
    {{ rows_affected if rows_affected else 'null' }},
    {{ execution_time if execution_time else 'null' }},
    current_timestamp
  );
{% endmacro %}

{% macro check_data_volume_anomaly(table_name, column_name, threshold_percent=20) %}
  {# 
    Checks for data volume anomalies compared to historical averages
    Usage: {{ check_data_volume_anomaly('sales', 'order_date', 20) }}
  #}
  with daily_counts as (
    select 
      {{ column_name }}::date as date,
      count(*) as record_count
    from {{ ref(table_name) }}
    where {{ column_name }} >= current_date - interval '30 days'
    group by {{ column_name }}::date
  ),
  
  historical_avg as (
    select 
      avg(record_count) as avg_count,
      stddev(record_count) as stddev_count
    from daily_counts
    where date < current_date - interval '7 days'
  ),
  
  current_volume as (
    select 
      count(*) as current_count
    from {{ ref(table_name) }}
    where {{ column_name }}::date = current_date
  )
  
  select 
    '{{ table_name }}' as table_name,
    current_count,
    avg_count,
    stddev_count,
    case 
      when current_count < (avg_count - (stddev_count * 2)) then 'LOW_VOLUME_ALERT'
      when current_count > (avg_count + (stddev_count * 2)) then 'HIGH_VOLUME_ALERT'
      else 'NORMAL'
    end as anomaly_status
  from current_volume, historical_avg
{% endmacro %}

{% macro generate_pipeline_health_dashboard() %}
  {# 
    Generates a comprehensive pipeline health dashboard
    Shows status of all pipelines and models
  #}
  with pipeline_status as (
    select 
      pipeline_name,
      max(case when status = 'started' then started_at end) as last_started,
      max(case when status in ('completed', 'failed') then completed_at end) as last_completed,
      max(case when status = 'failed' then 1 else 0 end) as has_failed
    from {{ ref('pipeline_logs') }}
    group by pipeline_name
  ),
  
  model_status as (
    select 
      model_name,
      max(executed_at) as last_executed,
      max(case when status = 'success' then 1 else 0 end) as last_run_successful,
      avg(execution_time_seconds) as avg_execution_time
    from {{ ref('model_execution_logs') }}
    group by model_name
  ),
  
  test_results as (
    select 
      model_name,
      count(*) as total_tests,
      sum(case when status = 'pass' then 1 else 0 end) as passed_tests
    from {{ ref('dbt_test_results') }}
    group by model_name
  )
  
  select 
    p.pipeline_name,
    p.last_started,
    p.last_completed,
    case when p.has_failed = 1 then 'FAILED' else 'HEALTHY' end as pipeline_status,
    m.model_name,
    m.last_executed,
    case when m.last_run_successful = 1 then 'SUCCESS' else 'FAILED' end as model_status,
    m.avg_execution_time,
    t.total_tests,
    t.passed_tests,
    round((t.passed_tests::float / nullif(t.total_tests, 0)::float) * 100, 2) as test_pass_rate
  from pipeline_status p
  left join model_status m on p.pipeline_name = split_part(m.model_name, '_', 1)
  left join test_results t on m.model_name = t.model_name
  order by p.last_started desc
{% endmacro %}

{% macro create_alert_conditions() %}
  {# 
    Creates alert conditions for monitoring
    Returns records that should trigger alerts
  #}
  with failed_models as (
    select 
      model_name,
      executed_at,
      'MODEL_FAILURE' as alert_type,
      'Model ' || model_name || ' failed at ' || executed_at as alert_message
    from {{ ref('model_execution_logs') }}
    where status = 'failed'
    and executed_at >= current_timestamp - interval '1 hour'
  ),
  
  stale_data as (
    select 
      'stale_data' as table_name,
      'STALE_DATA' as alert_type,
      'Data is older than 24 hours' as alert_message
    from {{ ref('sales') }}
    where updated_at < current_timestamp - interval '24 hours'
    limit 1
  ),
  
  test_failures as (
    select 
      model_name,
      test_name,
      'TEST_FAILURE' as alert_type,
      'Test ' || test_name || ' failed for model ' || model_name as alert_message
    from {{ ref('dbt_test_results') }}
    where status = 'fail'
    and executed_at >= current_timestamp - interval '1 hour'
  )
  
  select * from failed_models
  union all
  select * from stale_data
  union all
  select * from test_failures
{% endmacro %}

