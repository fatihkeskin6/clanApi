from fastapi import APIRouter
from fastapi.responses import JSONResponse
from uuid import UUID

from app.db_conn import get_conn

router = APIRouter()


@router.post("/clans")
def create_clan(body: dict):
    name = (body.get("name") or "").strip() #Purpose of (or "") section is to make sure that strip function doesnt fail if input of name is empty(None).
    region = (body.get("region") or "").strip().upper()

    if not name:
        return JSONResponse(status_code=400, content={"error": "name is required"})
    if not region:
        return JSONResponse(status_code=400, content={"error": "region is required"})

    sql = """
        INSERT INTO clans (name, region)
        VALUES (%s, %s)
        RETURNING id::text AS id, name, region, created_at;
    """

    try:
        with get_conn() as conn:
            with conn.cursor() as curr:
                curr.execute(sql, (name, region))
                row = curr.fetchone()
        return {"data": row}
    except Exception:
        return JSONResponse(status_code=500, content={"error": "db error"})


@router.get("/clans")
def list_clans():
    sql = """
        SELECT id::text AS id, name, region, created_at
        FROM clans
        ORDER BY created_at DESC;
    """

    try:
        with get_conn() as conn:
            with conn.cursor() as curr:
                curr.execute(sql)
                rows = curr.fetchall()
        return {"data": rows, "count": len(rows)}
    except Exception:
        return JSONResponse(status_code=500, content={"error": "db error"})


@router.get("/clans/search")
def search_clans(name: str = None):
    # (None) makes param optional; we handle validation ourselves instead of FastAPI returning 422
    # If no: Empty requests wont receive the request contains empty name and automatically will return 422 Unprocessable Entity
    query = (name or "").strip()

    if len(query) < 3:
        return JSONResponse(status_code=400, content={"error": "name must be at least 3 chars"})

    like = f"%{query}%"
    sql = """
        SELECT id::text AS id, name, region, created_at
        FROM clans
        WHERE name ILIKE %s
        ORDER BY created_at DESC;
    """
    # In SQL script, usage of ILIKE instead of LIKE: To avoid case-sensitive problems. 

    try:
        with get_conn() as conn:
            with conn.cursor() as curr:
                curr.execute(sql, (like,))
                rows = curr.fetchall()
        return {"data": rows, "count": len(rows)}
    except Exception:
        return JSONResponse(status_code=500, content={"error": "db error"})


@router.delete("/clans/{clan_id}")
def delete_clan(clan_id: str):
    try:
        UUID(clan_id) #To check if the given id is in proper type, to avoid unnecessary traffic.
    except Exception:
        return JSONResponse(status_code=400, content={"error": "invalid id"})

    sql = "DELETE FROM clans WHERE id = %s RETURNING id::text AS id;"

    try:
        with get_conn() as conn:
            with conn.cursor() as curr:
                curr.execute(sql, (clan_id,))
                row = curr.fetchone()

        if not row:
            return JSONResponse(status_code=404, content={"error": "not found"})

        return {"deleted_id": row["id"]}
    except Exception:
        return JSONResponse(status_code=500, content={"error": "db error"})
