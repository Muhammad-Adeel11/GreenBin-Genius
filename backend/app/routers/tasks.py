"""
GreenBin Genius – Eco Tasks Router
Admin creates tasks; users enroll and earn progress automatically on each scan.
"""

from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, HTTPException, status, Depends, Query
from bson import ObjectId

from app.db.mongo import get_db
from app.routers.auth import get_current_user
from app.routers.notifications import create_notification

router = APIRouter(prefix="/api/tasks", tags=["Eco Tasks"])


# ── Collection helpers ────────────────────────────────────────

def tasks_col():
    return get_db()["tasks"]


def enrollments_col():
    return get_db()["task_enrollments"]


# ── Helpers ───────────────────────────────────────────────────

def _serialize(doc: dict) -> dict:
    doc["id"] = str(doc.pop("_id"))
    if "task_id" in doc:
        doc["task_id"] = str(doc["task_id"])
    if "user_id" in doc:
        doc["user_id"] = str(doc["user_id"])
    return doc


def _require_admin(user: dict):
    if (user.get("role") or "USER").upper() != "ADMIN":
        raise HTTPException(status_code=403, detail="Admin access required.")


# ── Public / User Endpoints ───────────────────────────────────

@router.get("", summary="List all active tasks (with user enrollment status)")
async def get_tasks(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])

    # Fetch all active tasks
    cursor = tasks_col().find({"is_active": True}).sort("created_at", -1)
    tasks = await cursor.to_list(length=100)

    # Fetch user enrollments for quick lookup
    enr_cursor = enrollments_col().find({"user_id": user_id})
    enrollments = await enr_cursor.to_list(length=500)
    enr_map = {str(e["task_id"]): e for e in enrollments}

    result = []
    for t in tasks:
        t_dict = _serialize(t)
        enr = enr_map.get(t_dict["id"])
        if enr:
            t_dict["enrolled"] = True
            t_dict["progress"] = enr["progress"]
            t_dict["enrollment_status"] = enr["status"]
            t_dict["enrolled_at"] = enr["enrolled_at"].isoformat()
        else:
            t_dict["enrolled"] = False
            t_dict["progress"] = 0
            t_dict["enrollment_status"] = "not_enrolled"
        result.append(t_dict)

    return {"success": True, "data": result}


@router.get("/mine", summary="Tasks the current user is enrolled in")
async def get_my_tasks(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])

    pipeline = [
        {"$match": {"user_id": user_id}},
        {"$addFields": {"task_oid": {"$toObjectId": "$task_id"}}},
        {"$lookup": {
            "from": "tasks",
            "localField": "task_oid",
            "foreignField": "_id",
            "as": "task"
        }},
        {"$unwind": "$task"},
        {"$sort": {"enrolled_at": -1}},
    ]
    cursor = enrollments_col().aggregate(pipeline)
    docs = await cursor.to_list(length=200)

    result = []
    for d in docs:
        task = _serialize(d["task"])
        task["progress"] = d["progress"]
        task["enrollment_status"] = d["status"]
        task["enrolled_at"] = d["enrolled_at"].isoformat()
        task["enrolled"] = True
        result.append(task)

    return {"success": True, "data": result}


@router.post("/{task_id}/enroll", summary="Enroll in (Apply Now) a task")
async def enroll_task(task_id: str, current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])

    # Task must exist and be active
    try:
        task = await tasks_col().find_one({"_id": ObjectId(task_id), "is_active": True})
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid task ID.")
    if not task:
        raise HTTPException(status_code=404, detail="Task not found or inactive.")

    # Check deadline
    if task.get("deadline") and task["deadline"] < datetime.utcnow():
        raise HTTPException(status_code=400, detail="This task has already expired.")

    # Check already enrolled
    existing = await enrollments_col().find_one({"task_id": task_id, "user_id": user_id})
    if existing:
        raise HTTPException(status_code=409, detail="Already enrolled in this task.")

    doc = {
        "task_id":     task_id,
        "user_id":     user_id,
        "progress":    0,
        "target":      task["target_count"],
        "status":      "in_progress",
        "enrolled_at": datetime.utcnow(),
        "completed_at": None,
    }
    await enrollments_col().insert_one(doc)

    await create_notification(
        user_id=user_id,
        title_en=f"Task Enrolled: {task['title']}",
        title_ur=f"ٹاسک میں شامل: {task.get('title_ur', task['title'])}",
        message_en=f"You've joined the challenge! Complete it before the deadline to earn {task['reward_points']} points.",
        message_ur=f"آپ نے چیلنج میں شمولیت اختیار کر لی! ڈیڈ لائن سے پہلے مکمل کریں اور {task['reward_points']} پوائنٹس حاصل کریں۔",
        notif_type="task",
    )

    return {"success": True, "message": "Enrolled successfully."}


