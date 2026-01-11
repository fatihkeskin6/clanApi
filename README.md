# Clan API (Part 1)

 **FastAPI + PostgreSQL** service to manage *clans*, deployed on **Google Cloud Platform**.

- FastAPI REST API
- PostgreSQL persistence on **GCP Cloud SQL**
- Deployed on **Cloud Run**
- Endpoints to **create**, **list**, **search**, and **delete** clans

---

## Architecture Overview

```
Client Request
  |
  v
Cloud Run (FastAPI)
  |
  v
Cloud SQL (PostgreSQL)
```

- Database access is handled via **Cloud SQL**
- Authentication is handled by **Cloud Run service identity**
- Configuration is injected via **environment variables**

---

## Project Structure

```
Part1/
  app/
    main.py          # FastAPI app entrypoint
    router.py        # API routes
    db_conn.py       # DB connection helper (reads DATABASE_URL)
  sample_data_to_db/
    one_time_to_db.py  # One-time CSV loader (used during setup)
```

---

## Database (Cloud SQL – PostgreSQL)

This application uses **Google Cloud SQL for PostgreSQL**.

### Table Definition

The `clans` table is created directly in Cloud SQL.

```sql
CREATE TABLE public.clans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_clans_name_lower --In API '/search' endpoint searches as lower(name)  pgsql cant use index for case-insenseitive search, without index it will apply full scan index. so we apply index lower(name).
  ON public.clans (lower(name));
```
Notes:
- `id` is generated using `gen_random_uuid()` (pgcrypto extension)
- `region` is stored uppercased by the API
- Case-insensitive search is supported via `lower(name)` index
---

## File & Directory Overview

### /app/main.py
- FastAPI application entry point
- Initializes the FastAPI app
- Registers API routes
- Exposes a health check endpoint (`GET /`) to verify service availability

---

### /app/router.py
- Contains all API route definitions
- Implements CRUD-style endpoints for the `clans` resource:
  - Create clan
  - List clans
  - Search clans (case-insensitive)
  - Delete clan
- Handles request validation and basic error handling
- Executes SQL queries using a PostgreSQL connection

---

### /app/db_conn.py
- Database connection helper module
- Reads the `DATABASE_URL` from environment variables
- Creates a PostgreSQL connection using `psycopg`
- Uses dictionary-based row results for easier JSON serialization
- Designed for Cloud Run usage with Cloud SQL

---

### /sample_data_to_db/one_time_to_db.py
- One-time utility script used during initial setup
- Loads sample clan data from a CSV file into the database
- Normalizes input data (uppercases region, validates fields)
- Parses optional timestamps or falls back to current UTC time
- Not used in runtime or production execution

---

## Runtime Configuration (Cloud Run)

The application **relies entirely on environment variables** provided by Cloud Run.

### Required Environment Variable

| Variable | Description |
|--------|-------------|
| `DATABASE_URL` | Cloud SQL PostgreSQL connection string |

Format:
```
postgresql://USERNAME:PASSWORD@/DB_NAME?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
```

In Cloud Run, this is configured via:
- **Cloud Run → Service → Variables & Secrets**

No database credentials are stored in the repository.

---

## Deployment Model (Cloud Run)

This service is continuously deployed from a GitHub repository using
Cloud Run's native source integration. Each commit triggers a new
revision without requiring a separate CI/CD pipeline.


---

## API Endpoints

Base URL:
```
https://clanapi-755545457074.europe-west1.run.app/
```

### Health Check

`GET /`

Response:
```json
{
  "data": {
    "service": "clan-api",
    "status": "ok"
  }
}
```

---

### Create Clan

`POST /clans`

Body:
```json
{
  "name": "Night Owls",
  "region": "eu"
}
```

Rules:
- `name` is required
- `region` is required and normalized to uppercase

<img width="750" height="500" alt="image" src="https://github.com/user-attachments/assets/a44e8871-ffb8-4980-a4ff-c3929c55b2c2" />

---

### List Clans

`GET /clans`

Response:
```json
{
  "data": [...],
  "count": 10
}
```
---

### Search Clans

`GET /clans/search?name=owl`

Rules:
- Minimum **3 characters**
- Case-insensitive search
<img width="750" height="550" alt="image" src="https://github.com/user-attachments/assets/79eb1d38-18ed-4387-b2a0-a09a4b6e7056" />

---

### Delete Clan

`DELETE /clans/{clan_id}`

Rules:
- `clan_id` must be a valid UUID
- Returns 404 if not found
<img width="750" height="439" alt="image" src="https://github.com/user-attachments/assets/3720ddf1-aa0a-429a-8ca0-1d84a2a081df" />

---

## Security Notes

- No credentials are committed to the repository
- Secrets are managed via **Cloud Run environment variables**
- Cloud SQL access is restricted at the network / IAM level

---


# Part 2 — BigQuery + dbt (Analytics)

The goal is to take raw CSV exports, load them into BigQuery, and turn it into an **analytics-ready dataset** using dbt, with tests and documentation included.

---

### High-level Flow

```
CSV files
   |
   v
BigQuery (raw table)
   |
   v
dbt model (analytics)
   |
   v
dbt tests + artifacts
```

- Raw input: CSV files under `data_sender_to_bq/data/`
- Raw table: `vertigo_case.user_level_daily_metrics`
- Analytics output: `daily_metrics` 
- Quality control: dbt tests

---

