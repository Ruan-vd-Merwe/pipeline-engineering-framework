-- Data Quality Helper Macros
-- These macros provide reusable functions for data quality testing

{% macro generate_data_quality_tests(model_name, columns) %}
  {# 
    Generates comprehensive data quality tests for a given model and columns
    Usage: {{ generate_data_quality_tests('my_table', ['id', 'name', 'email']) }}
  #}
  {% for column in columns %}
    - name: {{ column }}
      tests:
        - not_null
        {% if column.endswith('_id') %}
        - unique
        {% endif %}
        {% if 'email' in column.lower() %}
        - dbt_utils.expression_is_true:
            expression: "{{ column }} ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'"
        {% endif %}
        {% if 'date' in column.lower() %}
        - dbt_utils.expression_is_true:
            expression: "{{ column }} <= current_date"
        {% endif %}
  {% endfor %}
{% endmacro %}

{% macro calculate_data_quality_score(model_name) %}
  {# 
    Calculates a data quality score for a given model
    Returns a score between 0 and 100
  #}
  {% set quality_checks = [
    "not_null",
    "unique", 
    "accepted_values",
    "relationships"
  ] %}
  
  {% set total_checks = quality_checks | length %}
  {% set passed_checks = 0 %}
  
  -- This would be implemented with actual test results
  -- For now, returning a placeholder calculation
  select 
    '{{ model_name }}' as model_name,
    {{ total_checks }} as total_checks,
    {{ passed_checks }} as passed_checks,
    round(({{ passed_checks }}::float / {{ total_checks }}::float) * 100, 2) as quality_score
{% endmacro %}

{% macro validate_email_format(email_column) %}
  {# 
    Validates email format using regex
    Usage: {{ validate_email_format('email') }}
  #}
  {{ email_column }} ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
{% endmacro %}

{% macro validate_phone_format(phone_column) %}
  {# 
    Validates phone number format
    Usage: {{ validate_phone_format('phone') }}
  #}
  length({{ phone_column }}) >= 10 and {{ phone_column }} ~ '^[0-9+\-\s\(\)]+$'
{% endmacro %}

{% macro check_data_freshness(table_name, timestamp_column, max_age_hours=24) %}
  {# 
    Checks if data is fresh (not older than specified hours)
    Usage: {{ check_data_freshness('my_table', 'updated_at', 24) }}
  #}
  select count(*) as stale_records
  from {{ ref(table_name) }}
  where {{ timestamp_column }} < current_timestamp - interval '{{ max_age_hours }} hours'
{% endmacro %}

{% macro generate_quality_report() %}
  {# 
    Generates a comprehensive data quality report
    Shows quality scores for all models
  #}
  with model_tests as (
    select 
      model_name,
      test_name,
      status,
      case when status = 'pass' then 1 else 0 end as passed
    from {{ ref('dbt_test_results') }}
    where test_type in ('not_null', 'unique', 'accepted_values', 'relationships')
  ),
  
  quality_scores as (
    select 
      model_name,
      count(*) as total_tests,
      sum(passed) as passed_tests,
      round((sum(passed)::float / count(*)::float) * 100, 2) as quality_score
    from model_tests
    group by model_name
  )
  
  select 
    model_name,
    total_tests,
    passed_tests,
    quality_score,
    case 
      when quality_score >= 90 then 'Excellent'
      when quality_score >= 80 then 'Good'
      when quality_score >= 70 then 'Fair'
      else 'Poor'
    end as quality_rating
  from quality_scores
  order by quality_score desc
{% endmacro %}

