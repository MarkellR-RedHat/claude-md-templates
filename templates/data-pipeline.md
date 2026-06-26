# CLAUDE.md - Data Pipeline Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your pipeline framework (Spark, Beam, Flink, or plain Python) -->
<!-- TODO: Set your orchestrator (Airflow, Tekton, Argo, or Prefect) -->
<!-- TODO: Set your storage layer (S3, GCS, HDFS, ADLS) -->
<!-- TODO: Set your table format (Delta Lake, Apache Iceberg, Hive, or raw Parquet) -->
<!-- TODO: Set your schema registry (Confluent, AWS Glue, Apicurio) -->
<!-- TODO: Set your message broker (Kafka, Pulsar, Kinesis, or none for batch-only) -->
<!-- TODO: Set your data quality framework (Great Expectations, Soda, dbt tests) -->
<!-- TODO: Set your CI/CD system (Tekton, GitHub Actions, Jenkins) -->

## Project Overview

This is a data pipeline project. It ingests, transforms, validates, and delivers data across systems with a focus on correctness, idempotency, and operational reliability.

### Architecture Pattern

<!-- TODO: Uncomment the pattern that matches your project -->

<!-- Batch: Scheduled transforms over bounded datasets. Each run processes a complete partition. -->
<!-- Streaming: Continuous processing of unbounded data. Requires windowing and checkpoints. -->
<!-- Hybrid: Streaming for low-latency views, batch for corrections and backfills. -->

### Key Principles

- **Idempotency first.** Every pipeline run must produce the same output for the same input, regardless of how many times it runs.
- **Schema as contract.** Schemas are versioned, enforced at pipeline boundaries, and evolved through a compatibility process.
- **Partition as unit of work.** A partition (usually date-based) is the atomic unit of processing, backfill, and validation.
- **Fail loud, recover gracefully.** Bad data triggers alerts, not silent corruption. A single bad record does not take down the pipeline.
- **Test with real shapes.** Unit tests with three-row DataFrames catch syntax errors. Integration tests with realistic distributions catch production failures.

## Project Structure

```
project-root/
  pipelines/
    ingestion/
      source_a/
        pipeline.py          # Main pipeline logic
        schema.py            # Input/output schema definitions
        transforms.py        # Transform functions (pure, testable)
        config.py            # Pipeline-specific configuration
    enrichment/
      enrich_user_events/
    aggregation/
      daily_metrics/
  schemas/
    avro/                    # Avro schema files (.avsc)
    protobuf/                # Protobuf definitions (.proto)
    json_schema/             # JSON Schema files
    registry/                # Schema registry configs and migration scripts
  dags/
    ingestion_dag.py         # Airflow DAG definitions
    enrichment_dag.py
    backfill_dag.py
    common/
      operators.py           # Custom Airflow operators
      sensors.py             # Custom sensors
      callbacks.py           # Alert and SLA callbacks
  tekton/
    pipelines/               # Tekton Pipeline definitions
    tasks/                   # Tekton Task definitions
  quality/
    expectations/            # Great Expectations suites
    contracts/               # Data contract definitions
  config/
    environments/
      dev.yaml
      staging.yaml
      prod.yaml
    sources.yaml             # Source system connection configs
    sinks.yaml               # Destination configs
  tests/
    unit/
      test_transforms.py
      test_schemas.py
    integration/
      test_pipeline_e2e.py
    fixtures/
      sample_data/           # Small representative datasets
      expected_output/       # Expected transform results
    conftest.py
  monitoring/
    dashboards/              # Grafana dashboard JSON exports
    alerts/                  # Alert rule definitions
    runbooks/                # Operational runbooks
  scripts/
    backfill.py
    validate.py
  pyproject.toml
  Containerfile
  Makefile
```

### Layout Rules

