# Clan API (Part 1)

A small **FastAPI + PostgreSQL** service to manage *clans*, deployed on **Google Cloud Platform**.

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

---

### Delete Clan

`DELETE /clans/{clan_id}`

Rules:
- `clan_id` must be a valid UUID
- Returns 404 if not found

---

## Security Notes

- No credentials are committed to the repository
- Secrets are managed via **Cloud Run environment variables**
- Cloud SQL access is restricted at the network / IAM level

---


# Part 2 — BigQuery + dbt (Analytics Case)

This part of the case study focuses on:
1) **Loading raw CSV exports into BigQuery**, and  
2) **Building an analytics model with dbt** on top of the raw table, including **data quality tests** and **documented transformations**.

> This is not a web application. It is a data/analytics workflow meant for development and review.

---

## High-level Flow

```
CSV files  ->  BigQuery raw table (user_level_daily_metrics)
                    |
                    v
           dbt model (daily_metrics)
                    |
                    v
           dbt tests + run artifacts
```

- Raw inputs: many CSV files under `data_sender_to_bq/data/`
- Raw storage: BigQuery dataset `vertigo_case` table `user_level_daily_metrics`
- Analytics output: BigQuery view/table `daily_metrics` created by dbt
- Quality gates: dbt tests (not_null, accepted_values, expression checks)

---

## Repository Structure

```
Part2/
  data_sender_to_bq/
    data/                   # Raw CSV files (source exports)
    sender.py               # Loads CSVs into BigQuery
    vertigo-...json         # (LOCAL ONLY) service account key (MUST NOT be committed)

  dbt/
    dbt_project.yml         # dbt project config
    packages.yml            # dbt package dependencies
    package-lock.yml        # resolved dependency versions
    models/
      sources.yml           # BigQuery source definitions + source tests
      daily_metrics.sql     # transformation model (raw -> analytics)
      daily_metrics.yml     # model documentation + model tests
    target/
      run_results.json      # dbt run/test results (generated artifact)
    logs/                   # dbt logs (generated artifacts)
    dbt_packages/           # installed packages (generated)
```

### Notes about generated folders
In a “clean” dbt repo, these are usually not committed:
- `dbt/target/`
- `dbt/logs/`
- `dbt/dbt_packages/`

They are included here because this is a **case study** and the artifacts (like `run_results.json`) help reviewers verify execution.

---

## BigQuery Setup

### Dataset and location
- Project: `vertigo-483902`
- Dataset: `vertigo_case`
- Location: `europe-west1`

Make sure your BigQuery dataset is created in the same location as your jobs, otherwise BigQuery will throw *location mismatch* errors.

---

## Authentication & Authorization (Development)

There are 2 common ways to authenticate during development:

### Option A — Service Account Key (JSON) (used here during development)
A service account key JSON can be used by tools/scripts to authenticate to GCP.

**Important security rule:**
- **Never commit** service account keys to GitHub.
- Add this to your `.gitignore`:
  ```gitignore
  *.json
  Part2/data_sender_to_bq/*.json
  ```

You typically set the environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

On Windows (PowerShell):
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

The service account must have permissions like:
- `BigQuery Data Editor` (write tables)
- `BigQuery Job User` (run load jobs / queries)
- (Optional) `BigQuery Data Viewer` (read)

### Option B — gcloud user auth (recommended for local dev)
```bash
gcloud auth application-default login
```

This creates ADC credentials that many GCP client libraries can use automatically.

---

## Step 1 — Load CSV Data to BigQuery (sender.py)

Folder: `Part2/data_sender_to_bq/`

### What it does
- Reads many CSV files from `data_sender_to_bq/data/`
- Loads them into BigQuery table:
  - First file: typically `WRITE_TRUNCATE` (create/replace)
  - Remaining files: `WRITE_APPEND` (append)

### Why this exists
BigQuery is the “source of truth” for this case. dbt models build on top of the loaded table.

> If you interrupt the first run (Ctrl+C), the destination table might be partially created.
> In that case, re-run with a clean truncate on the first file, or delete/recreate the table.

---

## Step 2 — dbt Project (Transform + Tests)

Folder: `Part2/dbt/`

### Why dbt?
dbt provides:
- **Version-controlled SQL transformations**
- **Repeatable builds** (recreate models consistently)
- **Automated data tests** (quality gates)
- **Documentation** (model + column descriptions)

