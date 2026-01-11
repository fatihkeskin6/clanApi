# Clan API (Part 1)

A small **FastAPI + PostgreSQL** service to manage *clans*.

- FastAPI app with simple health endpoint
- PostgreSQL persistence (UUID primary key assumed)
- Endpoints to **create**, **list**, **search**, and **delete** clans
- One-time script to load sample data from CSV

---

## Project Structure

```
Part1/
  app/
    main.py          # FastAPI app entrypoint
    router.py        # API routes
    db_conn.py       # DB connection helper (reads DATABASE_URL)
  sample_data_to_db/
    one_time_to_db.py  # Loads clan_sample_data.csv into DB
```

---

## Requirements

- Python 3.10+ (3.11 recommended)
- PostgreSQL 13+ (any recent version is fine)

Python deps (minimum):
- `fastapi`
- `uvicorn`
- `psycopg` (psycopg v3)

---

## Configuration

This project reads the DB connection string from an environment variable:

- `DATABASE_URL` **(required)**

Format:
```
postgresql://user:pass@host:5432/dbname
```

> If `DATABASE_URL` is missing, the app raises an error on startup.

### Example (local)

**Windows (PowerShell)**
```powershell
$env:DATABASE_URL="postgresql://postgres:postgres@localhost:5432/clan_db"
```

**macOS/Linux**
```bash
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/clan_db"
```

---

## Database Setup

Create a database and a `clans` table.

### 1) Create DB

Example:
```sql
CREATE DATABASE clan_db;
```

### 2) Create table

Run the following SQL in your database:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS clans (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL,
  region     TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clans_name ON clans (name);
CREATE INDEX IF NOT EXISTS idx_clans_created_at ON clans (created_at DESC);
```

> Notes:
> - API expects `id` to be a UUID.
> - `region` is stored uppercased in the API.

---

## Run Locally

### 1) Create & activate a virtual environment

**Windows**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**macOS/Linux**
```bash
python -m venv .venv
source .venv/bin/activate
```

### 2) Install dependencies

```bash
pip install -r requirements.txt
```

If you don't have a `requirements.txt` yet, you can install quickly with:
```bash
pip install fastapi uvicorn psycopg
```

### 3) Start the API

Run from the **Part1** directory:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:
- `GET /` → `{"data":{"service":"clan-api","status":"ok"}}`

---

## API Endpoints

Base URL: `http://localhost:8000`

### Create a clan

`POST /clans`

Body:
```json
{
  "name": "Night Owls",
  "region": "eu"
}
```

- `name` required
- `region` required (stored as uppercase)

Example:
```bash
curl -X POST "http://localhost:8000/clans"   -H "Content-Type: application/json"   -d '{"name":"Night Owls","region":"eu"}'
```

### List clans

`GET /clans`

Example:
```bash
curl "http://localhost:8000/clans"
```

Response:
```json
{
  "data": [...],
  "count": 10
}
```

### Search clans by name (case-insensitive)

`GET /clans/search?name=...`

Rules:
- `name` must be at least **3 characters** (otherwise 400)

Example:
```bash
curl "http://localhost:8000/clans/search?name=owl"
```

### Delete a clan

`DELETE /clans/{clan_id}`

Rules:
- `clan_id` must be a valid UUID (otherwise 400)
- Returns 404 if not found

Example:
```bash
curl -X DELETE "http://localhost:8000/clans/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
```

---

## Load Sample Data (One-Time)

There is a helper script to load sample CSV data into the `clans` table.

### 1) Place CSV file

The script expects `clan_sample_data.csv` in the same directory as the script:
```
Part1/sample_data_to_db/clan_sample_data.csv
```

CSV columns expected:
- `name`
- `region`
- `created_at` *(optional, ISO-8601; e.g., `2026-01-01T10:00:00Z`)*

### 2) Run the script

From the **Part1** directory:

```bash
python -m sample_data_to_db.one_time_to_db
```

The script:
- Skips rows with missing `name` or `region`
- Uppercases region
- Parses `created_at` if provided (falls back to current UTC on parsing errors)

---

## Troubleshooting

### `RuntimeError: DATABASE_URL env var is required`
Set `DATABASE_URL` before starting the app or running the loader.

### `psycopg` module not found
Install it:
```bash
pip install psycopg
```

### Connection issues
Verify:
- PostgreSQL is running
- Host/port/user/password in `DATABASE_URL` are correct
- DB and table exist

---

## Notes / Improvements (Optional)

For a production service you’d typically add:
- Pydantic models for request/response validation
- More detailed error handling & logging
- Connection pooling (or a pooler like PgBouncer)
- Migrations (Alembic)

---

## License
MIT (or your preferred license)