@router.get("/{task_id}/progress", summary="Get my progress on a specific task")
async def get_task_progress(task_id: str, current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    enr = await enrollments_col().find_one({"task_id": task_id, "user_id": user_id})
    if not enr:
        return {"enrolled": False, "progress": 0, "status": "not_enrolled"}
    return {
        "enrolled": True,
        "progress": enr["progress"],
        "target": enr["target"],
        "status": enr["status"],
        "percentage": round((enr["progress"] / enr["target"]) * 100) if enr["target"] else 0,
    }


# ── Admin Endpoints ───────────────────────────────────────────

@router.post("", status_code=201, summary="[Admin] Create a new task")
async def create_task(body: dict, current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)

    required = ["title", "type", "target_count", "reward_points"]
    for f in required:
        if not body.get(f):
            raise HTTPException(status_code=400, detail=f"Field '{f}' is required.")

    doc = {
        "title":           body["title"],
        "title_ur":        body.get("title_ur", ""),
        "description":     body.get("description", ""),
        "description_ur":  body.get("description_ur", ""),
        "type":            body["type"],          # scan_count | category_scan | streak | manual
        "target_category": body.get("target_category"),  # e.g. "plastic" or null
        "target_count":    int(body["target_count"]),
        "reward_points":   int(body["reward_points"]),
        "badge_icon":      body.get("badge_icon", "🌿"),
        "difficulty":      body.get("difficulty", "medium"),
        "deadline":        datetime.fromisoformat(body["deadline"]) if body.get("deadline") else None,
        "is_active":       bool(body.get("is_active", True)),
        "created_by":      str(current_user["_id"]),
        "created_at":      datetime.utcnow(),
        "enrolled_count":  0,
        "completed_count": 0,
    }
    result = await tasks_col().insert_one(doc)
    return {"success": True, "id": str(result.inserted_id)}


@router.put("/{task_id}", summary="[Admin] Update a task")
async def update_task(task_id: str, body: dict, current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)

    updates = {k: v for k, v in body.items() if k not in ["_id", "id", "created_at", "created_by"]}
    if "deadline" in updates and updates["deadline"]:
        updates["deadline"] = datetime.fromisoformat(updates["deadline"])
    updates["updated_at"] = datetime.utcnow()

    res = await tasks_col().update_one({"_id": ObjectId(task_id)}, {"$set": updates})
    if res.matched_count == 0:
        raise HTTPException(status_code=404, detail="Task not found.")
    return {"success": True}


@router.patch("/{task_id}/toggle", summary="[Admin] Toggle task active/inactive")
async def toggle_task(task_id: str, current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)
    task = await tasks_col().find_one({"_id": ObjectId(task_id)})
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")
    new_state = not task.get("is_active", True)
    await tasks_col().update_one({"_id": ObjectId(task_id)}, {"$set": {"is_active": new_state}})
    return {"success": True, "is_active": new_state}


@router.delete("/{task_id}", summary="[Admin] Delete a task")
async def delete_task(task_id: str, current_user: dict = Depends(get_current_user)):
    _require_admin(current_user)
    res = await tasks_col().delete_one({"_id": ObjectId(task_id)})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Task not found.")
    # Clean up enrollments too
    await enrollments_col().delete_many({"task_id": task_id})
    return {"success": True}


@router.get("/admin/all", summary="[Admin] List all tasks including inactive")
async def admin_list_tasks(
    current_user: dict = Depends(get_current_user),
    skip: int = 0,
    limit: int = 50,
):
    _require_admin(current_user)
    cursor = tasks_col().find({}).sort("created_at", -1).skip(skip).limit(limit)
    tasks = await cursor.to_list(length=limit)
    total = await tasks_col().count_documents({})
    return {"success": True, "data": [_serialize(t) for t in tasks], "total": total}


# ── Auto-progress (called by classify.py after every scan) ───

async def update_task_progress(user_id: str, category: str):
    """
    Called internally after every successful classification.
    Increments progress on all matching in-progress enrollments.
    Awards points and sends notification on completion.
    """
    now = datetime.utcnow()

    # Find all active enrollments for this user
    cursor = enrollments_col().find({"user_id": user_id, "status": "in_progress"})
    enrollments = await cursor.to_list(length=100)

    from app.db.mongo import users_col

    for enr in enrollments:
        task_id = enr["task_id"]
        try:
            task = await tasks_col().find_one({"_id": ObjectId(task_id), "is_active": True})
        except Exception:
            continue
        if not task:
            continue

        # Check deadline
        if task.get("deadline") and task["deadline"] < now:
            await enrollments_col().update_one(
                {"_id": enr["_id"]}, {"$set": {"status": "expired"}}
            )
            continue

        task_type = task.get("type", "scan_count")

        # Determine if this scan counts toward the task
        should_increment = False
        if task_type == "scan_count":
            should_increment = True
        elif task_type == "category_scan":
            target_cat = (task.get("target_category") or "").lower()
            should_increment = (category.lower() == target_cat)

        if not should_increment:
            continue

        new_progress = enr["progress"] + 1
        target = enr["target"]

        if new_progress >= target:
            # Task completed!
            await enrollments_col().update_one(
                {"_id": enr["_id"]},
                {"$set": {"progress": target, "status": "completed", "completed_at": now}},
            )
            # Award points to user
            await users_col().update_one(
                {"_id": ObjectId(user_id)},
                {"$inc": {"total_points": task["reward_points"]}},
            )
            # Increment completed_count on task
            await tasks_col().update_one(
                {"_id": ObjectId(task_id)}, {"$inc": {"completed_count": 1}}
            )
            # Send completion notification
            await create_notification(
                user_id=user_id,
                title_en=f"🎉 Task Completed: {task['title']}",
                title_ur=f"🎉 ٹاسک مکمل: {task.get('title_ur', task['title'])}",
                message_en=f"You earned {task['reward_points']} points! {task.get('badge_icon', '🌿')}",
                message_ur=f"آپ نے {task['reward_points']} پوائنٹس حاصل کیے! {task.get('badge_icon', '🌿')}",
                notif_type="achievement",
            )
        else:
            await enrollments_col().update_one(
                {"_id": enr["_id"]}, {"$set": {"progress": new_progress}}
            )