- Each pipeline lives in its own directory with its own schema, transforms, and config. Do not share transform logic between pipelines unless it is extracted into a shared library with its own tests.
- Keep transforms as pure functions that take and return DataFrames. This makes them testable without spinning up Spark or Beam.
- DAG definitions are thin orchestration layers. They call pipeline code but contain no transform logic.
- Schema files are versioned alongside code. Schema changes go through the same review process as code changes.
- Test fixtures use realistic data shapes. Include nulls, empty strings, boundary timestamps, and Unicode in sample data.

## Apache Spark Patterns

### SparkSession Management

Create one SparkSession per application. Pass it as a parameter to pipeline functions. Never call `getOrCreate()` scattered throughout the codebase.

```python
def get_spark_session(app_name: str, config: dict[str, str] | None = None) -> SparkSession:
    builder = SparkSession.builder.appName(app_name)
    if config:
        for key, value in config.items():
            builder = builder.config(key, value)
    return builder.getOrCreate()
```

### DataFrame Over RDD

Always use the DataFrame API. Never use RDDs unless the DataFrame API genuinely cannot express what you need (this is rare). DataFrames give you Catalyst optimization, Tungsten memory management, schema enforcement, and a composable API.

```python
# Good: DataFrame API
def enrich_events(events: DataFrame, users: DataFrame) -> DataFrame:
    return (
        events.join(users, on="user_id", how="left")
        .withColumn("event_date", F.to_date("event_timestamp"))
        .withColumn("is_active", F.col("last_login_date") >= F.date_sub(F.current_date(), 30))
    )
```

### Partitioning, Joins, and UDFs

```python
# Partition before writing. Target 128MB-256MB per output file for Parquet.
df.repartition(num_partitions).write.partitionBy("date").parquet(output_path)

# Use broadcast joins when one side fits in memory (under ~100MB serialized).
result = large_df.join(F.broadcast(small_lookup_df), on="key_col", how="left")

# Avoid UDFs. They serialize data from Tungsten to Python and back.
# Bad: @F.udf for string splitting. Good: F.split(F.col("email"), "@").getItem(1)
# When unavoidable, use Pandas UDFs for vectorized execution:
@pandas_udf("string")
def normalize_address(addresses: pd.Series) -> pd.Series:
    return addresses.apply(address_lib.normalize)
```

### Caching and Dynamic Allocation

Cache DataFrames only when reused multiple times. Always call `unpersist()` when done.

```python
enriched.persist(StorageLevel.MEMORY_AND_DISK)
daily = compute_daily(enriched)
hourly = compute_hourly(enriched)
enriched.unpersist()
```

Enable dynamic allocation to scale executors based on workload:

```python
spark.conf.set("spark.dynamicAllocation.enabled", "true")
spark.conf.set("spark.dynamicAllocation.minExecutors", "2")
spark.conf.set("spark.dynamicAllocation.maxExecutors", "50")
spark.conf.set("spark.shuffle.service.enabled", "true")
```

## Apache Beam Patterns

### PCollection Transforms

Write transforms as composable `PTransform` subclasses, not inline lambdas.

```python
class ParseAndValidate(beam.PTransform):
    def __init__(self, schema: dict):
        super().__init__()
        self.schema = schema

    def expand(self, pcoll):
        return (
            pcoll
            | "ParseJSON" >> beam.Map(json.loads)
            | "Validate" >> beam.Filter(lambda r: validate(r, self.schema))
            | "AddTimestamp" >> beam.Map(self._add_ts)
        )
```

### Windowing and Triggers

```python
# Fixed windows: non-overlapping time intervals
pcoll | beam.WindowInto(FixedWindows(60 * 5))

# Session windows: group by activity gaps per key
pcoll | beam.WindowInto(Sessions(60 * 30))

# Triggers: balance latency against completeness
pcoll | beam.WindowInto(
    FixedWindows(60 * 5),
    trigger=AfterWatermark(early=AfterProcessingTime(60), late=AfterProcessingTime(600)),
    accumulation_mode=AccumulationMode.ACCUMULATING,
    allowed_lateness=3600,
)
```

### DoFn Lifecycle

