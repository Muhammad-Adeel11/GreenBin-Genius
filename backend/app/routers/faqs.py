"""
GreenBin Genius – FAQs & Resources Router
Provides full CRUD for FAQs and Resources (admin-managed, stored in MongoDB).
On request to list FAQs/Resources, default collections are seeded if empty.
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from bson import ObjectId
from bson.errors import InvalidId

from app.db.mongo import faqs_col, resources_col
from app.routers.auth import get_current_user
from app.models.schemas import (
    FAQCreate, FAQUpdate, FAQResponse, FAQListResponse,
    ResourceCreate, ResourceUpdate, ResourceResponse, ResourceListResponse
)

router = APIRouter(prefix="/api", tags=["FAQs & Resources"])

# ── Defaults for Seeding ─────────────────────────────────────
DEFAULT_FAQS = [
    {
        "question_en": "What is GreenBin Genius?",
        "question_ur": "گرین بن جینیئس کیا ہے؟",
        "answer_en": "GreenBin Genius is an AI-powered waste classification assistant designed to help users identify recyclables and locate nearby disposal bins.",
        "answer_ur": "گرین بن جینیئس ایک اے آئی سے چلنے والا کوڑا کرکٹ کی درجہ بندی کا معاون ہے جو صارفین کو ری سائیکل کی جانے والی اشیاء کی شناخت اور قریبی ڈبوں کو تلاش کرنے میں مدد کرتا ہے۔",
        "category": "general",
        "is_active": True
    },
    {
        "question_en": "How does the AI waste classification work?",
        "question_ur": "اے آئی کوڑے کی درجہ بندی کیسے کام کرتی ہے؟",
        "answer_en": "Our system uses a combined deep learning approach (CNN and YOLOv8 models) to analyze the waste image you upload and identify the waste material and category.",
        "answer_ur": "ہمارا سسٹم آپ کی اپ لوڈ کردہ تصویر کا تجزیہ کرنے اور کوڑے کے مواد اور زمرے کی شناخت کرنے کے لیے ایک گہری لرننگ اپروچ (CNN اور YOLOv8 ماڈلز) کا استعمال کرتا ہے۔",
        "category": "classification",
        "is_active": True
    },
    {
        "question_en": "What should I do if the AI makes a mistake?",
        "question_ur": "اگر اے آئی کوئی غلطی کرے تو مجھے کیا کرنا چاہئے؟",
        "answer_en": "You can submit a correction by tapping the 'Wrong' button on the classification result screen. Correcting classification mistakes awards you +5 contribution points!",
        "answer_ur": "آپ درجہ بندی کے نتیجے کی اسکرین پر 'غلط' بٹن پر ٹیپ کر کے تصحیح جمع کر سکتے ہیں۔ غلطیوں کی تصحیح کرنے پر آپ کو +5 کنٹریبیوشن پوائنٹس ملیں گے!",
        "category": "classification",
        "is_active": True
    },
    {
        "question_en": "How do I find a recycling bin near me?",
        "question_ur": "میں اپنے قریب ری سائیکلنگ بن کیسے تلاش کروں؟",
        "answer_en": "Go to the 'Bin Locator' page or tap 'Find Nearest Bin' on any classification result to see nearby active bins sorted by distance.",
        "answer_ur": "قریبی ڈبوں کو فاصلے کے لحاظ سے ترتیب وار دیکھنے کے لیے 'بن لوکیٹر' صفحہ پر جائیں یا کسی بھی درجہ بندی کے نتیجے پر 'قریبی بن تلاش کریں' پر ٹیپ کریں۔",
        "category": "locator",
        "is_active": True
    }
]

DEFAULT_RESOURCES = [
    {
        "title": "Official EPA Recycling Guide",
        "url": "https://www.epa.gov/recycle",
        "category": "Education",
        "icon": "📖",
        "description": "Comprehensive guide on what and how to recycle household materials.",
        "is_active": True
    },
    {
        "title": "Home Composting Basics",
        "url": "https://www.epa.gov/recycle/composting-home",
        "category": "Composting",
        "icon": "🌱",
        "description": "Learn how to turn organic waste into nutrient-rich soil at home.",
        "is_active": True
    },
    {
        "title": "Reducing Household Plastic",
        "url": "https://www.plasticfreejuly.org/",
        "category": "Tips",
        "icon": "🚫",
        "description": "Simple challenges and ideas to help reduce your everyday plastic consumption.",
        "is_active": True
    },
    {
        "title": "Electronic Waste (e-Waste) Disposal",
        "url": "https://www.consumerreports.org/recycling/how-to-recycle-electronics/",
        "category": "E-Waste",
        "icon": "💻",
        "description": "Safety guidelines and centers for responsible electronic device recycling.",
        "is_active": True
    }
]


# ── Helpers ──────────────────────────────────────────────────

def _serialize(doc: dict) -> dict:
    """Convert a MongoDB document to a JSON-serialisable dict."""
    doc["id"] = str(doc.pop("_id"))
    return doc


def _require_admin(user: dict):
    role = (user.get("role") or "").upper()
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )


async def _seed_faqs_if_empty():
    col = faqs_col()
    if await col.count_documents({}) == 0:
        docs = []
        for item in DEFAULT_FAQS:
            docs.append({
                **item,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            })
        await col.insert_many(docs)


async def _seed_resources_if_empty():
    col = resources_col()
    if await col.count_documents({}) == 0:
        docs = []
        for item in DEFAULT_RESOURCES:
            docs.append({
                **item,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            })
        await col.insert_many(docs)


# ── FAQS ENDPOINTS ───────────────────────────────────────────

@router.get("/faqs", response_model=FAQListResponse, summary="List all FAQs")
async def list_faqs(
    limit:  int = Query(default=20, le=100),
    skip:   int = Query(default=0, ge=0),
    active: Optional[bool] = Query(default=None),
):
    await _seed_faqs_if_empty()
    col = faqs_col()
    query: dict = {}
    if active is not None:
        query["is_active"] = active

    total = await col.count_documents(query)
    cursor = col.find(query).skip(skip).limit(limit)
    docs = [_serialize(d) async for d in cursor]
    return {"total": total, "data": docs}


@router.get("/faqs/{faq_id}", response_model=FAQResponse, summary="Get FAQ by ID")
async def get_faq(faq_id: str):
    try:
        oid = ObjectId(faq_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid FAQ ID.")
    doc = await faqs_col().find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="FAQ not found.")
    return _serialize(doc)


@router.post("/faqs", response_model=FAQResponse, status_code=201, summary="Create a new FAQ (Admin)")
async def create_faq(
    body: FAQCreate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    now = datetime.utcnow()
    doc = {
        **body.model_dump(),
        "created_at": now,
        "updated_at": now,
    }
    result = await faqs_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


@router.put("/faqs/{faq_id}", response_model=FAQResponse, summary="Update an FAQ (Admin)")
async def update_faq(
    faq_id: str,
    body:   FAQUpdate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(faq_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid FAQ ID.")

    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    updates["updated_at"] = datetime.utcnow()

    result = await faqs_col().find_one_and_update(
        {"_id": oid},
        {"$set": updates},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="FAQ not found.")
    return _serialize(result)


@router.delete("/faqs/{faq_id}", summary="Delete an FAQ (Admin)")
async def delete_faq(
    faq_id: str,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(faq_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid FAQ ID.")

    result = await faqs_col().delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="FAQ not found.")
    return {"success": True, "message": "FAQ deleted successfully."}


@router.post("/faqs/seed", summary="(Admin) Seed defaults for FAQs & Resources")
async def seed_faqs_resources(current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)
    
    # Reset FAQs
    f_col = faqs_col()
    await f_col.drop()
    await _seed_faqs_if_empty()
    faqs_count = await f_col.count_documents({})

    # Reset Resources
    r_col = resources_col()
    await r_col.drop()
    await _seed_resources_if_empty()
    resources_count = await r_col.count_documents({})

    return {
        "success": True,
        "seeded_faqs": faqs_count,
        "seeded_resources": resources_count
    }


# ── RESOURCES ENDPOINTS ───────────────────────────────────────

@router.get("/resources", response_model=ResourceListResponse, summary="List all resources")
async def list_resources(
    limit:  int = Query(default=50, le=100),
    skip:   int = Query(default=0, ge=0),
    active: Optional[bool] = Query(default=None),
):
    await _seed_resources_if_empty()
    col = resources_col()
    query: dict = {}
    if active is not None:
        query["is_active"] = active

    total = await col.count_documents(query)
    cursor = col.find(query).skip(skip).limit(limit)
    docs = [_serialize(d) async for d in cursor]
    return {"total": total, "data": docs}


@router.get("/resources/{res_id}", response_model=ResourceResponse, summary="Get resource by ID")
async def get_resource(res_id: str):
    try:
        oid = ObjectId(res_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid resource ID.")
    doc = await resources_col().find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Resource not found.")
    return _serialize(doc)


@router.post("/resources", response_model=ResourceResponse, status_code=201, summary="Create a new resource (Admin)")
async def create_resource(
    body: ResourceCreate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    now = datetime.utcnow()
    doc = {
        **body.model_dump(),
        "created_at": now,
        "updated_at": now,
    }
    result = await resources_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


@router.put("/resources/{res_id}", response_model=ResourceResponse, summary="Update a resource (Admin)")
async def update_resource(
    res_id: str,
    body:   ResourceUpdate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(res_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid resource ID.")

    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    updates["updated_at"] = datetime.utcnow()

    result = await resources_col().find_one_and_update(
        {"_id": oid},
        {"$set": updates},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Resource not found.")
    return _serialize(result)


@router.delete("/resources/{res_id}", summary="Delete a resource (Admin)")
async def delete_resource(
    res_id: str,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(res_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid resource ID.")

    result = await resources_col().delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Resource not found.")
    return {"success": True, "message": "Resource deleted successfully."}
