from fastapi import APIRouter, Depends
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])

@router.get("/unread-count")
async def get_unread_count(_ = Depends(get_current_user)):
    """Stub for Admin Panel dashboard."""
    return {"count": 0}

@router.get("/")
async def get_notifications(_ = Depends(get_current_user)):
    """Stub for notifications list."""
    return []

@router.patch("/{id}/read")
async def mark_read(id: str, _ = Depends(get_current_user)):
    return {"success": True}

@router.patch("/read-all")
async def mark_all_read(_ = Depends(get_current_user)):
    return {"success": True}

@router.get("/campaigns")
async def get_campaigns(_ = Depends(get_current_user)):
    return []
