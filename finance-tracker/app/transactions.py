from fastapi import APIRouter, Depends, HTTPException
from bson import ObjectId
import json
import re
from datetime import datetime, timedelta
from google import genai
import os
from app.database import db
from app.schemas import BudgetCreate, TransactionCreate, VoiceConfirm
from app.schemas import VoiceTransactionRequest
from app.schemas import TransactionUpdate
from app.schemas import SMSTransactionRequest
from app.models import budget_helper, transaction_helper
from app.auth import get_current_user
from app.logger import logger

router = APIRouter()


# ➕ Add Transaction
@router.post("/transactions")
async def add_transaction(
    transaction: TransactionCreate,
    current_user=Depends(get_current_user)
):

    user_id = str(current_user["_id"])

    logger.info(f"User {user_id} is adding a transaction")

    new_transaction = {
        "user_id": user_id,
        "amount": transaction.amount,
        "type": transaction.type,
        "category": transaction.category,
        "description": transaction.description,
        "created_at": datetime.utcnow()
    }

    result = await db.transactions.insert_one(new_transaction)

    logger.info(f"Transaction created with ID {result.inserted_id}")

    created_transaction = await db.transactions.find_one({"_id": result.inserted_id})

    return transaction_helper(created_transaction)


# 📄 Get All Transactions
@router.get("/transactions")
async def get_transactions(
    page: int = 1,
    limit: int = 10,
    current_user=Depends(get_current_user)
):

    user_id = str(current_user["_id"])

    logger.info(f"User {user_id} requested transactions page={page} limit={limit}")

    skip = (page - 1) * limit

    transactions = []

    cursor = db.transactions.find(
        {"user_id": user_id}
    ).skip(skip).limit(limit)

    async for transaction in cursor:
        transactions.append(transaction_helper(transaction))

    total = await db.transactions.count_documents({"user_id": user_id})

    return {
        "page": page,
        "limit": limit,
        "total_transactions": total,
        "data": transactions
    }

@router.put("/transactions/{transaction_id}")
async def update_transaction(
    transaction_id: str,
    updated_data: TransactionUpdate,
    current_user=Depends(get_current_user)
):

    user_id = str(current_user["_id"])
    logger.info(f"User {user_id} attempting to update transaction {transaction_id}")
    transaction = await db.transactions.find_one({
        "_id": ObjectId(transaction_id),
        "user_id": user_id
    })

    if not transaction:
        logger.warning(f"Transaction {transaction_id} not found for user {user_id}")
        raise HTTPException(status_code=404, detail="Transaction not found")

    update_fields = {}

    if updated_data.amount is not None:
        update_fields["amount"] = updated_data.amount

    if updated_data.type is not None:
        update_fields["type"] = updated_data.type

    if updated_data.category is not None:
        update_fields["category"] = updated_data.category

    if updated_data.description is not None:
        update_fields["description"] = updated_data.description

    if not update_fields:
        raise HTTPException(status_code=400, detail="No fields provided for update")

    await db.transactions.update_one(
        {"_id": ObjectId(transaction_id)},
        {"$set": update_fields}
    )

    updated_transaction = await db.transactions.find_one({"_id": ObjectId(transaction_id)})
    logger.info(f"Transaction {transaction_id} updated successfully by user {user_id}")
    return transaction_helper(updated_transaction)

# 🗑 Delete Transaction
@router.delete("/transactions/{transaction_id}")
async def delete_transaction(transaction_id: str, current_user=Depends(get_current_user)):

    user_id = str(current_user["_id"])

    logger.info(f"User {user_id} attempting to delete transaction {transaction_id}")

    result = await db.transactions.delete_one({
        "_id": ObjectId(transaction_id),
        "user_id": user_id
    })

    if result.deleted_count == 0:
        logger.warning(f"Transaction {transaction_id} not found for deletion")
        raise HTTPException(status_code=404, detail="Transaction not found")

    logger.info(f"Transaction {transaction_id} deleted successfully")

    return {"message": "Transaction deleted"}

