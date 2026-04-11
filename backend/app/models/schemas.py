"""
GreenBin Genius – Pydantic Schemas
All request/response data models used across routes.
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


# ──────────────────────────────────────────────
# Auth Schemas
# ──────────────────────────────────────────────

class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=80, example="Rehman Ghani")
    email: EmailStr = Field(..., example="rehman@example.com")
    password: str = Field(..., min_length=6, example="securepassword")
    language: Optional[str] = Field(default="en", example="en")  # "en" | "ur"


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    email: str


# ──────────────────────────────────────────────
# Classification Schemas
# ──────────────────────────────────────────────

class ClassificationResult(BaseModel):
    """Schema returned to the Flutter app after AI inference."""
    category: str = Field(..., example="plastic")
    object_detected: str = Field(..., example="Bottle")
    material: str = Field(..., example="PET")
    confidence: float = Field(..., ge=0.0, le=1.0, example=0.94)
    disposal_tip: str = Field(..., example="Rinse and place in the blue recycling bin.")
    disposal_tip_ur: str = Field(..., example="صاف کریں اور نیلے ری سائیکلنگ ڈبے میں رکھیں۔")
    recyclable: bool = Field(..., example=True)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ClassificationHistoryEntry(BaseModel):
    """One record in a user's classification history."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    category: str
    object_detected: str
    material: str
    confidence: float
    recyclable: bool
    disposal_tip: str
    image_url: Optional[str] = None
    timestamp: datetime


class ClassificationHistoryResponse(BaseModel):
    total: int
    entries: List[ClassificationHistoryEntry]


# ──────────────────────────────────────────────
# Bin Locator Schemas
# ──────────────────────────────────────────────

class BinLocation(BaseModel):
    """A single recycling / waste bin location."""
    id: str
    name: str
    bin_type: str = Field(..., example="Plastic / Recyclable")
    latitude: float
    longitude: float
    distance_m: Optional[float] = None   # Filled by backend geo query
    address: Optional[str] = None


class NearbyBinsResponse(BaseModel):
    total: int
    bins: List[BinLocation]


# ──────────────────────────────────────────────
# Analytics Schemas
# ──────────────────────────────────────────────

class UserAnalytics(BaseModel):
    user_id: str
    total_scans: int
    recyclable_count: int
    non_recyclable_count: int
    top_category: Optional[str] = None
    scans_this_week: int
    scans_this_month: int
    streak_days: int


class GlobalAnalytics(BaseModel):
    total_global_scans: int
    total_recyclable: int
    monthly_scans: int
    top_category_global: Optional[str] = None


# ──────────────────────────────────────────────
# Generic Responses
# ──────────────────────────────────────────────

class SuccessResponse(BaseModel):
    success: bool = True
    message: str


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    detail: Optional[str] = None
