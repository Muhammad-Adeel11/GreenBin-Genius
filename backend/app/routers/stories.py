"""
GreenBin Genius – Impact Stories Router
Provides dynamic stories of impact for both mobile display and admin panel CRUD.
"""

import os
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from bson import ObjectId
from bson.errors import InvalidId
import cloudinary.uploader

from app.db.mongo import stories_col
from app.routers.auth import get_current_user
from app.models.schemas import (
    StoryCreate, StoryUpdate, StoryResponse, StoryListResponse
)

router = APIRouter(prefix="/api/stories", tags=["Impact Stories"])

DEFAULT_STORIES = [
    {
        "title": "Cleaning the Golden Gate",
        "image_url": "https://picsum.photos/300/200?random=1",
        "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "description": "Volunteers gathered at the Golden Gate Bridge to clear plastic waste and litter, collecting over 2 tons of recyclable materials in a single afternoon.",
        "is_active": True
    },
    {
        "title": "School Project in Spain",
        "image_url": "https://picsum.photos/300/200?random=2",
        "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "description": "A local primary school in Madrid implemented a zero-waste lunch initiative. Students learned how to sort compostable waste, recyclable paper, and plastics, reducing their trash output by 80%.",
        "is_active": True
    },
    {
        "title": "Ocean Cleanup Initiative",
        "image_url": "https://picsum.photos/300/200?random=3",
        "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "description": "Deploying innovative floating barriers to collect ocean waste. This initiative has successfully removed tons of microplastics and discarded nets from marine ecosystems.",
        "is_active": True
    }
]

# ── Helpers ──────────────────────────────────────────────────

def _serialize(doc: dict) -> dict:
    """Convert MongoDB _id to string id."""
    doc["id"] = str(doc.pop("_id"))
    return doc


def _require_admin(user: dict):
    role = (user.get("role") or "").upper()
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required.",
        )


async def _seed_stories_if_empty():
    col = stories_col()
    if await col.count_documents({}) == 0:
        docs = []
        for item in DEFAULT_STORIES:
            docs.append({
                **item,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            })
        await col.insert_many(docs)


# ── GET ALL ──────────────────────────────────────────────────

@router.get("", response_model=StoryListResponse, summary="List all stories")
async def list_stories(
    limit:  int = Query(default=20, le=100),
    skip:   int = Query(default=0, ge=0),
    active: Optional[bool] = Query(default=None),
):
    await _seed_stories_if_empty()
    col = stories_col()
    query: dict = {}
    if active is not None:
        query["is_active"] = active

    total = await col.count_documents(query)
    cursor = col.find(query).sort("created_at", -1).skip(skip).limit(limit)
    docs = [_serialize(d) async for d in cursor]
    return {"total": total, "data": docs}


# ── GET ONE ──────────────────────────────────────────────────

@router.get("/{story_id}", response_model=StoryResponse, summary="Get one story by ID")
async def get_story(story_id: str):
    await _seed_stories_if_empty()
    try:
        oid = ObjectId(story_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid story ID.")
    doc = await stories_col().find_one({"_id": oid})
    if not doc:
        raise HTTPException(status_code=404, detail="Story not found.")
    return _serialize(doc)


# ── CREATE ───────────────────────────────────────────────────

@router.post("", response_model=StoryResponse, status_code=201, summary="Create a new story (Admin)")
async def create_story(
    body: StoryCreate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    now = datetime.utcnow()
    doc = {
        **body.model_dump(),
        "created_at": now,
        "updated_at": now,
    }
    result = await stories_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


# ── UPDATE ───────────────────────────────────────────────────

@router.put("/{story_id}", response_model=StoryResponse, summary="Update a story (Admin)")
async def update_story(
    story_id: str,
    body: StoryUpdate,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(story_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid story ID.")

    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    updates["updated_at"] = datetime.utcnow()

    result = await stories_col().find_one_and_update(
        {"_id": oid},
        {"$set": updates},
        return_document=True,
    )
    if not result:
        raise HTTPException(status_code=404, detail="Story not found.")
    return _serialize(result)


# ── DELETE ───────────────────────────────────────────────────

@router.delete("/{story_id}", summary="Delete a story (Admin)")
async def delete_story(
    story_id: str,
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        oid = ObjectId(story_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="Invalid story ID.")

    result = await stories_col().delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Story not found.")
    return {"success": True, "message": "Story deleted successfully."}


# ── CLOUDINARY UPLOAD ────────────────────────────────────────

@router.post("/upload", summary="(Admin) Upload cover image to Cloudinary")
async def upload_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    _require_admin(current_user)
    try:
        content = await file.read()
        if not (os.getenv("CLOUDINARY_URL") or os.getenv("CLOUDINARY_CLOUD_NAME")):
            raise HTTPException(status_code=400, detail="Cloudinary is not configured in .env")
        upload_res = cloudinary.uploader.upload(content)
        url = upload_res.get("secure_url")
        if not url:
            raise HTTPException(status_code=500, detail="Cloudinary did not return a secure URL.")
        return {"secure_url": url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {e}")
