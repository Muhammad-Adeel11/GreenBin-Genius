"""
GreenBin Genius – Classification Router
POST /api/classify  – core AI endpoint consumed by the Flutter app.
Follows FR-3 (AI Image Classification) from SRS.
"""

from datetime import datetime
from fastapi import APIRouter, File, UploadFile, Depends, HTTPException, status
from app.models.schemas import ClassificationResult
from app.services import cnn_classifier, yolo_detector
from app.db.mongo import classifications_col, users_col
from app.routers.auth import get_current_user
from bson import ObjectId

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
    """
    Return a resolved MIME type.
    Android camera sometimes sends 'application/octet-stream'; in that case
    we fall back to the filename extension (e.g. 'photo.jpeg' → 'image/jpeg').
    """
    ct = (file.content_type or "").lower()
    if ct in ALLOWED_TYPES:
        return ct
    # Fallback: detect from filename extension
    if file.filename:
        ext = file.filename.rsplit(".", 1)[-1].lower()
        if ext in _EXT_TO_MIME:
            return _EXT_TO_MIME[ext]
    return ct  # return as-is so the error message is accurate


@router.post(
    "/classify",
    response_model=ClassificationResult,
    summary="Upload a waste image and get AI classification",
    description=(
        "Accepts a JPEG/PNG image via multipart upload. "
        "Runs dual-model inference (CNN for category/material, YOLO for object). "
        "Returns structured classification data and bilingual disposal tips."
    ),
)
async def classify_image(
    file: UploadFile = File(..., description="Waste image (JPEG / PNG)"),
    current_user: dict = Depends(get_current_user),
):
    # ── Validate file type (with octet-stream fallback) ───────
    resolved_type = _resolve_content_type(file)
    if resolved_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type '{file.content_type}'. Use JPEG or PNG.",
        )


    image_bytes = await file.read()

    if len(image_bytes) > 10 * 1024 * 1024:   # 10 MB guard
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image too large. Maximum size is 10 MB.",
        )

    # ── Run inference ─────────────────────────────────────────
    cnn_result  = cnn_classifier.predict(image_bytes)
    yolo_result = yolo_detector.detect(image_bytes)

    timestamp = datetime.utcnow()

    result = ClassificationResult(
        category=cnn_result["category"],
        object_detected=yolo_result["object_detected"],
        material=cnn_result["material"],
        confidence=cnn_result["confidence"],
        disposal_tip=cnn_result["disposal_tip"],
        disposal_tip_ur=cnn_result["disposal_tip_ur"],
        recyclable=cnn_result["recyclable"],
        timestamp=timestamp,
    )

    # ── Persist classification to MongoDB (non-blocking) ──────
    user_id = str(current_user["_id"])
    await classifications_col().insert_one({
        "user_id":        user_id,
        "category":       result.category,
        "object_detected": result.object_detected,
        "material":       result.material,
        "confidence":     result.confidence,
        "recyclable":     result.recyclable,
        "disposal_tip":   result.disposal_tip,
        "timestamp":      timestamp,
        "filename":       file.filename,
        "mock_cnn":       cnn_result.get("mock", False),
        "mock_yolo":      yolo_result.get("mock", False),
    })

    # ── Increment user total_scans counter ───────────────────
    await users_col().update_one(
        {"_id": ObjectId(user_id)},
        {"$inc": {"total_scans": 1}},
    )

    return result


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
