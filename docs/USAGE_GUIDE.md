# Usage Guide

This guide provides detailed instructions on how to use the Pipeline Engineering Framework for common data engineering tasks.

## 🎯 Core Capabilities in Action

### 1. Code Generation

#### Natural Language to SQL Translation

**Example 1: Basic Aggregation**
```
User: "Create a model that shows daily sales totals by product category"

AI Response:
- Identifies this as a Code Generation request
- Generates dbt model with proper SQL
- Includes data quality considerations
- Provides implementation guidance
```

**Example 2: Complex Business Logic**
```
User: "Build a customer segmentation model based on RFM analysis"

AI Response:
- Creates staging models for recency, frequency, monetary calculations
- Implements segmentation logic
- Adds appropriate tests and documentation
- Provides business context and interpretation
```

#### Model Template Generation

**Available Templates:**
- **Staging Models**: Data cleaning and standardization
- **Mart Models**: Business logic and aggregations
- **Bridge Models**: Many-to-many relationships
- **Snapshot Models**: Slowly changing dimensions

### 2. Test and Constraint Generation

#### Automated Test Creation

**Example 1: Basic Data Quality Tests**
```
User: "Make sure the 'email' column in my 'customers' table is never null and has valid format"

AI Response:
- Generates not_null test
- Creates custom regex validation test
- Provides YAML configuration
- Explains test purpose and failure scenarios
```

**Example 2: Business Rule Validation**
```
User: "Ensure that order amounts are always positive and delivery dates are after order dates"

AI Response:
- Creates custom tests for business rules
- Implements referential integrity checks
- Provides test configuration
- Explains validation logic
```

#### Test Types Available

1. **Standard dbt Tests**
   - `not_null`: Ensures no null values
   - `unique`: Validates uniqueness
   - `accepted_values`: Checks against allowed values
   - `relationships`: Foreign key validation

2. **Custom Tests**
   - Data quality scoring
   - Business logic validation
   - Performance benchmarks
   - Data freshness checks

### 3. Debugging and Observability

#### Pipeline Error Analysis

**Example 1: Model Failure Debugging**
```
User: "My 'sales_summary' model is failing with a division by zero error"

AI Response:
- Analyzes the error logs
- Identifies the root cause
- Suggests fixes (null handling, default values)
- Provides corrected SQL
- Adds preventive tests
```

**Example 2: Performance Issues**
```
User: "My pipeline is running 3x slower than usual"

AI Response:
- Reviews execution metrics
- Identifies bottlenecks
- Suggests optimizations (indexing, query structure)
- Provides performance monitoring setup
- Creates alerts for future issues
```

#### Observability Features

1. **Pipeline Health Dashboard**
   - Real-time execution status
   - Success/failure rates
   - Performance metrics
   - Data quality scores

2. **Alerting System**
   - Model execution failures
   - Data quality issues
   - Performance degradation
   - Stale data detection

3. **Monitoring Macros**
   - Pipeline logging
   - Performance tracking
   - Anomaly detection
   - Health reporting

### 4. Feedback Loop

#### Continuous Improvement

**Quality Metrics Tracking:**
- Data quality scores over time
- Test pass rates
- Performance trends
- Error frequencies

**Automated Optimization:**
- Query performance analysis
- Test coverage assessment
- Data quality improvement suggestions
- Pipeline optimization recommendations

## 🛠️ Practical Examples

### Example 1: E-commerce Data Pipeline

**Scenario**: Building a complete e-commerce analytics pipeline

**Step 1: Staging Models**
```sql
-- models/staging/stg_orders.sql
with source_orders as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    customer_id,
    order_date,
    order_status,
    order_amount,
    created_at,
    updated_at
from source_orders
```

**Step 2: Data Quality Tests**
```yaml
# tests/orders_tests.yml
models:
  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - not_null
          - unique
      - name: order_amount
        tests:
          - not_null
          - dbt_utils.accepted_range:
              min_value: 0
```

**Step 3: Business Logic Models**
```sql
-- models/marts/daily_sales.sql
with daily_sales as (
    select
        order_date,
        sum(order_amount) as total_revenue,
        count(*) as total_orders,
        count(distinct customer_id) as unique_customers
    from {{ ref('stg_orders') }}
    group by order_date
)

select * from daily_sales
```

**Step 4: Observability Setup**
```sql
-- Log pipeline execution
{{ log_pipeline_start('ecommerce_pipeline') }}

-- Check for anomalies
{{ check_data_volume_anomaly('stg_orders', 'order_date') }}

-- Generate health report
{{ generate_pipeline_health_dashboard() }}
```

### Example 2: Data Quality Monitoring

