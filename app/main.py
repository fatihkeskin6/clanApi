from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app.router import router

app = FastAPI(default_response_class=JSONResponse)
app.include_router(router)

@app.get("/")
def health():
    return {"data": {"service": "clan-api", "status": "ok"}}