Use `setup()` for expensive initialization (DB connections, model loading). Use `start_bundle()`/`finish_bundle()` for batch-level operations. Use `teardown()` to release resources.

### Runner-Agnostic Design

Write pipelines that work on any runner. Do not use runner-specific features in transform code. Pass `PipelineOptions` from the command line to switch between DirectRunner, DataflowRunner, and FlinkRunner.

## Schema Management

### Schema Evolution Strategy

| Mode | Allowed Changes | Use When |
|------|----------------|----------|
| BACKWARD | Add optional fields, remove fields | Consumers upgrade before producers |
| FORWARD | Add fields, remove optional fields | Producers upgrade before consumers |
| FULL | Add/remove optional fields only | Independent upgrades required |
| NONE | Any change | Development only. Never in production |

Decide on a compatibility mode and enforce it through your schema registry. Do not mix modes within a single topic or table.

### Schema Validation in Pipelines

Validate schemas at pipeline boundaries: on ingestion and before writing. Never trust upstream systems to send conforming data. Always define schemas explicitly.

```python
EVENTS_SCHEMA = StructType([
    StructField("event_id", StringType(), nullable=False),
    StructField("user_id", StringType(), nullable=False),
    StructField("event_timestamp", TimestampType(), nullable=False),
    StructField("schema_version", LongType(), nullable=False),
])

df = spark.read.schema(EVENTS_SCHEMA).parquet(path)
```

### Handling Schema Drift

Detect drift proactively. Alert on type changes and missing non-nullable fields. New nullable fields can often be handled automatically.

```python
def detect_schema_drift(actual: StructType, expected: StructType) -> dict:
    actual_f = {f.name: f for f in actual.fields}
    expected_f = {f.name: f for f in expected.fields}
    return {
        "new_fields": set(actual_f) - set(expected_f),
        "missing_fields": set(expected_f) - set(actual_f),
        "type_changes": {
            n for n in actual_f.keys() & expected_f.keys()
            if actual_f[n].dataType != expected_f[n].dataType
        },
    }
```

## Idempotency

### Processing Patterns

**Partition overwrite** (simplest for batch): overwrite the entire partition on each run. Safe to retry.

```python
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")
df.write.mode("overwrite").partitionBy("date").parquet(output_path)
```

**Merge/Upsert** (for incremental loads):

```python
target = DeltaTable.forPath(spark, target_path)
target.alias("t").merge(
    source=incoming_df.alias("s"), condition="t.event_id = s.event_id"
).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
```

**Deduplication window** (for streaming):

```python
df.withWatermark("event_timestamp", "1 hour").dropDuplicatesWithinWatermark(["event_id"])
```

### Checkpoint Management

Each pipeline and each output sink gets its own checkpoint directory. Use durable storage (S3, GCS, HDFS), never local disk. When changing query logic, you may need to reset checkpoints. Document this in your runbook.

## Backfill Strategies

### Partition-Based Backfill

Reprocess one partition at a time using the same pipeline code that handles daily runs.

```python
def backfill_partition(spark, pipeline_fn, date, source_path, target_path):
    input_df = spark.read.parquet(f"{source_path}/date={date}")
    result_df = pipeline_fn(input_df)
    spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")
    result_df.write.mode("overwrite").partitionBy("date").parquet(target_path)
```

### Incremental Backfill

When full partition reprocessing is too expensive, use high-water-mark tracking. Store the last processed timestamp in a metadata store. Only update it after the write is confirmed successful.

### Backfill Validation

Always validate backfill output before marking it complete: check row counts (allow ~5% variance from expected), verify primary keys are non-null, and confirm data falls within expected ranges.

### Schema Changes During Backfill

When backfilling with a newer schema, add missing columns as nulls and drop extra columns to align with the target schema before writing.

## Data Quality

### Data Contracts

Define contracts as code. Each contract specifies what downstream consumers can rely on.

