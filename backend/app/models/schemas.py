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
    """Detailed YOLO detection including bounding box and material info."""
    label: str = Field(..., example="Bottle")
    class_name: str = Field(default="unknown", alias="class")
    material: str = Field(default="unknown")
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
    object_count: int = Field(default=0)
    detections: List[YOLODetection] = Field(default_factory=list)
    disposal_tip: str = Field(..., example="Rinse and place in the blue recycling bin.")
    disposal_tip_ur: str = Field(..., example="صاف کریں اور نیلے ری سائیکلنگ ڈبے میں رکھیں۔")
    recyclable: bool = Field(..., example=True)
    image_url: Optional[str] = Field(default=None, example="https://res.cloudinary.com/...")
    annotated_image_url: Optional[str] = Field(default=None, example="https://res.cloudinary.com/...")
    summary: Optional[str] = Field(default=None, example="3 Metal Cans, 1 Plastic Bottle")
    item_counts: Optional[dict] = Field(default_factory=dict, example={"Metal Cans": 3, "Plastic Bottle": 1})
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
    annotated_image_url: Optional[str] = None
    mode: Optional[str] = "single"
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


# ──────────────────────────────────────────────
# Eco-Tips Schemas
# ──────────────────────────────────────────────

class EcoTipCreate(BaseModel):
    waste_category: str = Field(..., example="PLASTIC")
    tip_english:    str = Field(..., example="Rinse and place in the blue recycling bin.")
    tip_urdu:       str = Field(..., example="صاف کریں اور نیلے ڈبے میں ڈالیں۔")
    bin_color:      Optional[str] = Field(default="Black", example="Blue")
    icon:           Optional[str] = Field(default="♻️", example="🧴")
    steps:          Optional[List[str]] = Field(default_factory=list)
    steps_ur:       Optional[List[str]] = Field(default_factory=list)
    do_list:        Optional[List[str]] = Field(default_factory=list)
    dont_list:      Optional[List[str]] = Field(default_factory=list)
    is_active:      Optional[bool] = Field(default=True)


class EcoTipUpdate(BaseModel):
    waste_category: Optional[str] = None
    tip_english:    Optional[str] = None
    tip_urdu:       Optional[str] = None
    bin_color:      Optional[str] = None
    icon:           Optional[str] = None
    steps:          Optional[List[str]] = None
    steps_ur:       Optional[List[str]] = None
    do_list:        Optional[List[str]] = None
    dont_list:      Optional[List[str]] = None
    is_active:      Optional[bool] = None


class EcoTipResponse(BaseModel):
    id:             str
    waste_category: str
    tip_english:    str
    tip_urdu:       str
    bin_color:      Optional[str] = "Black"
    icon:           Optional[str] = "♻️"
    steps:          List[str] = []
    steps_ur:       List[str] = []
    do_list:        List[str] = []
    dont_list:      List[str] = []
    is_active:      bool = True
    created_at:     Optional[datetime] = None
    updated_at:     Optional[datetime] = None


class EcoTipListResponse(BaseModel):
    total: int
    data:  List[EcoTipResponse]


class EcoTipFeedbackRequest(BaseModel):
    classification_id:  str = Field(..., example="665a1b2c3d4e5f6789012345")
    corrected_category: str = Field(..., example="metal")


class EcoTipFeedbackResponse(BaseModel):
    success:            bool
    message:            str
    points_awarded:     int
    total_points:       int
    corrected_category: str
    updated_guidance:   Optional[dict] = None


# ──────────────────────────────────────────────
# FAQs & Resources Schemas
# ──────────────────────────────────────────────

class FAQCreate(BaseModel):
    question_en: str = Field(..., example="What is GreenBin Genius?")
    question_ur: str = Field(..., example="گرین بن جینیئس کیا ہے؟")
    answer_en: str = Field(..., example="An AI waste classification assistant.")
    answer_ur: str = Field(..., example="ایک اے آئی کوڑا کرکٹ کی درجہ بندی کا معاون۔")
    category: str = Field(default="general", example="general")
    is_active: Optional[bool] = Field(default=True)


class FAQUpdate(BaseModel):
    question_en: Optional[str] = None
    question_ur: Optional[str] = None
    answer_en: Optional[str] = None
    answer_ur: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None


class FAQResponse(BaseModel):
    id: str
    question_en: str
    question_ur: str
    answer_en: str
    answer_ur: str
    category: str
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class FAQListResponse(BaseModel):
    total: int
    data: List[FAQResponse]


class ResourceCreate(BaseModel):
    title: str = Field(..., example="EPA Recycling Guide")
    url: str = Field(..., example="https://www.epa.gov/recycle")
    category: str = Field(..., example="Education")
    icon: Optional[str] = Field(default="🔗", example="📖")
    description: Optional[str] = Field(default=None, example="General tips for recycling.")
    is_active: Optional[bool] = Field(default=True)


class ResourceUpdate(BaseModel):
    title: Optional[str] = None
    url: Optional[str] = None
    category: Optional[str] = None
    icon: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class ResourceResponse(BaseModel):
    id: str
    title: str
    url: str
    category: str
    icon: str
    description: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ResourceListResponse(BaseModel):
    total: int
    data: List[ResourceResponse]
