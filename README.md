# Clan API – FastAPI + Cloud Run + Cloud SQL

This project is a lightweight backend REST API for managing clans.  
It was built as a backend case study using **FastAPI**, **Docker**, **Google Cloud Run**, and **Cloud SQL (PostgreSQL)**.

All API responses are returned in JSON format.

---

## Features

- Create a clan (name, region)
- List all clans
- Search clans by name (contains, minimum 3 characters)
- Delete a clan by ID
- UUID-based primary keys
- Auto-generated UTC timestamps
- Dockerized and cloud-ready

---

## Tech Stack

- Python 3.11
- FastAPI
- PostgreSQL
- psycopg
- Docker
- Google Cloud Run
- Google Cloud SQL

---

## Project Structure

.
├── app/
│ ├── init.py
│ ├── main.py
│ ├── router.py
│ └── db_conn.py
├── clan_sample_data.csv
├── one_time_to_db.py
├── requirements.txt
├── Dockerfile
├── .dockerignore
└── README.md

pgsql
Copy code

---

## Database Schema

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS clans (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  region     TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clans_name_lower
ON clans ((lower(name)));
Environment Variables
The application requires the following environment variable:

bash
Copy code
DATABASE_URL=postgresql://user:password@host:5432/dbname
For Google Cloud Run with Cloud SQL (Unix socket):

text
Copy code
postgresql://postgres:PASSWORD@/postgres?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME
Docker Usage
Build image
bash
Copy code
docker build -t clan-api .
Run container
bash
Copy code
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://user:password@host:5432/dbname" \
  clan-api
The API will be available at:

arduino
Copy code
http://localhost:8080
API Endpoints
Health Check
GET /

json
Copy code
{
  "data": {
    "service": "clan-api",
    "status": "ok"
  }
}
Create Clan
POST /clans

Request body:

json
Copy code
{
  "name": "Galatasaray",
  "region": "TR"
}
Response:

json
Copy code
{
  "data": {
    "id": "uuid",
    "name": "Galatasaray",
    "region": "TR",
    "created_at": "2026-01-10T07:22:45+00:00"
  }
}
List Clans
GET /clans

json
Copy code
{
  "data": [...],
  "count": 3
}
Search Clans
GET /clans/search?name=gal

Minimum 3 characters

Case-insensitive

Partial match

json
Copy code
{
  "data": [...],
  "count": 1
}
Delete Clan
DELETE /clans/{id}

json
Copy code
{
  "deleted_id": "uuid"
}
Sample Data Loader
A one-time script is provided to load sample clan data from CSV into the database.

bash
Copy code
python one_time_to_db.py