```yaml
# quality/contracts/user_events.yaml
contract:
  name: user_events
  version: 2
  owner: data-platform-team
  sla:
    freshness: 2 hours
    completeness: 99.5%
  schema:
    required_columns:
      - { name: event_id, type: string, nullable: false, unique: true }
      - { name: user_id, type: string, nullable: false }
      - { name: event_timestamp, type: timestamp, nullable: false }
  quality_rules:
    - { type: row_count, min: 1000 }
    - { type: freshness, column: event_timestamp, max_age: "2 hours" }
```

### Core Quality Checks

Every pipeline should validate four dimensions at minimum:

1. **Completeness**: Are required fields populated? Track null percentage per column.
2. **Freshness**: Is the newest record within the SLA window?
3. **Accuracy**: Do values fall within expected ranges?
4. **Consistency**: Do cross-field invariants hold (e.g., end_time > start_time)?

Integrate with Great Expectations, Soda, or your own validation framework. Run checks after every pipeline execution, not as a separate batch job.

## Orchestration

### Airflow DAG Patterns

Keep DAGs simple. A DAG is a scheduling and dependency layer, not a place for business logic.

```python
default_args = {
    "owner": "data-platform",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=30),
    "execution_timeout": timedelta(hours=2),
    # TODO: Set your alert email
    "email": ["data-alerts@example.com"],
    "email_on_failure": True,
}

with DAG(
    dag_id="ingest_user_events",
    default_args=default_args,
    schedule_interval="0 */2 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "user-events"],
) as dag:
    wait_for_source >> ingest >> validate
```

### DAG Design Rules

- One DAG per pipeline domain. No monolithic DAGs.
- Use `catchup=False` unless you specifically need historical backfill through Airflow.
- Set `max_active_runs=1` for pipelines that write to the same output location.
- Use `mode="reschedule"` on sensors to free worker slots during waits.
- Use Jinja templating (`{{ ds }}`, `{{ data_interval_start }}`) for date parameters. Never hardcode dates or call `datetime.now()` inside tasks.
- Set execution timeouts. A 15-minute pipeline should not silently run for 8 hours.

### Tekton Pipeline Integration

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: ingest-user-events
spec:
  params:
    - { name: processing-date, type: string }
  tasks:
    - name: run-pipeline
      taskRef: { name: spark-submit }
      params:
        - { name: args, value: ["--date", "$(params.processing-date)"] }
    - name: validate-output
      taskRef: { name: data-quality-check }
      runAfter: [run-pipeline]
```

### DAG Testing

Test DAGs as code. Validate import errors, schedules, retry configuration, and task dependency ordering.

## Storage Patterns

### Partitioning Schemes

- **Date-based** (best for time-series): `df.write.partitionBy("date").parquet(path)`
- **Hash-based** (best for even distribution): `df.write.bucketBy(64, "user_id").saveAsTable("events")`
- **Composite** (date + low-cardinality dimension): `df.write.partitionBy("date", "region")`

Target 128MB to 1GB per partition file. Under 10MB means your partitioning is too granular. Over 5GB means you need more partition columns or bucketing.

### File Formats

| Format | Best For | Schema Evolution |
|--------|----------|-----------------|
| Parquet | Columnar analytics, universal | Limited (add columns) |
| Delta Lake | ACID transactions, upserts | Full (merge schema) |
| Apache Iceberg | Multi-engine, schema evolution | Full (add, drop, rename, reorder) |

Prefer Iceberg or Delta Lake for new projects. Raw Parquet is fine for simple append-only pipelines.

### Compaction and Retention

Run compaction regularly to fix the small file problem. Automate data retention. Do not rely on humans remembering to clean up.

```python
# Delta Lake
DeltaTable.forPath(spark, path).optimize().executeCompaction()
DeltaTable.forPath(spark, path).vacuum(retentionHours=168)  # 7 days
```

## Performance

### Shuffle Optimization

Shuffles are the most expensive operation. Minimize them: pre-partition data before joins, use broadcast joins for small tables, and enable AQE.

```python
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")
```

### Predicate Pushdown and Partition Pruning

Filter on partition columns first, then narrow non-partition columns, then select only needed columns. Never read everything into Pandas and filter there.

### Memory Tuning

For a 16GB executor: 12g heap, 4g overhead. For Python-heavy workloads (Pandas UDFs, Arrow), shift to 10g heap and 6g overhead. Set `spark.memory.fraction=0.6` and `spark.memory.storageFraction=0.5`.

## Monitoring and Alerting

### Pipeline Health Metrics

Track for every pipeline run: duration, input/output row counts, rejected row count, bytes read/written, output-to-input ratio. Emit to Prometheus, Datadog, or CloudWatch.

### Data Freshness SLAs

Monitor how fresh data is in each table, not just whether pipelines ran. Alert when the newest record exceeds the SLA window.

### Row Count Anomaly Detection

Track row counts over time. Use z-score (threshold of 3 standard deviations) against the last 7+ days of history. A sudden drop or spike usually indicates a problem upstream.

## Testing

### Unit Testing Transforms

```python
@pytest.fixture(scope="session")
def spark():
    return (
        SparkSession.builder.master("local[2]").appName("test")
        .config("spark.sql.shuffle.partitions", "2")
        .config("spark.ui.enabled", "false")
        .getOrCreate()
    )

