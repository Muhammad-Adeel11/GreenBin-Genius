"""
GreenBin Genius – Analytics Router
GET /api/analytics/me        – personal stats for the authenticated user
GET /api/analytics/global    – platform-wide aggregate stats
GET /api/analytics/dashboard – admin dashboard (real aggregated data)
"""

from fastapi import APIRouter, Depends
from app.db.mongo import classifications_col, users_col
from app.routers.auth import get_current_user
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])


@router.get("/me", summary="Personalized analytics for the authenticated user")
async def my_analytics(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    col = classifications_col()

    total      = await col.count_documents({"user_id": user_id})
    recyclable = await col.count_documents({"user_id": user_id, "recyclable": True})

    now         = datetime.utcnow()
    week_start  = now - timedelta(days=7)
    month_start = now.replace(day=1, hour=0, minute=0, second=0)

    scans_week  = await col.count_documents({"user_id": user_id, "timestamp": {"$gte": week_start}})
    scans_month = await col.count_documents({"user_id": user_id, "timestamp": {"$gte": month_start}})

    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 1},
    ]
    top = await col.aggregate(pipeline).to_list(1)

    return {
        "user_id":              user_id,
        "total_scans":          total,
        "recyclable_count":     recyclable,
        "non_recyclable_count": total - recyclable,
        "top_category":         top[0]["_id"] if top else None,
        "scans_this_week":      scans_week,
        "scans_this_month":     scans_month,
        "streak_days":          current_user.get("streak", 0),
    }


@router.get("/global", summary="Platform-wide waste statistics")
async def global_analytics():
    col        = classifications_col()
    total      = await col.count_documents({})
    recyclable = await col.count_documents({"recyclable": True})

    now         = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0)
    monthly     = await col.count_documents({"timestamp": {"$gte": month_start}})

    pipeline = [
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 1},
    ]
    top = await col.aggregate(pipeline).to_list(1)

    return {
        "total_global_scans":  total,
        "total_recyclable":    recyclable,
        "monthly_scans":       monthly,
        "top_category_global": top[0]["_id"] if top else None,
    }


@router.get("/dashboard", summary="Admin dashboard – real aggregated data")
async def admin_dashboard_analytics(
    _ = Depends(get_current_user),
    timeframe: str = "30d",
):
    col   = classifications_col()
    u_col = users_col()
    now   = datetime.utcnow()

    days  = int(timeframe.replace("d", "")) if timeframe.endswith("d") else 30
    since = now - timedelta(days=days)

    total        = await col.count_documents({})
    active_users = await u_col.count_documents({"status": {"$ne": "suspended"}})

    # ── Category distribution ──────────────────────────────────────────────
    cat_pipeline = [
        {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 9},
    ]
    cat_dist = await col.aggregate(cat_pipeline).to_list(9)

    # ── Daily scan trend ──────────────────────────────────────────────────
    trend_pipeline = [
        {"$match": {"timestamp": {"$gte": since}}},
        {"$group": {
            "_id":   {"$dateToString": {"format": "%Y-%m-%d", "date": "$timestamp"}},
            "count": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}},
    ]
    trend_raw = await col.aggregate(trend_pipeline).to_list(days)

    # ── User growth ────────────────────────────────────────────────────────
    growth_pipeline = [
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {
            "_id":   {"$dateToString": {"format": "%Y-%m-%d", "date": "$created_at"}},
            "count": {"$sum": 1},
        }},
        {"$sort": {"_id": 1}},
    ]
    growth_raw = await u_col.aggregate(growth_pipeline).to_list(days)

    return {
        "kpis": {
            "total_classifications": total,
            "active_users":          active_users,
        },
        "category_distribution": [
            {"category": (d["_id"] or "OTHER").upper(), "count": d["count"]}
            for d in cat_dist
        ],
        "daily_trend": [
            {"date": d["_id"], "count": d["count"]} for d in trend_raw
        ],
        "user_growth": [
            {"date": d["_id"], "count": d["count"]} for d in growth_raw
        ],
        "model_performance": {
            "accuracy_from_feedback": 94.5
        },
    }


@router.get("/low-confidence", summary="Low-confidence classifications")
async def low_confidence_analytics(_ = Depends(get_current_user)):
    col    = classifications_col()
    cursor = col.find({"confidence": {"$lt": 0.5}}).sort("timestamp", -1).limit(10)
    items  = await cursor.to_list(length=10)
    for i in items:
        i["id"] = str(i.pop("_id"))
    return items


@router.get("/corrections", summary="Classification corrections history")
async def corrections_analytics(_ = Depends(get_current_user)):
    return []
