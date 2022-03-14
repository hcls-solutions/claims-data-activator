"""
  HITL Service Microservice
"""
import uvicorn
import asyncio
import time
import config
from common.utils.logging_handler import Logger
from concurrent.futures import ThreadPoolExecutor
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Request
from routes import hitl


app = FastAPI(title="HITL Service API")

origins = [
    "*",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def set_default_executor():
  loop = asyncio.get_running_loop()
  loop.set_default_executor(ThreadPoolExecutor(max_workers=1000))


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
  method = request.method
  path = request.scope.get("path")
  start_time = time.time()
  response = await call_next(request)
  if path != "/ping":
    process_time = time.time() - start_time
    time_elapsed = round(process_time * 1000)
    Logger.info(f"{method} {path} Time elapsed: {str(time_elapsed)} ms")
  return response


@app.get("/ping")
def health_check():
  return True


api = FastAPI(title="HITL Service API", version="latest")

api.include_router(hitl.router)

app.mount("/hitl_service/v1", api)

if __name__ == "__main__":
  uvicorn.run(
      "main:app",
      host="0.0.0.0",
      port=int(config.PORT),
      log_level="info",
      reload=True)