def test_enrich_events_adds_date_column(spark):
    events = spark.createDataFrame([
        Row(event_id="e1", user_id="u1", event_timestamp=datetime(2024, 1, 15, 10, 30)),
    ])
    users = spark.createDataFrame([
        Row(user_id="u1", last_login_date=date(2024, 1, 14)),
    ])
    result = enrich_events(events, users)
    assert result.collect()[0]["event_date"] == date(2024, 1, 15)
```

### Integration Testing

Test the full pipeline end-to-end: write test input, run the pipeline, validate output (row counts, expected columns, no null primary keys).

### Snapshot Testing

For complex transforms, compare output against a known-good snapshot file. Sort results by primary key for deterministic comparison.

### Contract Testing

Verify output conforms to the published data contract: required columns present with correct types, minimum row counts met, primary keys non-null.

## Security

### Data Classification

| Level | Examples | Handling |
|-------|----------|----------|
| Public | Aggregated metrics | No restrictions |
| Internal | Business reports | Team-level access |
| Confidential | PII, financial records | Encryption, masking, audit |
| Restricted | SSN, health data | Tokenization, dedicated secure zone |

### PII Handling

Never store PII in plaintext outside approved secure zones. Hash emails with SHA-256 for pseudonymous identifiers. Mask phone numbers to last 4 digits. Use salted token columns when reversibility via mapping table is required.

### Access Control and Audit

Use IAM roles per pipeline with least-privilege access. Use table-level grants for Iceberg/Delta. Log all data access operations (pipeline name, operation type, table, columns, row count, timestamp) for compliance.

## Error Handling

### Dead Letter Queues

Route bad records to a dead letter table with rejection timestamp and reason. Never fail the entire pipeline over a single bad record.

### Circuit Breaker Pattern

Stop processing when error rate exceeds a threshold (e.g., 5% of records). Do not let a broken source corrupt your entire data lake.

```python
class CircuitBreaker:
    def __init__(self, max_error_rate: float = 0.05, min_sample_size: int = 100):
        self.max_error_rate = max_error_rate
        self.min_sample_size = min_sample_size

    def check(self, total: int, errors: int) -> None:
        if total >= self.min_sample_size and (errors / total) > self.max_error_rate:
            raise PipelineCircuitBreakerError(
                f"Error rate {errors/total:.2%} exceeds {self.max_error_rate:.2%}. "
                f"Pipeline halted to prevent data corruption."
            )
