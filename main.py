from fastapi import FastAPI, HTTPException, Depends, Security
from fastapi.security.api_key import APIKeyHeader
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
import os

app = FastAPI(title="AI Security Gateway")

# Mount static files directory for Vercel Web Analytics and other assets
app.mount("/public", StaticFiles(directory="public"), name="public")

API_KEY_NAME = "X-Gateway-Auth-Token"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=True)
EXPECTED_TOKEN = os.getenv("EXPECTED_GATEWAY_TOKEN", "dev-token")


class PromptExecutionRequest(BaseModel):
    user_id: str = Field(..., example="usr_dev_441")
    prompt: str = Field(..., max_length=4000)


def verify_gateway_auth(api_key: str = Security(api_key_header)):
    if api_key != EXPECTED_TOKEN:
        raise HTTPException(status_code=403, detail="Unauthorized")
    return api_key


@app.get("/")
async def root():
    """Serve the landing page with Vercel Web Analytics"""
    return FileResponse("public/index.html")


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/api/v1/dispatch")
async def dispatch_ai_workflow(request: PromptExecutionRequest, api_key: str = Depends(verify_gateway_auth)):
    return {"status": "success", "user_id": request.user_id}
