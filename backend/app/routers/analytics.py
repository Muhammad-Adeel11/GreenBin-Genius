"""
GreenBin Genius – Analytics Router
GET /api/analytics/me        – personal stats for the authenticated user
GET /api/analytics/global    – platform-wide aggregate stats
Follows FR-8 (Impact Dashboard) from SRS.
"""

from fastapi import APIRouter, Depends
from app.db.mongo import classifications_col, users_col
from app.routers.auth import get_current_user
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])


@router.get(
    "/me",
    summary="Get personalized analytics for the authenticated user",
)
async def my_analytics(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    col = classifications_col()

    total = await col.count_documents({"user_id": user_id})
    recyclable = await col.count_documents({"user_id": user_id, "recyclable": True})

    now = datetime.utcnow()
    week_start  = now - timedelta(days=7)
    month_start = now.replace(day=1, hour=0, minute=0, second=0)

    scans_week  = await col.count_documents({"user_id": user_id, "timestamp": {"$gte": week_start}})
    scans_month = await col.count_documents({"user_id": user_id, "timestamp": {"$gte": month_start}})

    # Top category for this user
    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 1},
    ]
    top = await col.aggregate(pipeline).to_list(1)
    top_category = top[0]["_id"] if top else None

    return {
        "user_id":            user_id,
        "total_scans":        total,
        "recyclable_count":   recyclable,
        "non_recyclable_count": total - recyclable,
        "top_category":       top_category,
        "scans_this_week":    scans_week,
        "scans_this_month":   scans_month,
        "streak_days":        current_user.get("streak", 0),
    }


@router.get(
    "/global",
    summary="Get platform-wide waste classification statistics",
)
async def global_analytics():
    col = classifications_col()

    total   = await col.count_documents({})
    recyclable = await col.count_documents({"recyclable": True})

    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0)
    monthly = await col.count_documents({"timestamp": {"$gte": month_start}})

    pipeline = [
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 1},
    ]
    top = await col.aggregate(pipeline).to_list(1)
    top_category = top[0]["_id"] if top else None

    return {
        "total_global_scans": total,
        "total_recyclable":   recyclable,
        "monthly_scans":      monthly,
        "top_category_global": top_category,
    }
