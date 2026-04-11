"""
GreenBin Genius – History Router
GET /api/history  – paginated classification history for the authenticated user.
Follows FR-6 (Classification History) from SRS.
"""

from fastapi import APIRouter, Depends, Query
from bson import ObjectId
from app.db.mongo import classifications_col
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/history", tags=["History"])


@router.get(
    "",
    summary="Get the authenticated user's classification history",
)
async def get_history(
    page: int = Query(default=1, ge=1, description="Page number (1-indexed)"),
    limit: int = Query(default=20, ge=1, le=100, description="Results per page"),
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    skip = (page - 1) * limit

    cursor = (
        classifications_col()
        .find({"user_id": user_id})
        .sort("timestamp", -1)
        .skip(skip)
        .limit(limit)
    )

    entries = []
    async for doc in cursor:
        doc["id"] = str(doc.pop("_id"))
        doc["timestamp"] = doc["timestamp"].isoformat()
        entries.append(doc)

    total = await classifications_col().count_documents({"user_id": user_id})

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "entries": entries,
    }


@router.delete(
    "/{entry_id}",
    summary="Delete a single classification history entry",
)
async def delete_entry(
    entry_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    result = await classifications_col().delete_one({
        "_id": ObjectId(entry_id),
        "user_id": user_id,          # Ensure ownership
    })
    if result.deleted_count == 0:
        return {"success": False, "message": "Entry not found or not owned by you."}
    return {"success": True, "message": "Entry deleted."}
