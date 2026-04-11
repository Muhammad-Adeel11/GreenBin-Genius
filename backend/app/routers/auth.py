"""
GreenBin Genius – Auth Router
Handles user registration, login, and JWT token issuance.
Follows FR-1 (User Registration) and FR-2 (User Login) from SRS.
"""

import os
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
)
from app.db.mongo import users_col

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# ── Config ───────────────────────────────────────────────────
SECRET_KEY = os.getenv("JWT_SECRET", "changeme")
ALGORITHM  = os.getenv("JWT_ALGORITHM", "HS256")
EXPIRE_MIN = int(os.getenv("JWT_EXPIRE_MINUTES", "10080"))

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

    return TokenResponse(
        access_token=token,
        user_id=user_id,
        name=user["name"],
        email=user["email"],
    )


@router.get(
    "/me",
    summary="Get the currently authenticated user's profile",
)
async def get_me(current_user: dict = Depends(get_current_user)):
    return {
        "user_id": str(current_user["_id"]),
        "name":    current_user["name"],
        "email":   current_user["email"],
        "language": current_user.get("language", "en"),
        "total_scans": current_user.get("total_scans", 0),
        "streak": current_user.get("streak", 0),
    }
