from fastapi import FastAPI
from app.auth import router as auth_router
from app.transactions import router as transaction_router

app = FastAPI(title="Voice Finance Tracker - Day 1")

app.include_router(auth_router)
app.include_router(transaction_router)