**Scenario**: Setting up comprehensive data quality monitoring

**Step 1: Quality Score Calculation**
```sql
-- models/marts/data_quality_scores.sql
with test_results as (
    select
        model_name,
        test_name,
        status,
        executed_at
    from {{ ref('dbt_test_results') }}
),

quality_metrics as (
    select
        model_name,
        count(*) as total_tests,
        sum(case when status = 'pass' then 1 else 0 end) as passed_tests,
        round((sum(case when status = 'pass' then 1 else 0 end)::float / 
               count(*)::float) * 100, 2) as quality_score
    from test_results
    group by model_name
)

select * from quality_metrics
```

**Step 2: Alert Configuration**
```sql
-- models/marts/quality_alerts.sql
with quality_issues as (
    select
        model_name,
        test_name,
        'QUALITY_ALERT' as alert_type,
        'Test ' || test_name || ' failed for model ' || model_name as alert_message
    from {{ ref('dbt_test_results') }}
    where status = 'fail'
    and executed_at >= current_timestamp - interval '1 hour'
)

select * from quality_issues
```

## 🔧 Advanced Usage

### Custom Macros

**Creating Reusable Functions:**
```sql
-- macros/data_quality_helpers.sql
{% macro validate_email_format(email_column) %}
  {{ email_column }} ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
{% endmacro %}
```

**Using Custom Macros:**
```sql
-- In your models
select
    customer_id,
    email,
    case 
        when {{ validate_email_format('email') }} then 'valid'
        else 'invalid'
    end as email_status
from customers
```

### Performance Optimization

**Query Optimization:**
```sql
-- Use appropriate materialization strategies
{{ config(materialized='table') }}

-- Add indexes for frequently queried columns
{{ config(
    materialized='table',
    indexes=[
        {'columns': ['customer_id'], 'unique': False},
        {'columns': ['order_date'], 'unique': False}
    ]
) }}
```

**Incremental Models:**
```sql
-- models/marts/incremental_sales.sql
{{ config(materialized='incremental') }}

with new_sales as (
    select * from {{ ref('stg_orders') }}
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
)

select * from new_sales
```

## 📊 Monitoring and Alerting

### Setting Up Alerts

**Email Alerts:**
```yaml
# dbt_project.yml
models:
  pipeline_engineering_framework:
    +on_run_end: "{{ log_pipeline_end('pipeline_name', run_id) }}"
```

**Slack Integration:**
```sql
-- macros/slack_alerts.sql
{% macro send_slack_alert(message) %}
  {% if target.name == 'prod' %}
    -- Slack webhook integration
    {{ log(message, info=true) }}
  {% endif %}
{% endmacro %}
```

### Health Dashboards

**Pipeline Health Metrics:**
```sql
-- models/marts/pipeline_health.sql
with execution_metrics as (
    select
        pipeline_name,
        count(*) as total_runs,
        sum(case when status = 'success' then 1 else 0 end) as successful_runs,
        avg(execution_time_seconds) as avg_execution_time
    from {{ ref('pipeline_logs') }}
    group by pipeline_name
)

select
    pipeline_name,
    total_runs,
    successful_runs,
    round((successful_runs::float / total_runs::float) * 100, 2) as success_rate,
    avg_execution_time,
    case
        when round((successful_runs::float / total_runs::float) * 100, 2) < 95 then 'CRITICAL'
        when round((successful_runs::float / total_runs::float) * 100, 2) < 98 then 'WARNING'
        else 'HEALTHY'
    end as health_status
from execution_metrics
```

## 🚀 Best Practices

### 1. Model Organization
- Use clear naming conventions
- Separate staging and marts
- Document business logic
- Include data lineage

### 2. Testing Strategy
- Test at multiple levels
- Include business rule tests
- Monitor test performance
- Automate test execution

### 3. Observability
- Log all pipeline executions
- Monitor data quality metrics
- Set up proactive alerting
- Track performance trends

### 4. Documentation
- Document all models and tests
- Include business context
- Maintain data dictionary
- Provide usage examples

## 🔍 Troubleshooting

### Common Issues

**1. Model Compilation Errors**
- Check SQL syntax
- Verify column references
- Ensure proper indentation
- Review macro usage

**2. Test Failures**
- Analyze test results
- Check data quality
- Review business rules
- Update test logic

**3. Performance Issues**
- Review query execution plans
- Check for missing indexes
- Optimize join conditions
- Consider materialization strategies

**4. Data Quality Issues**
- Identify root causes
- Implement data validation
- Add quality checks
- Monitor improvements

### Getting Help

1. Check the logs for error messages
2. Review model documentation
3. Consult the test results
4. Use the observability tools
5. Create an issue with details

