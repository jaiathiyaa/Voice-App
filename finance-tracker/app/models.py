from datetime import datetime
from bson import ObjectId


def user_helper(user) -> dict:
    return {
        "id": str(user["_id"]),
        "email": user["email"],
        "created_at": user["created_at"],
    }


def transaction_helper(transaction) -> dict:
    return {
        "id": str(transaction["_id"]),
        "amount": transaction["amount"],
        "type": transaction["type"],
        "category": transaction["category"],
        "description": transaction.get("description"),
        "created_at": transaction["created_at"]
    }