### Project Structure (Part 2)

```
Part2/
  data_sender_to_bq/
    data/                  # Raw CSV exports
    sender.py              # CSV → BigQuery loader
    vertigo-...json        # LOCAL ONLY service account key

  dbt/
    dbt_project.yml
    packages.yml
    package-lock.yml
    models/
      sources.yml          # Raw table definition + source tests
      daily_metrics.sql    # Analytics transformation
      daily_metrics.yml    # Model docs + tests
    target/                # dbt run/test artifacts
    logs/
    dbt_packages/
```
---

### Step 1 — Load CSVs into BigQuery

Script: `Part2/data_sender_to_bq/sender.py`

What it does:
- Reads multiple CSV files from `data/`
- Loads them into BigQuery
- First file uses `WRITE_TRUNCATE`
- Remaining files use `WRITE_APPEND`

This pattern allows clean table creation followed by incremental appends.
---

### Step 2 — dbt Modeling

Raw event-level data is not analysis-ready.

dbt is used here to:
- Standardize dimensions
- Define KPIs in one place
- Apply consistent null handling
- Enforce data quality with tests

---

### Source (sources.yml)

The raw BigQuery table is registered as a dbt source:

- Dataset: `vertigo_case`
- Table: `user_level_daily_metrics`

Basic source tests are applied:
- Critical fields must not be null
- Numeric fields must be non-negative

This ensures the raw data is reasonable before analytics are built on top.

---

### Analytics Model (daily_metrics.sql)

The model produces daily aggregates grouped by:
- `event_date`
- `country`
- `platform`

Metrics include:
- Daily active users (DAU) : Number of distinct users active on a given day
- In-app and ad revenue totals : Total IAP and ad revenue per day
- ARPDAU : Average Revenue Per Daily Active User
- Match and win/defeat KPIs : Gameplay engagement and outcome ratios
- Server error rates : Server error events normalized per DAU

Data cleanup rules include:
- Missing countries converted to `UNKNOWN`
- Platform normalized to `ANDROID` / `IOS`
- Null numeric values treated as 0
- `SAFE_DIVIDE` used to avoid divide-by-zero failures
```sql
-- Aggregation user_level_daily_metrics by event_date, country, platform

with cte as (
  -- Preprocessing query for data cleansing
  select
    user_id,
    event_date,

    -- Group-by fields
    -- Convert null or empty country values to UNKNOWN
    coalesce(nullif(trim(country), ''), 'UNKNOWN') as country,

    -- Standardize platform values and handle nulls
    coalesce(nullif(upper(trim(platform)), ''), 'UNKNOWN') as platform,

    -- Convert numeric NULLs to 0 to ensure safe aggregations
    coalesce(iap_revenue, 0) as iap_revenue,
    coalesce(ad_revenue, 0) as ad_revenue,
    coalesce(match_start_count, 0) as match_start_count,
    coalesce(match_end_count, 0) as match_end_count,
    coalesce(victory_count, 0) as victory_count,
    coalesce(defeat_count, 0) as defeat_count,
    coalesce(server_connection_error, 0) as server_connection_error

  from {{ source('vertigo_case', 'user_level_daily_metrics') }}
  where event_date is not null
),

agg as (
  -- Aggregate metrics by event_date, country, and platform
  select
    event_date,
    country,
    platform,

    count(distinct user_id) as dau,

    sum(iap_revenue) as total_iap_revenue,
    sum(ad_revenue) as total_ad_revenue,
    sum(match_start_count) as matches_started,

    -- Values required for ratio calculations
    sum(match_end_count) as match_end_count,
    sum(victory_count) as victory_count,
    sum(defeat_count) as defeat_count,
    sum(server_connection_error) as server_connection_error

  from cte
  group by event_date, country, platform
)

-- Final KPI layer
select
  event_date,
  country,
  platform,

  dau,

  total_iap_revenue,
  total_ad_revenue,

  safe_divide(total_iap_revenue + total_ad_revenue, dau) as arpdau,

  matches_started,
  safe_divide(matches_started, dau) as match_per_dau,

  safe_divide(victory_count, match_end_count) as win_ratio,
  safe_divide(defeat_count, match_end_count) as defeat_ratio,

  safe_divide(server_connection_error, dau) as server_error_per_dau

from agg
---

### Model Tests & Documentation (daily_metrics.yml)

This file adds:
- Model-level documentation
- Column descriptions
- Data quality tests

Examples:
- `platform` must be `ANDROID` or `IOS`
- Revenue and counts must be >= 0
- Ratio metrics must be between 0 and 1

Some tests are filtered with `where: metric is not null` because `SAFE_DIVIDE` can
legitimately return NULL when the denominator is zero.



---

### dbt Artifacts

File: `dbt/target/run_results.json`

This shows:
- Whether models and tests succeeded
- The actual SQL executed in BigQuery
- Execution metadata and cost signals

All models and tests in this case ran successfully.

---

### Big Query: daily_metrics

<img width="1328" height="333" alt="Screenshot 2026-01-11 at 21 40 49" src="https://github.com/user-attachments/assets/71aad318-fe74-4c46-98f8-f59aff29830e" />

### Looker: Dashboard

<img width="1536" height="847" alt="image" src="https://github.com/user-attachments/assets/000682b7-1d17-4dae-a20d-fb3d76526a0d" />

https://lookerstudio.google.com/s/gq-6b3OewX8













