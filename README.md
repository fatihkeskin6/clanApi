# Clan API – FastAPI + Cloud Run + Cloud SQL

This project is a lightweight backend REST API for managing **clans**, built as part of a backend case study.  
The API is containerized with Docker and designed to run on **Google Cloud Run**, using **Cloud SQL (PostgreSQL)** as the database.

All responses are returned in **JSON** format.

---

## Features

- Create a clan (name, region)
- List all clans
- Search clans by name (contains, min 3 characters)
- Delete a clan by ID
- UUID-based primary keys
- Auto-generated `created_at` timestamps (UTC)
- Dockerized & cloud-ready

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

## 📁 Project Structure

