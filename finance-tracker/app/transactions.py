from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from bson import ObjectId

from app.database import db
from app.schemas import TransactionCreate
from app.models import transaction_helper
from app.auth import get_current_user

router = APIRouter()


# ➕ Add Transaction
@router.post("/transactions")
async def add_transaction(
    transaction: TransactionCreate,
    current_user=Depends(get_current_user)
):
    new_transaction = {
        "user_id": str(current_user["_id"]),
        "amount": transaction.amount,
        "type": transaction.type,
        "category": transaction.category,
        "description": transaction.description,
        "created_at": datetime.utcnow()
    }

    result = await db.transactions.insert_one(new_transaction)
    created_transaction = await db.transactions.find_one({"_id": result.inserted_id})

    return transaction_helper(created_transaction)


# 📄 Get All Transactions
@router.get("/transactions")
async def get_transactions(current_user=Depends(get_current_user)):
    transactions = []
    cursor = db.transactions.find({"user_id": str(current_user["_id"])})

    async for transaction in cursor:
        transactions.append(transaction_helper(transaction))

    return transactions


# 🗑 Delete Transaction
@router.delete("/transactions/{transaction_id}")
async def delete_transaction(transaction_id: str, current_user=Depends(get_current_user)):
    result = await db.transactions.delete_one({
        "_id": ObjectId(transaction_id),
        "user_id": str(current_user["_id"])
    })

    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Transaction not found")

    return {"message": "Transaction deleted"}



@router.get("/transactions/summary")
async def transaction_summary(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    income = 0
    expense = 0

    cursor = db.transactions.find({"user_id": user_id})

    async for transaction in cursor:
        if transaction["type"] == "income":
            income += transaction["amount"]
        else:
            expense += transaction["amount"]

    return {
        "total_income": income,
        "total_expense": expense,
        "balance": income - expense
    }


@router.get("/transactions/category-breakdown")
async def category_breakdown(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    breakdown = {}

    cursor = db.transactions.find({"user_id": user_id})

    async for transaction in cursor:
        category = transaction["category"]
        amount = transaction["amount"]

        if category not in breakdown:
            breakdown[category] = 0

        if transaction["type"] == "expense":
            breakdown[category] += amount

    return breakdown


from datetime import datetime

@router.get("/transactions/monthly-summary")
async def monthly_summary(month: int, year: int, current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    start_date = datetime(year, month, 1)

    if month == 12:
        end_date = datetime(year + 1, 1, 1)
    else:
        end_date = datetime(year, month + 1, 1)

    income = 0
    expense = 0

    cursor = db.transactions.find({
        "user_id": user_id,
        "created_at": {
            "$gte": start_date,
            "$lt": end_date
        }
    })

    async for transaction in cursor:
        if transaction["type"] == "income":
            income += transaction["amount"]
        else:
            expense += transaction["amount"]

    return {
        "month": month,
        "year": year,
        "total_income": income,
        "total_expense": expense,
        "balance": income - expense
    }


@router.get("/transactions/health-score")
async def financial_health(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    income = 0
    expense = 0

    cursor = db.transactions.find({"user_id": user_id})

    async for transaction in cursor:
        if transaction["type"] == "income":
            income += transaction["amount"]
        else:
            expense += transaction["amount"]

    if income == 0:
        score = 0
    else:
        savings_ratio = (income - expense) / income

        if savings_ratio >= 0.4:
            score = 90
        elif savings_ratio >= 0.2:
            score = 75
        elif savings_ratio > 0:
            score = 60
        else:
            score = 30

    return {
        "income": income,
        "expense": expense,
        "savings_ratio": round((income - expense) / income, 2) if income > 0 else 0,
        "health_score": score
    }


@router.get("/transactions/spending-pattern")
async def spending_pattern(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    category_expense = {}

    cursor = db.transactions.find({
        "user_id": user_id,
        "type": "expense"
    })

    async for transaction in cursor:
        category = transaction["category"]
        amount = transaction["amount"]

        if category not in category_expense:
            category_expense[category] = 0

        category_expense[category] += amount

    if not category_expense:
        return {"message": "No expense data available"}

    highest_category = max(category_expense, key=category_expense.get)

    return {
        "top_spending_category": highest_category,
        "amount_spent": category_expense[highest_category],
        "full_breakdown": category_expense
    }