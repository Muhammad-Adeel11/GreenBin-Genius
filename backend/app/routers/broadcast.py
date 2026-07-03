"""
GreenBin Genius – Broadcast & Quote Scheduler Router
Provides management for eco-tip broadcasts, predefined quote libraries, and scheduled notifications.
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from bson import ObjectId
from bson.errors import InvalidId

from app.db.mongo import broadcast_schedules_col, users_col, notifications_col
from app.routers.auth import get_current_user
from app.routers.notifications import create_notification
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/broadcast", tags=["Broadcast & Quotes"])

# ── Predefined Quote Library ──────────────────────────────────
PREDEFINED_QUOTES = [
    {
        "id": "1",
        "quote_en": "The Earth does not belong to us, we belong to the Earth.",
        "quote_ur": "زمین ہماری نہیں، ہم زمین کے ہیں۔",
        "author_en": "Chief Seattle",
        "author_ur": "چیف سیئٹل"
    },
    {
        "id": "2",
        "quote_en": "We do not inherit the Earth from our ancestors; we borrow it from our children.",
        "quote_ur": "ہمیں زمین آباؤ اجداد سے وراثت میں نہیں ملی، ہم نے اسے بچوں سے ادھار لیا ہے۔",
        "author_en": "Native American Proverb",
        "author_ur": "قدیم امریکی ضرب المثل"
    },
    {
        "id": "3",
        "quote_en": "The greatest threat to our planet is the belief that someone else will save it.",
        "quote_ur": "ہمارے سیارے کے لیے سب سے بڑا خطرہ یہ یقین رکھنا ہے کہ کوئی اور اسے بچائے گا۔",
        "author_en": "Robert Swan",
        "author_ur": "رابرٹ سوان"
    },
    {
        "id": "4",
        "quote_en": "Small acts, when multiplied by millions of people, can transform the world.",
        "quote_ur": "چھوٹے اقدامات، جب لاکھوں لوگوں کی طرف سے کیے جائیں، دنیا کو بدل سکتے ہیں۔",
        "author_en": "Howard Zinn",
        "author_ur": "ہاورڈ زن"
    },
    {
        "id": "5",
        "quote_en": "Be the change you wish to see in the world.",
        "quote_ur": "وہ تبدیلی بنیں جو آپ دنیا میں دیکھنا چاہتے ہیں۔",
        "author_en": "Mahatma Gandhi",
        "author_ur": "مہاتما گاندھی"
    },
    {
        "id": "6",
        "quote_en": "Reduce, Reuse, Recycle — in that order.",
        "quote_ur": "کم کریں، دوبارہ استعمال کریں، ری سائیکل کریں — اسی ترتیب سے۔",
        "author_en": "Eco Guide",
        "author_ur": "ماحولیاتی رہنما"
    },
    {
        "id": "7",
        "quote_en": "One person's trash is another planet's treasure when we recycle.",
        "quote_ur": "جب ہم ری سائیکل کرتے ہیں تو ایک شخص کا کچرا دوسرے کے لیے خزانہ بن جاتا ہے۔",
        "author_en": "Recycling Tip",
        "author_ur": "ری سائیکلنگ گائیڈ"
    },
    {
        "id": "8",
        "quote_en": "Recycling turns things into other things — which is like magic.",
        "quote_ur": "ری سائیکلنگ چیزوں کو دوسری چیزوں میں بدل دیتی ہے — جو کہ جادو کی طرح ہے۔",
        "author_en": "Eco Quote",
        "author_ur": "ماحولیاتی قول"
    }
]

# ── Schemas ───────────────────────────────────────────────────

class BroadcastSendRequest(BaseModel):
    quote_en: str
    quote_ur: str
    author_en: Optional[str] = ""
    author_ur: Optional[str] = ""

class BroadcastScheduleRequest(BaseModel):
    quote_en: str
    quote_ur: str
    author_en: Optional[str] = ""
    author_ur: Optional[str] = ""
    send_mode: str = Field(..., description="'once' or 'weekly'")
    send_at: Optional[datetime] = None  # Needed for both once and weekly (specifies start time / trigger time)
    weekday: Optional[int] = None      # 0=Mon ... 6=Sun (needed for weekly)

# ── Helpers ───────────────────────────────────────────────────

def _require_admin(user: dict):
    role = (user.get("role") or "").upper()
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )

def _serialize(doc: dict) -> dict:
    doc["id"] = str(doc.pop("_id"))
    return doc

# ── Endpoints ──────────────────────────────────────────────────

@router.get("/quotes", summary="Get predefined short eco quotes")
async def get_predefined_quotes():
    return PREDEFINED_QUOTES

@router.get("/schedules", summary="List scheduled broadcasts")
async def get_schedules(current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)
    cursor = broadcast_schedules_col().find({}).sort("created_at", -1)
    docs = [_serialize(d) async for d in cursor]
    return docs

@router.post("/send", summary="Send broadcast immediately to users who have notifications enabled")
async def send_broadcast_now(
    body: BroadcastSendRequest,
    current_user: dict = Depends(get_current_user)
):
    _require_admin(current_user)
    
    # Query users who have notifications enabled
    cursor = users_col().find({"notifications_enabled": {"$ne": False}}, {"_id": 1})
    user_ids = [str(u["_id"]) async for u in cursor]
    
    if not user_ids:
        return {"success": True, "recipients_count": 0, "message": "No active users have notifications enabled."}

    # Save to campaigns or log as broadcast schedule
    log_doc = {
        "quote_en": body.quote_en,
        "quote_ur": body.quote_ur,
        "author_en": body.author_en,
        "author_ur": body.author_ur,
        "send_mode": "sent_immediate",
        "sent_at": datetime.utcnow(),
        "created_by": str(current_user["_id"]),
        "created_at": datetime.utcnow()
    }
    await broadcast_schedules_col().insert_one(log_doc)

    title_en = "🌱 Eco Tip of the Day"
    title_ur = "🌱 آج کا ماحولیاتی مشورہ"
    msg_en = f"\"{body.quote_en}\" - {body.author_en}" if body.author_en else f"\"{body.quote_en}\""
    msg_ur = f"\"{body.quote_ur}\" - {body.author_ur}" if body.author_ur else f"\"{body.quote_ur}\""

    # Send notifications in bulk
    for uid in user_ids:
        await create_notification(
            user_id=uid,
            title_en=title_en,
            title_ur=title_ur,
            message_en=msg_en,
            message_ur=msg_ur,
            notif_type="system"
        )
        
    return {"success": True, "recipients_count": len(user_ids)}

@router.post("/schedule", summary="Schedule a broadcast notification")
async def schedule_broadcast(
    body: BroadcastScheduleRequest,
    current_user: dict = Depends(get_current_user)
):
    _require_admin(current_user)
    
    if body.send_mode not in ["once", "weekly"]:
        raise HTTPException(status_code=400, detail="send_mode must be 'once' or 'weekly'")
        
    if not body.send_at:
        raise HTTPException(status_code=400, detail="send_at date-time is required")

    doc = {
        "quote_en": body.quote_en,
        "quote_ur": body.quote_ur,
        "author_en": body.author_en,
        "author_ur": body.author_ur,
        "send_mode": body.send_mode,
        "send_at": body.send_at,
        "weekday": body.weekday,
        "sent_at": None,
        "created_by": str(current_user["_id"]),
        "created_at": datetime.utcnow()
    }
    
    res = await broadcast_schedules_col().insert_one(doc)
    doc["id"] = str(res.inserted_id)
    return doc

@router.delete("/schedules/{schedule_id}", summary="Cancel/delete a scheduled broadcast")
async def cancel_schedule(
    schedule_id: str,
    current_user: dict = Depends(get_current_user)
):
    _require_admin(current_user)
    try:
        oid = ObjectId(schedule_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid schedule ID")
        
    res = await broadcast_schedules_col().delete_one({"_id": oid})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Schedule not found")
        
    return {"success": True, "message": "Schedule deleted successfully"}
