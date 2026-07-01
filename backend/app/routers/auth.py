"""
GreenBin Genius – Auth Router
Handles user registration, login, and JWT token issuance.
Follows FR-1 (User Registration) and FR-2 (User Login) from SRS.
"""

import os
import httpx
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from jose import JWTError, jwt
from bson import ObjectId

from app.models.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    SuccessResponse,
    GoogleVerifyClaimRequest,
)
from app.db.mongo import users_col

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# ── Config ───────────────────────────────────────────────────
SECRET_KEY = os.getenv("JWT_SECRET", "changeme")
ALGORITHM  = os.getenv("JWT_ALGORITHM", "HS256")
EXPIRE_MIN = int(os.getenv("JWT_EXPIRE_MINUTES", "10080"))

# Google OAuth
GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"
GOOGLE_WEB_CLIENT_ID = os.getenv(
    "GOOGLE_WEB_CLIENT_ID",
    "765275404655-r49q8li2knel95shk0g0iqooundd5c2s.apps.googleusercontent.com"
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


# ── Helpers ──────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_token(user_id: str, email: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=EXPIRE_MIN)
    payload = {"sub": user_id, "email": email, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """Dependency – validates JWT and returns the user document."""
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: Optional[str] = payload.get("sub")
        if user_id is None:
            raise credentials_exc
    except JWTError:
        raise credentials_exc

    user = await users_col().find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise credentials_exc
    return user


async def get_current_user_optional(token: Optional[str] = Depends(oauth2_scheme)) -> Optional[dict]:
    """Dependency – returns the user document if token is valid, otherwise None."""
    if not token:
        return None
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: Optional[str] = payload.get("sub")
        if user_id is None:
            return None
        return await users_col().find_one({"_id": ObjectId(user_id)})
    except:
        return None


# ── Routes ───────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
async def register(body: UserRegisterRequest):
    # Check if email already exists
    existing = await users_col().find_one({"email": body.email})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    hashed = hash_password(body.password)
    doc = {
        "name":       body.name,
        "email":      body.email,
        "password":   hashed,
        "language":   body.language or "en",
        "created_at": datetime.utcnow(),
        "goals":      [],
        "streak":     0,
        "total_scans": 0,
    }
    result = await users_col().insert_one(doc)
    user_id = str(result.inserted_id)
    token = create_token(user_id, body.email)

    return TokenResponse(
        access_token=token,
        user_id=user_id,
        name=body.name,
        email=body.email,
        user={
            "id": user_id,
            "name": body.name,
            "email": body.email,
            "role": "USER"
        }
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login and receive a JWT token",
)
async def login(body: UserLoginRequest):
    user = await users_col().find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    user_id = str(user["_id"])
    token = create_token(user_id, body.email)
    role = user.get("role", "USER").upper()

    return TokenResponse(
        access_token=token,
        user_id=user_id,
        name=user["name"],
        email=user["email"],
        user={
            "id": user_id,
            "name": user["name"],
            "email": user["email"],
            "role": role
        }
    )


@router.post(
    "/admin-login",
    response_model=TokenResponse,
    summary="Login strictly for administrators",
)
async def admin_login(body: UserLoginRequest):
    user = await users_col().find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    # Specific Admin Role check
    role = (user.get("role") or "").upper()
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied. Administrator privileges required.",
        )

    user_id = str(user["_id"])
    token = create_token(user_id, body.email)
    role = user.get("role", "ADMIN").upper()

    return TokenResponse(
        access_token=token,
        user_id=user_id,
        name=user["name"],
        email=user["email"],
        user={
            "id": user_id,
            "name": user["name"],
            "email": user["email"],
            "role": role
        }
    )


@router.get(
    "/me",
    summary="Get the currently authenticated user's profile",
)
async def get_me(current_user: dict = Depends(get_current_user)):
    return {
        "user_id":      str(current_user["_id"]),
        "name":         current_user.get("name", "Guest User"),
        "email":        current_user.get("email", ""),
        "username":     current_user.get("username", ""),
        "profile_image": current_user.get("profile_image", ""),
        "language":     current_user.get("language", "en"),
        "total_scans":  current_user.get("total_scans", 0),
        "streak":       current_user.get("streak", 0),
        "is_anonymous": current_user.get("is_anonymous", False),
        "claimed_at":   current_user.get("claimed_at", None) and
                        current_user["claimed_at"].isoformat() if current_user.get("claimed_at") else None,
    }


@router.post(
    "/fcm-token",
    summary="Save or update the device's FCM push token",
)
async def save_fcm_token(
    body: dict,
    current_user: dict = Depends(get_current_user),
):
    """
    Called by the Flutter app on startup (after Firebase.initializeApp).
    Stores the FCM token in the user's MongoDB document so the backend
    can send push notifications to this specific device.
    Body: { "fcm_token": "<device_token_string>" }
    """
    token = body.get("fcm_token", "").strip()
    if not token:
        raise HTTPException(status_code=400, detail="fcm_token is required.")

    await users_col().update_one(
        {"_id": current_user["_id"]},
        {"$set": {"fcm_token": token, "fcm_token_updated_at": datetime.utcnow()}},
    )
    return {"success": True, "message": "FCM token saved."}


@router.post(
    "/verify-google",
    response_model=TokenResponse,
    summary="Verify a Google idToken and claim an anonymous account",
)
async def verify_google_and_claim(
    body: GoogleVerifyClaimRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Receives a Google ID token from the Flutter app (google_sign_in).
    1. Calls Google's public tokeninfo endpoint to verify the token is genuine.
    2. Checks that email_verified = true (real Gmail inbox).
    3. Checks token audience matches our Web Client ID.
    4. Upgrades the anonymous MongoDB user document inline — all scan
       history, points, and streak are automatically preserved.
    5. Issues a new JWT under the verified Gmail address.
    """
    # ── Step 1: Call Google's tokeninfo (no API key required) ──────────────
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(
            GOOGLE_TOKENINFO_URL,
            params={"id_token": body.id_token},
        )

    if resp.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Google token. Please sign in with Google again.",
        )

    token_data = resp.json()

    # ── Step 2: Verify Gmail is confirmed by Google ─────────────────────────
    if token_data.get("email_verified") != "true":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your Google email address has not been verified by Google.",
        )

    # ── Step 3: Confirm token belongs to our app (audience check) ──────────
    if GOOGLE_WEB_CLIENT_ID and token_data.get("aud") != GOOGLE_WEB_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token audience mismatch. Please contact support.",
        )

    verified_email = token_data.get("email", "")
    verified_name  = body.display_name or token_data.get("name") or verified_email.split("@")[0]
    google_id      = token_data.get("sub")   # Google's unique user ID
    photo_url      = body.photo_url or token_data.get("picture")

    # ── Step 4: Check the Gmail isn't already used by another account ───────
    existing_email = await users_col().find_one({
        "email": verified_email,
        "_id":   {"$ne": current_user["_id"]},
    })
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This Google account is already linked to another GreenBin account.",
        )

    # ── Step 5: Validate & check username uniqueness ────────────────────────
    update_doc: dict = {
        "name":         verified_name,
        "email":        verified_email,
        "google_id":    google_id,
        "is_anonymous": False,
        "claimed_at":   datetime.utcnow(),
    }
    if photo_url:
        update_doc["profile_image"] = photo_url

    if body.username:
        existing_uname = await users_col().find_one({
            "username": body.username,
            "_id":      {"$ne": current_user["_id"]},
        })
        if existing_uname:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Username is already taken. Please choose another.",
            )
        update_doc["username"] = body.username

    # ── Step 6: Upgrade anonymous → real account (inline, preserves history) ─
    await users_col().update_one(
        {"_id": current_user["_id"]},
        {"$set": update_doc},
    )

    # ── Step 7: Issue a new JWT under the verified Gmail ───────────────────
    user_id = str(current_user["_id"])
    new_token = create_token(user_id, verified_email)

    return TokenResponse(
        access_token=new_token,
        user_id=user_id,
        name=verified_name,
        email=verified_email,
        user={
            "id":    user_id,
            "name":  verified_name,
            "email": verified_email,
            "role":  current_user.get("role", "USER").upper(),
        },
    )