@router.get("/transactions/filter")
async def filter_transactions(
    category: str = None,
    txn_type: str = None,
    start_date: str = None,
    end_date: str = None,
    current_user=Depends(get_current_user)
):

    user_id = str(current_user["_id"])
    logger.info(f"User {user_id} used transaction filters")
    query = {"user_id": user_id}

    if category:
        query["category"] = category

    if txn_type:
        query["type"] = txn_type

    if start_date and end_date:
        query["created_at"] = {
            "$gte": datetime.fromisoformat(start_date),
            "$lte": datetime.fromisoformat(end_date)
        }

    transactions = []

    cursor = db.transactions.find(query)

    async for transaction in cursor:
        transactions.append(transaction_helper(transaction))

    return transactions

@router.get("/categories")
async def get_categories():
    logger.info("Categories API requested")
    income_categories = [
        "Salary",
        "Freelance",
        "Business",
        "Bonus",
        "Investment",
        "Gift",
        "Refund"
    ]

    expense_categories = [
        "Food",
        "Travel",
        "Shopping",
        "Fuel",
        "Rent",
        "Entertainment",
        "Utilities",
        "Others"
    ]

    return {
        "income_categories": income_categories,
        "expense_categories": expense_categories
    }

@router.get("/transactions/summary")
async def transaction_summary(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    logger.info(f"Generating financial summary for user {user_id}")
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

@router.get("/transactions/heatmap")
async def spending_heatmap(current_user=Depends(get_current_user)):

    user_id = str(current_user["_id"])
    logger.info(f"Generating heatmap for user {user_id}")
    heatmap = {}

    cursor = db.transactions.find({
        "user_id": user_id,
        "type": "expense"
    })

    async for transaction in cursor:

        date_str = transaction["created_at"].strftime("%Y-%m-%d")
        amount = transaction["amount"]

        if date_str not in heatmap:
            heatmap[date_str] = 0

        heatmap[date_str] += amount

    return heatmap


@router.get("/transactions/spending-pattern")
async def spending_pattern(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    logger.info(f"Calculating spending pattern for user {user_id}")
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
    logger.info(f"User {user_id} setting budget for {budget.category}")
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
    logger.info(f"Generating alerts for user {user_id}")
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
)
@router.get("/ai-coach")
async def ai_finance_coach(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    logger.info(f"User {user_id} requested AI financial analysis")
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
        logger.error(f"Gemini AI error for user {user_id}: {str(e)}")
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



def parse_transaction(text: str):
    text = text.lower()

    amount = None
    txn_type = "expense"
    category = "Others"
    txn_date = datetime.utcnow()

    # Extract amount
    match = re.search(r'\d+', text)
    if match:
        amount = int(match.group())

    # Income keywords
    income_keywords = [
        "salary",
        "received",
        "income",
        "credited",
        "earned",
        "got"
    ]

    # Income categories
    income_categories = {
        "salary": "Salary",
        "freelance": "Freelance",
        "business": "Business",
        "bonus": "Bonus",
        "dividend": "Investment",
        "interest": "Interest",
        "gift": "Gift",
        "refund": "Refund"
    }

    # Expense categories
    expense_categories = ["food", "travel", "rent", "shopping", "fuel"]

    # Detect income
    if any(word in text for word in income_keywords):
        txn_type = "income"

        for key, value in income_categories.items():
            if key in text:
                category = value
                break

    # Detect expense category only if expense
    else:
        for cat in expense_categories:
            if cat in text:
                category = cat.capitalize()
                break

    # Detect date
    if "yesterday" in text:
        txn_date = datetime.utcnow() - timedelta(days=1)

    return {
        "amount": amount,
        "type": txn_type,
        "category": category,
        "date": txn_date
    }



@router.post("/voice-transaction")
async def voice_transaction(
    request: VoiceTransactionRequest,
    current_user=Depends(get_current_user)
):
    logger.info(f"Voice command received: {request.text}")
    parsed = parse_transaction(request.text)
    logger.info(f"Parsed voice transaction: {parsed}")
    if not parsed["amount"]:
        raise HTTPException(status_code=400, detail="Could not detect amount")

    # DO NOT SAVE DIRECTLY (Return parsed first)
    return {
        "parsed_data": parsed,
        "message": "Confirm to save transaction"
    }





@router.post("/voice-transaction/confirm")
async def confirm_voice_transaction(
    data: VoiceConfirm,
    current_user=Depends(get_current_user)
):
    logger.info(f"Voice transaction confirmed by user {current_user['_id']}")
    new_txn = {
        "user_id": str(current_user["_id"]),
        "amount": data.amount,
        "type": data.type,
        "category": data.category,
        "created_at": datetime.utcnow()
    }

    result = await db.transactions.insert_one(new_txn)
    
    return {
        "message": "Transaction saved successfully",
        "transaction_id": str(result.inserted_id)
    }


def parse_sms_transaction(text: str):
    
    text_lower = text.lower()

    amount = None
    txn_type = "expense"
    merchant = "Unknown"
    bank = "Unknown"
    category = "Others"

    # -------------------------
    # Detect Amount
    # -------------------------
    amount_match = re.search(r'(?:rs\.?|inr)?\s?(\d+(?:,\d+)*)', text_lower)

    if amount_match:
        amount = int(amount_match.group(1).replace(",", ""))

    # -------------------------
    # Detect Transaction Type
    # -------------------------
    income_words = ["credited", "received", "deposit"]
    expense_words = ["spent", "debited", "purchase", "paid", "withdrawn"]

    if any(word in text_lower for word in income_words):
        txn_type = "income"

    elif any(word in text_lower for word in expense_words):
        txn_type = "expense"

    # -------------------------
    # Detect Bank
    # -------------------------
    banks = ["hdfc", "sbi", "icici", "axis", "kotak", "yes bank"]

    for b in banks:
        if b in text_lower:
            bank = b.upper()
            break

    # -------------------------
    # Detect Merchant
    # -------------------------
    merchant_patterns = [
        r'at\s([a-zA-Z0-9\s]+)',
        r'to\s([a-zA-Z0-9\s]+)',
        r'paid\s+to\s([a-zA-Z0-9\s]+)'
    ]

    for pattern in merchant_patterns:
        match = re.search(pattern, text_lower)
        if match:
            merchant = match.group(1).strip().split()[0].capitalize()
            break

    # -------------------------
    # Category Detection
    # -------------------------
    shopping_merchants = ["amazon", "flipkart", "myntra"]
    food_merchants = ["swiggy", "zomato"]
    fuel_merchants = ["hpcl", "ioc", "shell"]

    if merchant.lower() in shopping_merchants:
        category = "Shopping"

    elif merchant.lower() in food_merchants:
        category = "Food"

    elif merchant.lower() in fuel_merchants:
        category = "Fuel"

    return {
        "amount": amount,
        "type": txn_type,
        "merchant": merchant,
        "bank": bank,
        "category": category
    }

@router.post("/sms-transaction")
async def sms_transaction(
    request: SMSTransactionRequest,
    current_user=Depends(get_current_user)
):

    parsed = parse_sms_transaction(request.sms_text)

    if not parsed["amount"]:
        raise HTTPException(status_code=400, detail="Could not detect amount")

    new_transaction = {
        "user_id": str(current_user["_id"]),
        "amount": parsed["amount"],
        "type": parsed["type"],
        "category": parsed["category"],
        "description": parsed["merchant"],
        "created_at": datetime.utcnow()
    }

    result = await db.transactions.insert_one(new_transaction)

    return {
        "message": "Transaction added from SMS",
        "transaction_id": str(result.inserted_id),
        "parsed_data": parsed
    }