---

## Source Definition (models/sources.yml)

File: `models/sources.yml`

Defines the raw BigQuery table as a dbt **source**:

- Source: `vertigo_case`
- Table: `user_level_daily_metrics`

It also adds **source-level tests**, such as:
- `not_null` for critical fields (`user_id`, `event_date`, `platform`)
- numeric checks (e.g., revenue counts must be `>= 0` when present)

This ensures your raw data is “reasonable” before building analytics.

---

## Transformation Model (models/daily_metrics.sql)

File: `models/daily_metrics.sql`

### What it builds
A daily aggregation grouped by:
- `event_date`
- `country`
- `platform`

Output metrics include:
- `dau` (Daily Active Users) = `count(distinct user_id)`
- revenue totals: `total_iap_revenue`, `total_ad_revenue`
- `arpdau` = (total revenue) / dau
- match KPIs: matches started per dau, win/defeat ratios
- server error rate per dau

### Data cleansing logic (why it matters)
The model intentionally normalizes and cleans the raw inputs:

- `country` can be null/empty → bucketed as `UNKNOWN`
- `platform` is standardized to uppercase (`ANDROID`, `IOS`)
- numeric fields treat null as 0 to allow consistent aggregation
- `SAFE_DIVIDE` is used to avoid divide-by-zero failures (returns `NULL` instead of crashing)

### Why a model is needed
Raw event-level data is not “analysis-ready”.
The dbt model creates a stable dataset that analysts can query directly:
- consistent dimensions
- consistent KPIs
- predictable null-handling

---

## Model Documentation & Tests (models/daily_metrics.yml)

File: `models/daily_metrics.yml`

Adds:
- model description
- column-level tests

### Key tests included
- `not_null` on required columns (event_date/country/platform/dau/revenues)
- `accepted_values` for platform (`ANDROID`, `IOS`)
- numeric sanity checks (>= 0) using `dbt_utils.expression_is_true`
- ratio bounds:
  - `win_ratio` between 0 and 1
  - `defeat_ratio` between 0 and 1

### Why tests are filtered with `where: ... is not null`
Some metrics use `SAFE_DIVIDE`, which can return `NULL` when the denominator is 0.
Instead of failing tests on valid NULL results, tests apply:
- `where: metric is not null`

This keeps tests strict *and* realistic.

---

## Running dbt

> dbt commands are executed from `Part2/dbt/`

Typical workflow:

1) Install packages:
```bash
dbt deps
```

2) Build models + run tests:
```bash
dbt build
```

3) Run only tests:
```bash
dbt test
```

4) Run only the model:
```bash
dbt run --select daily_metrics
```

---

## dbt Profiles (BigQuery connection)

dbt uses a `profiles.yml` file (typically located at `~/.dbt/profiles.yml`).

Example BigQuery profile:

```yaml
vertigo_case_dbt:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: vertigo-483902
      dataset: vertigo_case
      location: europe-west1
      keyfile: /path/to/service-account.json
      threads: 4
      timeout_seconds: 300
```

If using gcloud ADC instead, you can use:
- `method: oauth`

---

## Test Results & Artifacts (target/run_results.json)

File: `dbt/target/run_results.json`

This is generated by dbt after `dbt build/test/run`.

### What to look for
- Overall status: `pass` for tests, `success` for model builds
- Execution metadata:
  - dbt version: `1.11.2`
  - location: `europe-west1`
  - project: `vertigo-483902`
- For each test:
  - `compiled_code` shows the actual SQL dbt ran in BigQuery
  - `bytes_processed` / `bytes_billed` show BigQuery cost signals
  - `failures: 0` indicates test passed

In the provided artifact:
- Source tests (raw table) passed (not_null + numeric constraints)
- Model `daily_metrics` built successfully
- Model tests passed (platform values, ratios, non-negative metrics, etc.)

---

## What this Part Demonstrates

- **Data ingestion** into BigQuery from many CSVs
- **Modeling** raw -> analytics using dbt
- **Data quality enforcement** with tests
- **Reproducibility** via dbt project structure and artifacts

---

## Security Reminder

If you used a service account key locally:
- Revoke/rotate the key after finishing the case study
- Never publish the key to GitHub
- Prefer `gcloud auth application-default login` for personal development








