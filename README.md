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
## File & Directory Overview

### Part1/app/main.py
- FastAPI application entry point
- Initializes the FastAPI app
- Registers API routes
- Exposes a health check endpoint (`GET /`) to verify service availability

---

### Part1/app/router.py
- Contains all API route definitions
- Implements CRUD-style endpoints for the `clans` resource:
  - Create clan
  - List clans
  - Search clans (case-insensitive)
  - Delete clan
- Handles request validation and basic error handling
- Executes SQL queries using a PostgreSQL connection

---

### Part1/app/db_conn.py
- Database connection helper module
- Reads the `DATABASE_URL` from environment variables
- Creates a PostgreSQL connection using `psycopg`
- Uses dictionary-based row results for easier JSON serialization
- Designed for Cloud Run usage with Cloud SQL

---

### Part1/sample_data_to_db/one_time_to_db.py
- One-time utility script used during initial setup
- Loads sample clan data from a CSV file into the database
- Normalizes input data (uppercases region, validates fields)
- Parses optional timestamps or falls back to current UTC time
- Not used in runtime or production execution

---
Notes:
- `id` is generated using `gen_random_uuid()` (pgcrypto extension)
- `region` is stored uppercased by the API
- Case-insensitive search is supported via `lower(name)` index

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

Base URL (example):
```
https://<cloud-run-service-url>
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

## One-Time Data Load (Optional)

A helper script exists to populate the database from CSV:

```
Part1/sample_data_to_db/one_time_to_db.py
```

This script was used **only during initial setup** and is **not part of runtime execution**.

---

## Security Notes

- No credentials are committed to the repository
- Secrets are managed via **Cloud Run environment variables**
- Cloud SQL access is restricted at the network / IAM level

---

## Notes

This project is intentionally minimal and focused on:
- Clean API design
- Cloud-native deployment (GCP)
- Separation of code and configuration

---

## License

MIT




