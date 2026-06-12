"""
GreenBin Genius – Eco-Tips Router
Provides full CRUD for disposal guidance tips (admin-managed, stored in MongoDB).
On first request to GET /api/tips, default tips are seeded from DISPOSAL_TIPS if
the collection is empty, so the admin panel always has content to edit.

Routes:
  GET    /api/tips                   → List all tips (paginated)
  GET    /api/tips/{tip_id}          → Get one tip by ID
  GET    /api/tips/category/{cat}    → Get tip for a specific waste category
  POST   /api/tips                   → Create a new tip (admin)
  PUT    /api/tips/{tip_id}          → Update a tip (admin)
  DELETE /api/tips/{tip_id}          → Delete a tip (admin)
  POST   /api/tips/feedback          → User submits a category correction
  POST   /api/tips/seed              → (Admin) Seed DB from hardcoded defaults
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from bson import ObjectId
from bson.errors import InvalidId

from app.db.mongo import eco_tips_col, classifications_col, users_col
from app.routers.auth import get_current_user
from app.routers.notifications import create_notification
from app.models.schemas import (
    EcoTipCreate, EcoTipUpdate, EcoTipResponse,
    EcoTipFeedbackRequest, EcoTipFeedbackResponse,
    EcoTipListResponse,
)
from app.services.cnn_classifier import DISPOSAL_TIPS

router = APIRouter(prefix="/api/tips", tags=["Eco Tips"])


# ── Helpers ────────────────────────────────────────────────────

def _serialize(doc: dict) -> dict:
    """Convert a MongoDB document to a JSON-serialisable dict."""
    doc["id"] = str(doc.pop("_id"))
    return doc


def _require_admin(user: dict):
    if user.get("role") != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )


async def _seed_defaults_if_empty():
    """Seed the eco_tips collection from DISPOSAL_TIPS if it is empty."""
    col = eco_tips_col()
    if await col.count_documents({}) == 0:
        docs = []
        for category, data in DISPOSAL_TIPS.items():
            docs.append({
                "waste_category":  category.upper(),
                "tip_english":     data["tip_en"],
                "tip_urdu":        data["tip_ur"],
                "bin_color":       data["bin_color"],
                "icon":            data["icon"],
                "steps":           data["steps"],
                "steps_ur":        data["steps_ur"],
                "do_list":         data["do_list"],
                "dont_list":       data["dont_list"],
                "is_active":       True,
                "created_at":      datetime.utcnow(),
                "updated_at":      datetime.utcnow(),
            })
        await col.insert_many(docs)


# ── LIST ───────────────────────────────────────────────────────

@router.get("", response_model=EcoTipListResponse, summary="List all eco tips")
async def list_tips(
    limit:  int = Query(default=20, le=100),
    skip:   int = Query(default=0, ge=0),
    active: Optional[bool] = Query(default=None),
):
    await _seed_defaults_if_empty()
    col = eco_tips_col()
    query: dict = {}
    if active is not None:
        query["is_active"] = active

    total = await col.count_documents(query)
    cursor = col.find(query).sort("waste_category", 1).skip(skip).limit(limit)
    docs = [_serialize(d) async for d in cursor]
    return {"total": total, "data": docs}


# ── GET BY CATEGORY ───────────────────────────────────────────

@router.get(
    "/category/{category}",
    response_model=EcoTipResponse,
    summary="Get disposal guidance for a waste category",
)
async def get_tip_by_category(category: str):
    await _seed_defaults_if_empty()
    col = eco_tips_col()
    doc = await col.find_one({"waste_category": category.upper(), "is_active": True})
    if not doc:
        # Fallback: build from hardcoded defaults if DB has no active tip
        data = DISPOSAL_TIPS.get(category.lower())
        if not data:
            raise HTTPException(status_code=404, detail=f"No tip found for category '{category}'")
        return {
            "id": "default",
            "waste_category": category.upper(),
            "tip_english": data["tip_en"],
            "tip_urdu": data["tip_ur"],
            "bin_color": data["bin_color"],
            "icon": data["icon"],
            "steps": data["steps"],
            "steps_ur": data["steps_ur"],
            "do_list": data["do_list"],
            "dont_list": data["dont_list"],
            "is_active": True,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
    return _serialize(doc)


# ── GET BY ID ─────────────────────────────────────────────────

@router.get("/{tip_id}", response_model=EcoTipResponse, summary="Get a tip by ID")
async def get_tip(tip_id: str):
    try:
        oid = ObjectId(tip_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid tip ID.")
    doc = await eco_tips_col().find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Tip not found.")
    return _serialize(doc)


# ── CREATE ────────────────────────────────────────────────────

@router.post("", response_model=EcoTipResponse, status_code=201, summary="Create a new tip (Admin)")
async def create_tip(
    body: EcoTipCreate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    now = datetime.utcnow()
    doc = {
        **body.model_dump(),
        "is_active":  True,
        "created_at": now,
        "updated_at": now,
    }
    result = await eco_tips_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


# ── UPDATE ────────────────────────────────────────────────────

@router.put("/{tip_id}", response_model=EcoTipResponse, summary="Update a tip (Admin)")
async def update_tip(
    tip_id: str,
    body:   EcoTipUpdate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(tip_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid tip ID.")

    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    updates["updated_at"] = datetime.utcnow()

    result = await eco_tips_col().find_one_and_update(
        {"_id": oid},
        {"$set": updates},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Tip not found.")
    return _serialize(result)


# ── DELETE ────────────────────────────────────────────────────

@router.delete("/{tip_id}", summary="Delete a tip (Admin)")
async def delete_tip(
    tip_id: str,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(tip_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid tip ID.")

    result = await eco_tips_col().delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Tip not found.")
    return {"success": True, "message": "Tip deleted successfully."}


# ── USER FEEDBACK (Correction) ────────────────────────────────

@router.post(
    "/feedback",
    response_model=EcoTipFeedbackResponse,
    summary="Submit category correction feedback",
)
async def submit_feedback(
    body: EcoTipFeedbackRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    col = classifications_col()

    # Validate classification exists
    try:
        oid = ObjectId(body.classification_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid classification ID.")

    classification = await col.find_one({"_id": oid})
    if not classification:
        raise HTTPException(status_code=404, detail="Classification not found.")

    if classification["user_id"] != user_id:
        raise HTTPException(status_code=403, detail="You can only correct your own classifications.")

    if classification.get("is_verified"):
        raise HTTPException(status_code=409, detail="Feedback already submitted for this classification.")

    # Validate corrected category
    valid_categories = list(DISPOSAL_TIPS.keys()) + [
        "plastic", "glass", "metal", "e-waste", "textile",
        "wood", "food_waste", "not_food_waste", "other",
    ]
    corrected = body.corrected_category.lower()
    if corrected not in valid_categories:
        raise HTTPException(status_code=422, detail=f"Invalid category '{corrected}'.")

    # Update the classification record
    await col.update_one(
        {"_id": oid},
        {"$set": {
            "user_feedback": corrected,
            "is_verified":   True,
            "feedback_at":   datetime.utcnow(),
        }},
    )

    # Award contribution points (+5)
    await users_col().update_one(
        {"_id": ObjectId(user_id)},
        {"$inc": {"contribution_points": 5}},
    )

    # Fetch updated user points
    updated_user = await users_col().find_one({"_id": ObjectId(user_id)})
    total_points = updated_user.get("contribution_points", 0) if updated_user else 0

    # Auto Notification: points awarded
    corrected_label = corrected.replace("_", " ").title()
    await create_notification(
        user_id    = user_id,
        title_en   = "🏆 +5 Points Earned!",
        title_ur   = "🏆 +5 پوائنٹس حاصل ہوئے!",
        message_en = f"Thanks for correcting the category to '{corrected_label}'. You now have {total_points} contribution points.",
        message_ur = f"'{corrected_label}' زمرہ درست کرنے کا شکریہ۔ آپ کے پاس اب {total_points} کنٹریبیوشن پوائنٹس ہیں۔",
        notif_type = "points",
    )

    # Fetch the updated disposal guidance for the corrected category
    tip_doc = await eco_tips_col().find_one(
        {"waste_category": corrected.upper(), "is_active": True}
    )
    guidance = None
    if tip_doc:
        guidance = _serialize(tip_doc)
    else:
        # Fallback from hardcoded
        data = DISPOSAL_TIPS.get(corrected)
        if data:
            guidance = {
                "id": "default",
                "waste_category": corrected.upper(),
                "tip_english": data["tip_en"],
                "tip_urdu":    data["tip_ur"],
                "bin_color":   data["bin_color"],
                "icon":        data["icon"],
                "steps":       data["steps"],
                "steps_ur":    data["steps_ur"],
                "do_list":     data["do_list"],
                "dont_list":   data["dont_list"],
            }

    return {
        "success":         True,
        "message":         "Thank you! Your feedback has been recorded.",
        "points_awarded":  5,
        "total_points":    total_points,
        "corrected_category": corrected,
        "updated_guidance": guidance,
    }


# ── ADMIN SEED ─────────────────────────────────────────────────

@router.post("/seed", summary="(Admin) Seed eco-tips from defaults")
async def seed_tips(current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)
    col = eco_tips_col()
    await col.drop()
    await _seed_defaults_if_empty()
    count = await col.count_documents({})
    return {"success": True, "seeded": count}
