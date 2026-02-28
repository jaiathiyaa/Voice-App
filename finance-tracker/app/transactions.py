from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from bson import ObjectId
import json
import re
from google import genai
from google.genai.types import HttpOptions
import os
from app.database import db
from app.schemas import BudgetCreate, TransactionCreate
from app.models import budget_helper, transaction_helper
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

@router.post("/budget")
async def set_budget(budget: BudgetCreate, current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    existing = await db.budgets.find_one({
        "user_id": user_id,
        "category": budget.category
    })

    if existing:
        await db.budgets.update_one(
            {"_id": existing["_id"]},
            {"$set": {"monthly_limit": budget.monthly_limit}}
        )
        updated = await db.budgets.find_one({"_id": existing["_id"]})
        return budget_helper(updated)

    new_budget = {
        "user_id": user_id,
        "category": budget.category,
        "monthly_limit": budget.monthly_limit
    }

    result = await db.budgets.insert_one(new_budget)
    created = await db.budgets.find_one({"_id": result.inserted_id})

    return budget_helper(created)

@router.get("/budget/status")
async def budget_status(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    budgets_cursor = db.budgets.find({"user_id": user_id})
    result = []

    async for budget in budgets_cursor:
        category = budget["category"]
        limit = budget["monthly_limit"]

        expense_total = 0
        cursor = db.transactions.find({
            "user_id": user_id,
            "category": category,
            "type": "expense"
        })

        async for transaction in cursor:
            expense_total += transaction["amount"]

        result.append({
            "category": category,
            "limit": limit,
            "spent": expense_total,
            "remaining": limit - expense_total,
            "status": "Exceeded" if expense_total > limit else "Safe"
        })

    return result

@router.get("/alerts")
async def generate_alerts(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    alerts = []

    income = 0
    expense = 0

    cursor = db.transactions.find({"user_id": user_id})

    async for transaction in cursor:
        if transaction["type"] == "income":
            income += transaction["amount"]
        else:
            expense += transaction["amount"]

    # Alert 1: Overspending overall
    if expense > income:
        alerts.append("⚠️ Your total expenses exceed your income.")

    # Alert 2: Low savings ratio
    if income > 0:
        savings_ratio = (income - expense) / income
        if savings_ratio < 0.1:
            alerts.append("⚠️ Your savings rate is very low. Try reducing discretionary spending.")

    # Alert 3: Budget exceeded
    budgets_cursor = db.budgets.find({"user_id": user_id})
    async for budget in budgets_cursor:
        category = budget["category"]
        limit = budget["monthly_limit"]

        category_expense = 0
        cursor = db.transactions.find({
            "user_id": user_id,
            "category": category,
            "type": "expense"
        })

        async for transaction in cursor:
            category_expense += transaction["amount"]

        if category_expense > limit:
            alerts.append(f"🚨 Budget exceeded for {category}")

    if not alerts:
        alerts.append("✅ Your financial status looks healthy.")

    return {
        "alerts": alerts
    }



client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY"),
    http_options=HttpOptions(api_version="v1")
)
@router.get("/ai-coach")
async def ai_finance_coach(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])

    income = 0
    expense = 0
    category_expense = {}

    cursor = db.transactions.find({"user_id": user_id})

    async for transaction in cursor:
        amount = transaction["amount"]

        if transaction["type"] == "income":
            income += amount
        else:
            expense += amount
            category = transaction["category"]
            category_expense[category] = category_expense.get(category, 0) + amount

    savings = income - expense
    savings_ratio = (savings / income) if income > 0 else 0

    # Base risk calculation
    if income == 0 and expense > 0:
        base_risk = "High"
    elif savings < 0:
        base_risk = "High"
    elif savings_ratio < 0.2:
        base_risk = "Medium"
    else:
        base_risk = "Low"

    health_score = max(0, min(100, int((savings_ratio * 100))))

    prompt = f"""
    You are a professional financial advisor.

    System Calculated Risk: {base_risk}

    Return ONLY valid JSON with:
    - risk_level
    - top_issues
    - action_steps
    - long_term_strategy
    - motivation

    User Data:
    Income: {income}
    Expense: {expense}
    Savings: {savings}
    Savings Ratio: {round(savings_ratio,2)}
    Category Breakdown: {category_expense}
    """

    # 🔐 Safe AI Call
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        raw_text = response.text
    except Exception as e:
        return {
            "income": income,
            "expense": expense,
            "savings": savings,
            "health_score": health_score,
            "ai_analysis": {
                "risk_level": base_risk,
                "top_issues": ["AI service unavailable"],
                "action_steps": ["Retry later"],
                "long_term_strategy": "AI unavailable",
                "motivation": "System temporarily unable to generate advice."
            }
        }


    clean_text = re.sub(r"```json|```", "", raw_text).strip()

    match = re.search(r"\{.*\}", clean_text, re.DOTALL)
    if match:
        clean_text = match.group(0)

    try:
        ai_data = json.loads(clean_text)
    except json.JSONDecodeError:
        ai_data = {
            "risk_level": base_risk,
            "top_issues": [],
            "action_steps": [],
            "long_term_strategy": "AI response parsing failed",
            "motivation": raw_text
        }

    # 💾 Save AI snapshot
    await db.ai_reports.insert_one({
        "user_id": user_id,
        "income": income,
        "expense": expense,
        "savings": savings,
        "analysis": ai_data,
        "created_at": datetime.utcnow()
    })

    return {
        "income": income,
        "expense": expense,
        "savings": savings,
        "health_score": health_score,
        "ai_analysis": ai_data
    }