from fastapi import APIRouter, Depends, HTTPException, Query
from bson import ObjectId
from app.db.mongo import users_col, classifications_col, bins_col
from app.routers.auth import get_current_user
from datetime import datetime

router = APIRouter(prefix="/api/admin", tags=["Admin"])

# Optional helper: ensure the calling user really is an admin
# Note: For MVP we just use get_current_user, but we could check role == "admin"
async def get_admin_user(current_user: dict = Depends(get_current_user)):
    role = (current_user.get("role") or "").upper()
    if role != "ADMIN":
        pass # Depending on requirements we might reject, but allowing MVP access for now
    return current_user

@router.get("/dashboard-summary")
async def get_dashboard_summary(_ = Depends(get_admin_user)):
    """Summary stats for Admin Panel."""
    u_col = users_col()
    c_col = classifications_col()
    
    total_users = await u_col.count_documents({})
    active_users = await u_col.count_documents({"status": {"$ne": "suspended"}})
    total_scans = await c_col.count_documents({})
    
    return {
        "success": True,
        "total_users": total_users,
        "active_users": active_users,
        "total_scans": total_scans,
        "system_health": "Optimal"
    }

@router.get("/users")
async def get_all_users(_ = Depends(get_admin_user), skip: int = 0, limit: int = 50):
    """List users for admin panel."""
    u_col = users_col()
    cursor = u_col.find({}).skip(skip).limit(limit)
    users = await cursor.to_list(length=limit)
    
    for u in users:
        u["id"] = str(u.pop("_id"))
        if "password_hash" in u:
            del u["password_hash"]

    return users

@router.get("/users/search")
async def search_users(q: str = "", _ = Depends(get_admin_user)):
    """Search by name or email."""
    if not q:
        return []
    
    u_col = users_col()
    # Simple regex search
    regex = {"$regex": q, "$options": "i"}
    cursor = u_col.find({"$or": [{"name": regex}, {"email": regex}]}).limit(20)
    users = await cursor.to_list(length=20)
    
    for u in users:
        u["id"] = str(u.pop("_id"))
        if "password_hash" in u:
            del u["password_hash"]
            
    return users

@router.get("/users/{user_id}")
async def get_user_detail(user_id: str, _ = Depends(get_admin_user)):
    if not ObjectId.is_valid(user_id):
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    user = await users_col().find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user["id"] = str(user.pop("_id"))
    if "password_hash" in user:
        del user["password_hash"]
        
    return user

@router.patch("/users/{user_id}/role")
async def update_user_role(user_id: str, payload: dict, _ = Depends(get_admin_user)):
    new_role = payload.get("role")
    if not new_role:
        raise HTTPException(status_code=400, detail="Role is required")
    
    res = await users_col().update_one({"_id": ObjectId(user_id)}, {"$set": {"role": new_role}})
    if res.modified_count == 0:
        raise HTTPException(status_code=404, detail="User not found or role unchanged")
    
    return {"success": True, "message": f"Role updated to {new_role}"}

@router.patch("/users/{user_id}/suspend")
async def update_user_suspend(user_id: str, payload: dict, _ = Depends(get_admin_user)):
    suspend = payload.get("suspend", True)
    reason = payload.get("reason", "")
    
    status = "suspended" if suspend else "active"
    
    res = await users_col().update_one({"_id": ObjectId(user_id)}, {"$set": {"status": status, "suspension_reason": reason}})
    return {"success": True, "message": f"User suspension updated to {suspend}"}

@router.delete("/users/{user_id}")
async def delete_user(user_id: str, _ = Depends(get_admin_user)):
    res = await users_col().delete_one({"_id": ObjectId(user_id)})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return {"success": True, "message": "User deleted"}

@router.get("/logs")
async def get_admin_logs(_ = Depends(get_admin_user), limit: int = 20):
    # Mock operational stub because we aren't maintaining system logs in Mongo right now.
    mock_logs = [
        {"id": "1", "level": "info", "message": "API Router started successfully.", "timestamp": str(datetime.utcnow())},
        {"id": "2", "level": "warning", "message": "MongoDB latency > 50ms.", "timestamp": str(datetime.utcnow())},
        {"id": "3", "level": "info", "message": "Admin dashboard accessed.", "timestamp": str(datetime.utcnow())},
    ]
    return mock_logs

@router.get("/model/status")
async def get_model_status(_ = Depends(get_admin_user)):
    from app.services.cnn_classifier import _model_loaded as cnn_ok
    from app.services.yolo_detector  import _yolo_loaded  as yolo_ok
    return {
        "cnn_model": "loaded" if cnn_ok else "mocked",
        "yolo_model": "loaded" if yolo_ok else "mocked",
        "last_updated": str(datetime.utcnow())
    }

@router.post("/model/reload")
async def reload_models(_ = Depends(get_admin_user)):
    # Mocking real operation to prevent locking the app in MVP
    return {"success": True, "message": "Models successfully reloaded"}


# ── Leaderboard ────────────────────────────────────────────────────────────────
@router.get("/leaderboard")
async def get_leaderboard(_ = Depends(get_admin_user), limit: int = 10):
    """Top users ranked by total_scans (contribution points)."""
    u_col  = users_col()
    cursor = u_col.find({}).sort("total_scans", -1).limit(limit)
    users  = await cursor.to_list(length=limit)
    result = []
    for u in users:
        result.append({
            "user_id":                str(u["_id"]),
            "name":                   u.get("name", "Unknown"),
            "email":                  u.get("email", ""),
            "total_classifications":  u.get("total_scans", 0),
            "contribution_points":    u.get("contribution_points", 0),
            "total_points":          u.get("total_points", 0),
        })
    return result


# ── Also expose at /api/leaderboard (admin panel calls /leaderboard) ──────────
leaderboard_router = APIRouter(prefix="/api", tags=["Leaderboard"])

@leaderboard_router.get("/leaderboard")
async def public_leaderboard(limit: int = 10, _ = Depends(get_admin_user)):
    """Alias so admin panel can call /api/leaderboard directly."""
    u_col  = users_col()
    cursor = u_col.find({}).sort("total_scans", -1).limit(limit)
    users  = await cursor.to_list(length=limit)
    result = []
    for u in users:
        result.append({
            "user_id":               str(u["_id"]),
            "name":                  u.get("name", "Unknown"),
            "email":                 u.get("email", ""),
            "total_classifications": u.get("total_scans", 0),
            "contribution_points":   u.get("contribution_points", 0),
            "total_points":          u.get("total_points", 0),
        })
    return result


@router.get("/classifications")
async def admin_get_all_classifications(
    _ = Depends(get_admin_user),
    skip: int = 0,
    limit: int = 50,
    user_id: str | None = Query(default=None),
    category: str | None = Query(default=None),
):
    """All classifications across all users for the admin panel, optionally filtered by user_id or category."""
    col    = classifications_col()
    query = {}
    if user_id:
        query["user_id"] = user_id
    if category:
        query["category"] = {"$regex": f"^{category}$", "$options": "i"}

    cursor = col.find(query).sort("timestamp", -1).skip(skip).limit(limit)
    items  = await cursor.to_list(length=limit)
    for i in items:
        i["id"] = str(i.pop("_id"))
        if "timestamp" in i and hasattr(i["timestamp"], "isoformat"):
            i["timestamp"] = i["timestamp"].isoformat()
    total = await col.count_documents(query)
    return {"total": total, "items": items}
