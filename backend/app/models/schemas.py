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


class UserInfo(BaseModel):
    id: str
    name: str
    email: str
    role: str = "USER"

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    name: str
    email: str
    user: UserInfo


# ──────────────────────────────────────────────
# Classification Schemas
# ──────────────────────────────────────────────

class YOLODetection(BaseModel):
    """Detailed YOLO detection including bounding box."""
    label: str = Field(..., example="Bottle")
    confidence: float = Field(..., example=0.88)
    box: List[float] = Field(..., example=[100.0, 150.0, 300.0, 450.0])  # [xmin, ymin, xmax, ymax]


class ClassificationResult(BaseModel):
    """Aggregated schema returned by the combined endpoint."""
    category: str = Field(..., example="plastic")
    object_detected: str = Field(..., example="Bottle")
    material: str = Field(..., example="PET")
    confidence: float = Field(..., ge=0.0, le=1.0, example=0.94)  # Legacy / Overall
    cnn_confidence: float = Field(default=0.0, ge=0.0, le=1.0, example=0.94)
    yolo_confidence: float = Field(default=0.0, ge=0.0, le=1.0, example=0.88)
    detections: List[YOLODetection] = Field(default_factory=list)
    disposal_tip: str = Field(..., example="Rinse and place in the blue recycling bin.")
    disposal_tip_ur: str = Field(..., example="صاف کریں اور نیلے ری سائیکلنگ ڈبے میں رکھیں۔")
    recyclable: bool = Field(..., example=True)
    image_url: Optional[str] = Field(default=None, example="https://res.cloudinary.com/...")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class CNNClassificationResult(BaseModel):
    """Result schema for the specialized CNN endpoint."""
    category: str = Field(..., example="plastic")
    material: str = Field(..., example="PET")
    confidence: float = Field(..., example=0.94)
    disposal_tip: str
    disposal_tip_ur: str
    recyclable: bool
    image_url: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class YOLOClassificationResult(BaseModel):
    """Result schema for the specialized YOLO endpoint."""
    object_detected: str = Field(..., example="Bottle")
    confidence: float = Field(..., example=0.88)
    detections: List[YOLODetection] = Field(default_factory=list)
    image_url: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class ClassificationHistoryEntry(BaseModel):
    """One record in a user's classification history."""
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    category: str
    object_detected: str
    material: str
    confidence: float
    cnn_confidence: Optional[float] = 0.0
    yolo_confidence: Optional[float] = 0.0
    detections: List[YOLODetection] = []
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


class BinCreate(BaseModel):
    """Payload for creating a new bin."""
    name: str = Field(..., example="BIN-105")
    bin_type: str = Field(default="Plastic / Recyclable", example="Plastic / Recyclable")
    latitude: float
    longitude: float
    address: Optional[str] = None
    waste_types: Optional[List[str]] = Field(default=["PLASTIC"])



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