```

### Graceful Degradation

When an enrichment source is unavailable, proceed with null columns if downstream consumers can handle it. Log a warning, do not fail the pipeline.

## Common Pitfalls

**Small file problem.** Writing too many small files kills read performance. Every file open is a storage round trip. Fix: repartition or coalesce before writing. Run compaction on a schedule.

**Data skew.** One partition has billions of rows, the rest have thousands. Joins on skewed keys cause OOM on the hot executor. Fix: salt skewed keys, enable AQE skew join handling, or pre-aggregate heavy hitters separately.

**OOM in shuffles.** Shuffles spill to disk, then fail when disk fills up. Fix: increase executor memory overhead, enable AQE to auto-coalesce small shuffle partitions.

**Timezone handling.** Timestamps without timezone info cause silent corruption. "2024-01-15 08:00:00" means different things in UTC, EST, and PST. Fix: normalize all timestamps to UTC at ingestion. Set `spark.sql.session.timeZone=UTC`.

**Null handling.** Nulls propagate silently. `NULL != NULL` evaluates to `NULL`, not `TRUE`. Fix: handle nulls explicitly in every transform. Document null semantics in your schema.

**Schema inference.** Never use it in production. It reads extra data, guesses types (often wrong), and creates non-deterministic schemas. Fix: always define schemas explicitly.

## Common Commands

```bash
# TODO: Update for your dependency manager and pipeline entry points

# Set up development environment
uv venv && source .venv/bin/activate && uv pip install -e ".[dev]"

# Run tests
pytest tests/unit/ -x                              # Unit tests (fast)
pytest tests/integration/ -m integration           # Integration tests (requires Spark)

# Lint, format, type check
ruff check pipelines/ tests/ --fix
ruff format pipelines/ tests/
mypy pipelines/

# Run a pipeline locally
python -m pipelines.ingestion.source_a.pipeline --date 2024-01-15 --env dev

# Submit to cluster
spark-submit --master yarn --deploy-mode cluster \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.sql.adaptive.enabled=true \
  pipelines/ingestion/source_a/pipeline.py --date 2024-01-15

# Backfill
python scripts/backfill.py --pipeline ingestion.source_a \
  --start-date 2024-01-01 --end-date 2024-01-31 --parallelism 4

# Validate output
python scripts/validate.py --table user_events --date 2024-01-15 \
  --checks freshness,completeness,row_count

# Test DAG imports
python -c "from airflow.models import DagBag; db = DagBag('dags/'); print(db.import_errors or 'OK')"

# Schema compatibility check
python schemas/registry/check_compatibility.py \
  --subject user-events-value --schema schemas/avro/user_events_v2.avsc

# Build container
podman build -t pipeline-runner:latest .
```

## Review Checklist

### Code Quality
- [ ] All tests pass (`pytest tests/ -x`)
- [ ] Linting clean (`ruff check --diff`)
- [ ] Type hints on all function signatures
- [ ] No hardcoded paths, credentials, or environment-specific values

### Data Correctness
- [ ] Pipeline is idempotent (safe to re-run for any partition)
- [ ] Schema explicitly defined, not inferred
- [ ] Null handling explicit in all transforms
- [ ] Timestamps normalized to UTC
- [ ] Joins account for missing keys (left join nulls handled)

### Schema
- [ ] Changes are backward-compatible (or migration plan documented)
- [ ] Schema registry compatibility check passes
- [ ] Downstream consumers notified
- [ ] Schema version incremented

### Quality and Operations
- [ ] Quality checks cover completeness, freshness, accuracy, consistency
- [ ] Data contract updated if output schema changed
- [ ] DAG has retries, timeouts, SLA monitoring
- [ ] Dead letter queue configured for bad records
- [ ] Circuit breaker threshold set
- [ ] Monitoring dashboards and alerts updated
- [ ] Runbook updated for new failure modes

### Performance
- [ ] Output files 128MB to 1GB (compressed)
- [ ] No unnecessary shuffles; broadcast joins used where applicable
- [ ] Partition strategy matches query patterns
- [ ] No schema inference in production reads
- [ ] Cache only reused DataFrames; unpersist called after

### Security
- [ ] No PII in non-secure zones
- [ ] PII masked, tokenized, or encrypted per data classification
- [ ] Access controls match data sensitivity
- [ ] Audit logging captures data access operations
