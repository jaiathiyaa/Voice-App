from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: str
    email: EmailStr
    created_at: datetime

class Token(BaseModel):
    access_token: str
    token_type: str




class TransactionCreate(BaseModel):
    amount: float
    type: str  # "income" or "expense"
    category: str
    description: Optional[str] = None


class TransactionResponse(BaseModel):
    id: str
    amount: float
    type: str
    category: str
    description: Optional[str]
    created_at: datetime

class BudgetCreate(BaseModel):
    category: str
    monthly_limit: float