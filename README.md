# Clan API (Part 1)

 **FastAPI + PostgreSQL** service to manage clans, deployed on **Google Cloud Platform**.

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
  "name": "Tokyo Crew",
  "region": "ap"
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

`GET /clans/search?name=tok`

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
<img width="750" height="437" alt="image" src="https://github.com/user-attachments/assets/c1938de6-3b02-4974-921e-57e15742eb21" />

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

### Layered Data Flow

CSV files  
→ BigQuery raw table  
→ staging models  
→ intermediate models  
→ mart models (analytics-ready)

---

### Project Structure (Part 2)

```
Part2/dbt/
- models/
  - staging/
    - sources.yml
    - stg_user_level_daily_metrics.sql
  - intermediate/
    - int_daily_metrics_agg.sql
  - marts/
    - daily_metrics.sql
    - daily_metrics.yml
```
---

### Initialization: Load CSVs into BigQuery

Script: `Part2/data_sender_to_bq/sender.py`

What it does:
- Reads multiple CSV files from `data/`
- Loads them into BigQuery
- First file uses `WRITE_TRUNCATE`
- Remaining files use `WRITE_APPEND`


---
## Staging Layer

**Model:** `stg_user_level_daily_metrics`

Purpose:
- Acts as a thin cleaning layer on top of the raw BigQuery table
- Keeps transformations explicit and easy to audit

Responsibilities:
- Reads from the raw source table `vertigo_case.user_level_daily_metrics`
- Trims and normalizes string fields
- Converts empty or null `country` values to `UNKNOWN`
- Normalizes `platform` values
- Converts null numeric values to `0`
- Filters out records with null `event_date`

This layer does not perform any aggregation.

## Intermediate Layer

**Model:** `int_daily_metrics_agg`

Purpose:
- Performs heavy aggregations once
- Prepares metrics required by multiple KPIs

Responsibilities:
- Groups data by:
  - event_date
  - country
  - platform
- Calculates:
  - Daily Active Users (DAU)
  - Revenue totals
  - Match counts
  - Victory and defeat counts
  - Server error totals

This layer keeps raw totals separate from ratio calculations.

---

## Mart Layer (Analytics)

**Model:** `daily_metrics`

Purpose:
- Final analytics-ready dataset
- Directly consumed by BI tools

Responsibilities:
- Calculates final KPIs confirming business logic:
  - ARPDAU
  - Matches per DAU
  - Win and defeat ratios
  - Server error rate per DAU
- Uses SAFE_DIVIDE to prevent divide-by-zero errors
- Produces a clean, documented, and tested dataset
<img width="371" height="147" alt="image" src="https://github.com/user-attachments/assets/684639a7-168b-49c3-ae0a-c6f7aed52942" />

---
## Data Quality & Testing

### Source Tests (sources.yml)
- Critical fields must not be null
- Numeric fields must be non-negative

### Model Tests (daily_metrics.yml)
- platform must be ANDROID or IOS
- Revenue and count metrics must be >= 0
- Ratio metrics must be between 0 and 1
- Some tests are filtered with `where: metric is not null`
  because SAFE_DIVIDE can legitimately return NULL
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





