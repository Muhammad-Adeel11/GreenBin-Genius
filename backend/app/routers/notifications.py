"""
GreenBin Genius – Notifications Router
Handles per-user notification feeds and admin broadcast campaigns.
Exposes a create_notification() helper that other routers can import
to trigger automatic notifications (scan confirmed, points earned, etc.)
"""

from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from bson import ObjectId
from bson.errors import InvalidId

from app.db.mongo import notifications_col, campaigns_col, users_col
from app.routers.auth import get_current_user
from app.models.schemas import (
    NotificationResponse, NotificationListResponse,
    CampaignCreate, CampaignResponse, CampaignListResponse,
)
from app.services import fcm_service

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])


# ── Internal helper (imported by classify.py, eco_tips.py) ──

async def create_notification(
    user_id:    str,
    title_en:   str,
    title_ur:   str,
    message_en: str,
    message_ur: str,
    notif_type: str = "system",   # "scan" | "points" | "campaign" | "system"
) -> None:
    """
    Insert a single notification document for the given user.
    Fire-and-forget – callers should not await errors from here.
    """
    try:
        await notifications_col().insert_one({
            "user_id":    user_id,
            "title_en":   title_en,
            "title_ur":   title_ur,
            "message_en": message_en,
            "message_ur": message_ur,
            "type":       notif_type,
            "is_read":    False,
            "created_at": datetime.utcnow(),
        })
        # Fetch user's FCM token and send push
        user_doc = await users_col().find_one({"_id": __import__('bson').ObjectId(user_id)}, {"fcm_token": 1})
        fcm_token = (user_doc or {}).get("fcm_token")
        if fcm_token:
            await fcm_service.send_push(
                token  = fcm_token,
                title  = title_en,
                body   = message_en,
                data   = {"type": notif_type, "user_id": user_id},
            )
    except Exception as exc:
        # Never crash the parent request – log and swallow
        import logging
        logging.getLogger("greenbin").warning(f"[Notification] Failed to create: {exc}")


def _serialize(doc: dict) -> dict:
    doc["id"] = str(doc.pop("_id"))
    return doc


def _require_admin(user: dict):
    if user.get("role") != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required.")


# ── User Endpoints ────────────────────────────────────────────

@router.get("/unread-count", summary="Get unread notification count")
async def get_unread_count(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    count = await notifications_col().count_documents({"user_id": user_id, "is_read": False})
    return {"count": count}


@router.get("/", response_model=NotificationListResponse, summary="List notifications for current user")
async def get_notifications(
    limit: int = Query(default=30, le=100),
    skip:  int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    col = notifications_col()

    total  = await col.count_documents({"user_id": user_id})
    unread = await col.count_documents({"user_id": user_id, "is_read": False})
    cursor = col.find({"user_id": user_id}).sort("created_at", -1).skip(skip).limit(limit)
    docs   = [_serialize(d) async for d in cursor]

    return {"total": total, "unread": unread, "data": docs}


@router.patch("/{notif_id}/read", summary="Mark one notification as read")
async def mark_read(
    notif_id: str,
    current_user: dict = Depends(get_current_user),
):
    try:
        oid = ObjectId(notif_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid notification ID.")

    user_id = str(current_user["_id"])
    result  = await notifications_col().update_one(
        {"_id": oid, "user_id": user_id},
        {"$set": {"is_read": True}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found.")
    return {"success": True}


@router.patch("/read-all", summary="Mark all notifications as read")
async def mark_all_read(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    await notifications_col().update_many(
        {"user_id": user_id, "is_read": False},
        {"$set": {"is_read": True}},
    )
    return {"success": True}


# ── Admin / Campaign Endpoints ────────────────────────────────

@router.get("/campaigns", response_model=CampaignListResponse, summary="(Admin) List all campaigns")
async def get_campaigns(
    limit: int = Query(default=20, le=100),
    skip:  int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    col    = campaigns_col()
    total  = await col.count_documents({})
    cursor = col.find({}).sort("created_at", -1).skip(skip).limit(limit)
    docs   = [_serialize(d) async for d in cursor]
    return {"total": total, "data": docs}


@router.post("/campaigns", response_model=CampaignResponse, status_code=201,
             summary="(Admin) Broadcast a notification campaign to all users")
async def create_campaign(
    body: CampaignCreate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)

    # Determine target audience
    u_col  = users_col()
    query  = {} if body.target_audience == "ALL" else {"total_scans": {"$gte": 1}}
    cursor = u_col.find(query, {"_id": 1})
    user_ids = [str(u["_id"]) async for u in cursor]

    now = datetime.utcnow()

    # Bulk-insert one notification per user
    if user_ids:
        notif_docs = [
            {
                "user_id":    uid,
                "title_en":   body.title_english,
                "title_ur":   body.title_urdu,
                "message_en": body.message_english,
                "message_ur": body.message_urdu,
                "type":       "campaign",
                "is_read":    False,
                "created_at": now,
            }
            for uid in user_ids
        ]
        await notifications_col().insert_many(notif_docs)

        # Collect FCM tokens and multicast push
        token_cursor = users_col().find(
            {"_id": {"$in": [__import__('bson').ObjectId(uid) for uid in user_ids]}, "fcm_token": {"$exists": True}},
            {"fcm_token": 1}
        )
        fcm_tokens = [u["fcm_token"] async for u in token_cursor if u.get("fcm_token")]
        if fcm_tokens:
            await fcm_service.send_push_multicast(
                tokens = fcm_tokens,
                title  = body.title_english,
                body   = body.message_english,
                data   = {"type": "campaign"},
            )

    # Save campaign record
    campaign_doc = {
        "title_english":    body.title_english,
        "title_urdu":       body.title_urdu,
        "message_english":  body.message_english,
        "message_urdu":     body.message_urdu,
        "target_audience":  body.target_audience,
        "recipients_count": len(user_ids),
        "created_at":       now,
    }
    result = await campaigns_col().insert_one(campaign_doc)
    campaign_doc["_id"] = result.inserted_id
    return _serialize(campaign_doc)
