# Pipeline Engineering Framework

A comprehensive data engineering framework built on dbt that provides code generation, testing, observability, and debugging capabilities for data pipelines.

## 🚀 Core Capabilities

### 1. Code Generation
- **SQL Generation**: Translate natural language requests into SQL or dbt code
- **Model Templates**: Pre-built templates for common data transformations
- **Macro Library**: Reusable functions for data quality and business logic

### 2. Test and Constraint Generation
- **Automated Testing**: Comprehensive dbt YAML configurations for data quality tests
- **Custom Tests**: Business logic validation and data quality scoring
- **Constraint Management**: Referential integrity and data validation rules

### 3. Debugging and Observability
- **Pipeline Monitoring**: Real-time pipeline health metrics and alerting
- **Error Analysis**: Automated root cause analysis for pipeline failures
- **Performance Tracking**: Execution time monitoring and optimization insights

### 4. Feedback Loop
- **Quality Scoring**: Automated data quality assessment
- **Performance Metrics**: Continuous improvement tracking
- **Alert Management**: Proactive issue detection and notification

## 📁 Project Structure

```
pipeline-engineering-framework/
├── models/
│   ├── staging/          # Staging models for data cleaning
│   └── marts/            # Business logic and aggregated models
├── tests/                # Data quality tests and constraints
├── macros/               # Reusable dbt macros and functions
├── analysis/             # Ad-hoc analysis queries
├── seeds/                # Reference data
├── snapshots/            # Slowly changing dimensions
├── dbt_project.yml       # dbt project configuration
└── profiles.yml          # Database connection profiles
```

## 🛠️ Getting Started

### Prerequisites
- Python 3.7+
- dbt 1.0+
- PostgreSQL (or your preferred database)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pipeline-engineering-framework
   ```

2. **Install dbt**
   ```bash
   pip install dbt-postgres
   ```

3. **Configure your database connection**
   ```bash
   # Copy and edit the profiles.yml file
   cp profiles.yml ~/.dbt/profiles.yml
   ```

4. **Set environment variables**
   ```bash
   export DBT_USER=your_username
   export DBT_PASSWORD=your_password
   export DBT_DATABASE=your_database
   export DBT_SCHEMA=your_schema
   ```

5. **Run the pipeline**
   ```bash
   dbt deps
   dbt seed
   dbt run
   dbt test
   ```

## 🧪 Testing Framework

### Built-in Tests
- **Not Null**: Ensures required fields are populated
- **Unique**: Validates primary keys and unique constraints
- **Accepted Values**: Checks for valid enum values
- **Relationships**: Validates foreign key constraints
- **Data Freshness**: Ensures data is up-to-date

### Custom Tests
- **Data Quality Score**: Calculates overall data quality metrics
- **Business Logic Validation**: Custom rules for domain-specific requirements
- **Performance Tests**: Validates query execution times

### Example Test Configuration
```yaml
models:
  - name: sales
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
              max_value: 1000000
```

## 📊 Observability Features

### Pipeline Health Dashboard
- Real-time pipeline execution status
- Success/failure rates and trends
- Performance metrics and bottlenecks
- Data quality scores

### Alerting System
- Model execution failures
- Data quality issues
- Performance degradation
- Stale data detection

### Monitoring Macros
```sql
-- Log pipeline start
{{ log_pipeline_start('sales_pipeline', 'run_123') }}

-- Check data volume anomalies
{{ check_data_volume_anomaly('sales', 'order_date', 20) }}

-- Generate health dashboard
{{ generate_pipeline_health_dashboard() }}
```

## 🔧 Usage Examples

### 1. Code Generation
**User Request**: "Create a model that calculates customer lifetime value"

**AI Response**: 
```sql
-- models/marts/customer_lifetime_value.sql
with customer_orders as (
    select
        customer_id,
        sum(order_amount) as total_spent,
        count(*) as total_orders,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date
    from {{ ref('stg_sales') }}
    group by customer_id
)

select
    customer_id,
    total_spent as lifetime_value,
    total_orders,
    first_order_date,
    last_order_date,
    current_date - last_order_date as days_since_last_order
from customer_orders
```

### 2. Test Generation
**User Request**: "Ensure the 'product_id' column in my 'sales' table is never null"

**AI Response**:
```yaml
models:
  - name: sales
    columns:
      - name: product_id
        tests:
          - not_null
          - relationships:
              to: ref('products')
              field: product_id
```

### 3. Debugging and Observability
**User Request**: "My pipeline is running slowly, help me identify the issue"

**AI Response**: 
- Analyzes execution logs
- Identifies slow-running models
- Suggests optimization strategies
- Provides performance metrics

## 📈 Data Quality Framework

### Quality Scoring
The framework automatically calculates data quality scores based on:
- Completeness (not null tests)
- Uniqueness (unique constraints)
- Validity (accepted values)
- Consistency (referential integrity)
- Timeliness (freshness tests)

### Quality Reports
```sql
-- Generate quality report
{{ generate_quality_report() }}
```

## 🚨 Alerting and Monitoring

### Alert Conditions
- Model execution failures
- Data quality test failures
- Performance degradation
- Stale data detection
- Volume anomalies

### Alert Management
```sql
-- Check for alert conditions
{{ create_alert_conditions() }}
```

## 🔄 Feedback Loop

### Continuous Improvement
- Track test pass rates over time
- Monitor performance trends
- Identify recurring issues
- Optimize based on metrics

### Quality Metrics
- Data quality scores
- Pipeline success rates
- Execution times
- Error frequencies

## 📚 Documentation

### Model Documentation
Each model includes:
- Description and purpose
- Column definitions
- Business logic explanation
- Data lineage information

### Test Documentation
- Test purpose and scope
- Expected outcomes
- Failure scenarios
- Remediation steps

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions and support:
- Create an issue in the repository
- Check the documentation
- Review the examples in the `models/` directory

## 🔮 Roadmap

- [ ] Machine learning integration for anomaly detection
- [ ] Advanced data lineage visualization
- [ ] Automated performance optimization
- [ ] Integration with popular BI tools
- [ ] Real-time streaming data support

