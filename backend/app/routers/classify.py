"""
GreenBin Genius – Classification Router
POST /api/classify  – core AI endpoint consumed by the Flutter app.
Follows FR-3 (AI Image Classification) from SRS.
"""

from datetime import datetime
from typing import Optional
from fastapi import APIRouter, File, UploadFile, Depends, HTTPException, status
from app.models.schemas import (
    ClassificationResult,
    CNNClassificationResult,
    YOLOClassificationResult
)
from app.services import cnn_classifier, yolo_detector
from app.db.mongo import classifications_col, users_col
from app.routers.auth import get_current_user
from bson import ObjectId
import cloudinary
import cloudinary.uploader

router = APIRouter(prefix="/api", tags=["Classification"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}

# Extensions that map to valid image MIME types (fallback for octet-stream)
_EXT_TO_MIME = {
    "jpg":  "image/jpeg",
    "jpeg": "image/jpeg",
    "png":  "image/png",
    "webp": "image/webp",
}


def _resolve_content_type(file: UploadFile) -> str:
    """Return a resolved MIME type."""
    ct = (file.content_type or "").lower()
    if ct in ALLOWED_TYPES:
        return ct
    if file.filename:
        ext = file.filename.rsplit(".", 1)[-1].lower()
        if ext in _EXT_TO_MIME:
            return _EXT_TO_MIME[ext]
    return ct


async def _handle_cloudinary_upload(image_bytes: bytes) -> Optional[str]:
    """Helper to upload image to Cloudinary if configured."""
    import os
    from typing import Optional
    if os.getenv("CLOUDINARY_URL") or os.getenv("CLOUDINARY_CLOUD_NAME"):
        try:
            upload_res = cloudinary.uploader.upload(image_bytes)
            return upload_res.get("secure_url")
        except Exception as e:
            print(f"[Cloudinary Warning] Upload failed: {e}")
    return None


@router.post(
    "/classify",
    response_model=ClassificationResult,
    summary="Combined AI classification (CNN + YOLO)",
)
async def classify_image(
    file: UploadFile = File(..., description="Waste image (JPEG / PNG)"),
    current_user: dict = Depends(get_current_user),
):
    # ── Validate and Read ─────────────────────────────────────
    resolved_type = _resolve_content_type(file)
    if resolved_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type '{file.content_type}'. Use JPEG or PNG.",
        )

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image too large. Maximum size is 10 MB.",
        )

    # ── Inference ─────────────────────────────────────────────
    timestamp = datetime.utcnow()
    cnn_result = cnn_classifier.predict(image_bytes)
    yolo_result = yolo_detector.detect(image_bytes)
    image_url = await _handle_cloudinary_upload(image_bytes)

    result = ClassificationResult(
        category=cnn_result["category"],
        object_detected=yolo_result["object_detected"],
        material=cnn_result["material"],
        confidence=cnn_result["confidence"],
        cnn_confidence=cnn_result["confidence"],
        yolo_confidence=yolo_result["yolo_confidence"],
        detections=yolo_result["detections"],
        disposal_tip=cnn_result["disposal_tip"],
        disposal_tip_ur=cnn_result["disposal_tip_ur"],
        recyclable=cnn_result["recyclable"],
        image_url=image_url,
        timestamp=timestamp,
    )

    # ── Persistence ───────────────────────────────────────────
    user_id = str(current_user["_id"])
    await classifications_col().insert_one({
        "user_id":        user_id,
        "category":       result.category,
        "object_detected": result.object_detected,
        "material":       result.material,
        "confidence":     result.confidence,
        "cnn_confidence":  result.cnn_confidence,
        "yolo_confidence": result.yolo_confidence,
        "detections":      result.detections,
        "recyclable":     result.recyclable,
        "disposal_tip":   result.disposal_tip,
        "image_url":      image_url,
        "timestamp":      timestamp,
        "filename":       file.filename,
    })

    await users_col().update_one(
        {"_id": ObjectId(user_id)}, {"$inc": {"total_scans": 1}}
    )

    return result


@router.post(
    "/classify/cnn",
    response_model=CNNClassificationResult,
    summary="CNN-only classification",
)
async def classify_cnn(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    image_bytes = await file.read()
    timestamp = datetime.utcnow()
    cnn_result = cnn_classifier.predict(image_bytes)
    image_url = await _handle_cloudinary_upload(image_bytes)

    return CNNClassificationResult(
        category=cnn_result["category"],
        material=cnn_result["material"],
        confidence=cnn_result["confidence"],
        disposal_tip=cnn_result["disposal_tip"],
        disposal_tip_ur=cnn_result["disposal_tip_ur"],
        recyclable=cnn_result["recyclable"],
        image_url=image_url,
        timestamp=timestamp,
    )


@router.post(
    "/classify/yolo",
    response_model=YOLOClassificationResult,
    summary="YOLO-only object detection",
)
async def classify_yolo(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    image_bytes = await file.read()
    timestamp = datetime.utcnow()
    yolo_result = yolo_detector.detect(image_bytes)
    image_url = await _handle_cloudinary_upload(image_bytes)

    return YOLOClassificationResult(
        object_detected=yolo_result["object_detected"],
        confidence=yolo_result["yolo_confidence"],
        detections=yolo_result["detections"],
        image_url=image_url,
        timestamp=timestamp,
    )


@router.get(
    "/classify/test",
    summary="Health-check: verify AI services are loaded",
)
async def classify_test():
    """Returns model load status without requiring an image or auth."""
    from app.services.cnn_classifier import _model_loaded as cnn_ok
    from app.services.yolo_detector  import _yolo_loaded  as yolo_ok
    return {
        "cnn_model_loaded":  cnn_ok,
        "yolo_model_loaded": yolo_ok,
        "status": "ready" if (cnn_ok and yolo_ok) else "mock_mode",
    }
