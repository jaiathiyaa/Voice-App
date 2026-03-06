from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional


# -------------------------
# User Schemas
# -------------------------

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters")


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


# -------------------------
# Transaction Schemas
# -------------------------

class TransactionCreate(BaseModel):

    amount: float = Field(..., gt=0, description="Amount must be greater than 0")
    type: str
    category: str
    description: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v):
        if v not in ["income", "expense"]:
            raise ValueError("type must be 'income' or 'expense'")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "amount": 500,
                "type": "expense",
                "category": "Food",
                "description": "Dinner"
            }
        }


class TransactionResponse(BaseModel):
    id: str
    amount: float
    type: str
    category: str
    description: Optional[str]
    created_at: datetime


class TransactionUpdate(BaseModel):
    amount: Optional[float] = Field(None, gt=0)
    type: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, v):
        if v and v not in ["income", "expense"]:
            raise ValueError("type must be 'income' or 'expense'")
        return v


# -------------------------
# Budget Schemas
# -------------------------

class BudgetCreate(BaseModel):
    category: str
    monthly_limit: float = Field(..., gt=0, description="Budget must be greater than 0")


# -------------------------
# Voice Transaction Schemas
# -------------------------

class VoiceTransactionRequest(BaseModel):
    text: str = Field(..., min_length=3)


class VoiceConfirm(BaseModel):
    amount: int = Field(..., gt=0)
    type: str
    category: str


# -------------------------
# SMS Parsing Schema
# -------------------------

class SMSTransactionRequest(BaseModel):
    sms_text: str = Field(..., min_length=5)