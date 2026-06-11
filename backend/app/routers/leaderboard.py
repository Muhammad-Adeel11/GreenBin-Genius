from fastapi import APIRouter, Depends
from typing import Optional
from app.db.mongo import users_col
from app.routers.auth import get_current_user_optional
from bson import ObjectId

router = APIRouter(prefix="/api", tags=["Leaderboard"])

@router.get("/leaderboard/members")
@router.get("/leaderboard")
async def get_member_leaderboard(
    limit: int = 10,
    current_user: Optional[dict] = Depends(get_current_user_optional)
):
    """
    Returns the top users based on the number of successful classifications.
    Includes the 'isMe' flag for the calling user.
    """
    u_col = users_col()
    
    # In a real app, we'd use total_scans which is already being incremented in classify.py
    cursor = u_col.find({}).sort("total_scans", -1).limit(limit)
    users = await cursor.to_list(length=limit)
    
    current_user_id = str(current_user["_id"]) if current_user else None
    
    leaderboard = []
    for rank, u in enumerate(users, 1):
        user_id = str(u["_id"])
        leaderboard.append({
            "rank": str(rank),
            "user_id": user_id,
            "name": u.get("name", "Unknown"),
            "score": f"{u.get('total_scans', 0)} PIECE{'S' if u.get('total_scans', 0) != 1 else ''}",
            "avatar": f"https://picsum.photos/100?random={user_id[-4:]}",
            "isMe": user_id == current_user_id
        })
        
    # If the current user is not in the top 10, optionally append them at the end with their real rank
    if current_user and not any(item["isMe"] for item in leaderboard):
        user_score = current_user.get("total_scans", 0)
        # Calculate rank (this is expensive in Mongo without a specialized index/count, but okay for MVP)
        rank_higher = await u_col.count_documents({"total_scans": {"$gt": user_score}})
        my_rank = rank_higher + 1
        
        leaderboard.insert(0, {
            "rank": f"{my_rank}",
            "user_id": current_user_id,
            "name": current_user.get("name", "Me"),
            "score": f"{user_score} PIECE{'S' if user_score != 1 else ''}",
            "avatar": None,
            "isMe": True
        })
        
    return leaderboard

@router.get("/leaderboard/countries")
async def get_country_leaderboard(limit: int = 10):
    """
    Returns the top countries based on total community impact.
    Still using mock data as country-level tracking isn't fully implemented in DB yet.
    """
    return [
        {'rank': '1', 'name': 'Canada', 'score': '898 PIECES', 'avatar': 'https://flagcdn.com/w160/ca.png'},
        {'rank': '2', 'name': 'Netherlands', 'score': '886 PIECES', 'avatar': 'https://flagcdn.com/w160/nl.png'},
        {'rank': '3', 'name': 'United States of America', 'score': '445 PIECES', 'avatar': 'https://flagcdn.com/w160/us.png'},
        {'rank': '4', 'name': 'Bulgaria', 'score': '188 PIECES', 'avatar': 'https://flagcdn.com/w160/bg.png'},
        {'rank': '5', 'name': 'Japan', 'score': '158 PIECES', 'avatar': 'https://flagcdn.com/w160/jp.png'},
        {'rank': '6', 'name': 'Spain', 'score': '158 PIECES', 'avatar': 'https://flagcdn.com/w160/es.png'},
    ]
