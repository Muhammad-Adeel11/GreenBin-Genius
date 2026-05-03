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
import logging
logger = logging.getLogger("greenbin")

from app.services import cnn_classifier, yolo_detector
from app.db.mongo import classifications_col, users_col
from app.routers.auth import get_current_user
from bson import ObjectId
import cloudinary
import cloudinary.uploader
from app.services.gemini_verifier import verify_classification_with_gemini

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
    mode: str = "single",  # "single" or "multiple"
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

    # ── Inference Branching ───────────────────────────────────
    timestamp = datetime.utcnow()
    
    cnn_result = None
    yolo_result = None

    if mode == "single":
        # REQUIREMENT: Only CNN model is used for Single
        cnn_result = cnn_classifier.predict(image_bytes, mode=mode)
        # We run YOLO just for the "Object Detected" string, but we won't show the boxes
        yolo_result = yolo_detector.detect(image_bytes)
        yolo_result["annotated_image"] = None # Force original image display
        yolo_result["detections"] = [] # Clear detections for Single mode UI
        
    elif mode == "food":
        # REQUIREMENT: Only food_waste model is used for Food
        cnn_result = cnn_classifier.predict(image_bytes, mode=mode)
        yolo_result = {"object_detected": "Food Item", "yolo_confidence": 0.0, "detections": [], "annotated_image": None}

        # EXPERT VERIFICATION: Use Gemini for Food
        try:
            from app.services.gemini_verifier import classify_food_with_gemini
            gemini_food = await classify_food_with_gemini(image_bytes)
            if gemini_food and "food" in gemini_food:
                # Prioritize Gemini for "Correct Result"
                g_food = str(gemini_food["food"]).lower()
                # Map Gemini labels to our internal labels
                label = "food_waste" if "waste" in g_food else "not_food_waste"
                cnn_result["category"] = label
                cnn_result["confidence"] = gemini_food.get("confidence", 100) / 100.0
        except Exception as e:
            logger.warning(f"[GEMINI-FOOD] Fallback to local model: {e}")
        
    else:
        # REQUIREMENT: Only YOLO model is used for Multiple
        yolo_result = yolo_detector.detect(image_bytes)
        # Use CNN just to get a general category/material for the summary
        cnn_result = cnn_classifier.predict(image_bytes, mode=mode)

        # EXPERT VERIFICATION: Use Gemini for Multiple Objects
        try:
            from app.services.gemini_verifier import verify_multiple_objects_with_gemini
            gemini_multi = await verify_multiple_objects_with_gemini(image_bytes)
            if gemini_multi and "objects" in gemini_multi:
                # Prioritize Gemini's labels and count for "Correct Result"
                g_objects = gemini_multi["objects"]
                y_detections = yolo_result.get("detections", [])
                
                # Update detections with Gemini info if they align, or replace
                new_detections = []
                # Simple mapping: Use Gemini labels for YOLO boxes if possible
                for i, g_obj in enumerate(g_objects):
                    box = [0, 0, 0, 0]
                    if i < len(y_detections):
                        box = y_detections[i]["box"] # Re-use local box for UI
                    
                    new_detections.append({
                        "label": g_obj["class"].capitalize(),
                        "class": g_obj["class"],
                        "material": g_obj["material"].capitalize(),
                        "confidence": g_obj["confidence"] / 100.0, # convert 95 to 0.95
                        "box": box
                    })
                yolo_result["detections"] = new_detections
                yolo_result["object_detected"] = f"{len(new_detections)} items"
                yolo_result["yolo_confidence"] = sum(d["confidence"] for d in new_detections) / len(new_detections) if new_detections else 0.0
        except Exception as e:
            logger.warning(f"[GEMINI-MULTI] Fallback to local YOLO due to error: {e}")

    # ── Expert Verification (Gemini) ──────────────────────
    if mode == "single":
        logger.info(f"[VERIFY] Calling Gemini Expert for Single Mode...")
        try:
            from app.services.gemini_verifier import classify_single_with_gemini
            gemini_res = await classify_single_with_gemini(image_bytes)
            if gemini_res:
                cnn_result.update(gemini_res)
                # Ensure tips are updated for the new category
                from app.services.cnn_classifier import get_disposal_tip
                tip_en, tip_ur = get_disposal_tip(gemini_res["category"])
                cnn_result["disposal_tip"] = tip_en
                cnn_result["disposal_tip_ur"] = tip_ur
                logger.info(f"[VERIFY] Gemini Result: {cnn_result['category']}")
        except Exception as e:
            logger.error(f"[VERIFY] Gemini Expert failed: {e}")
    
    # ── Cloudinary Uploads ────────────────────────────────────
    image_url = await _handle_cloudinary_upload(image_bytes)
    annotated_image_url = None
    if yolo_result.get("annotated_image"):
        annotated_image_url = await _handle_cloudinary_upload(yolo_result["annotated_image"])
    else:
        annotated_image_url = image_url

    # ── Generate Summary ──────────────────────────────────────
    detections = yolo_result.get("detections", [])
    item_counts = {}
    for d in detections:
        label = d["label"]
        item_counts[label] = item_counts.get(label, 0) + 1
    
    if item_counts:
        summary_parts = [f"{count} {label}{'s' if count > 1 else ''}" for label, count in item_counts.items()]
        summary = ", ".join(summary_parts)
    else:
        summary = yolo_result["object_detected"]

    result = ClassificationResult(
        category=cnn_result["category"],
        object_detected=yolo_result["object_detected"],
        material=cnn_result["material"],
        confidence=cnn_result["confidence"],
        cnn_confidence=cnn_result["confidence"],
        yolo_confidence=yolo_result["yolo_confidence"],
        object_count=len(detections),
        detections=yolo_result["detections"],
        summary=summary,
        item_counts=item_counts,
        disposal_tip=cnn_result["disposal_tip"],
        disposal_tip_ur=cnn_result["disposal_tip_ur"],
        recyclable=cnn_result["recyclable"],
        image_url=image_url,
        annotated_image_url=annotated_image_url,
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
        "detections":      [d.model_dump() for d in result.detections],
        "summary":         summary,
        "item_counts":     item_counts,
        "recyclable":     result.recyclable,
        "disposal_tip":   result.disposal_tip,
        "image_url":      image_url,
        "annotated_image_url": annotated_image_url,
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
    
    # ── Cloudinary Uploads ────────────────────────────────────
    image_url = await _handle_cloudinary_upload(image_bytes)
    annotated_image_url = None
    if yolo_result.get("annotated_image"):
        annotated_image_url = await _handle_cloudinary_upload(yolo_result["annotated_image"])
    else:
        annotated_image_url = image_url

    return YOLOClassificationResult(
        object_detected=yolo_result["object_detected"],
        confidence=yolo_result["yolo_confidence"],
        detections=yolo_result["detections"],
        image_url=image_url,
        annotated_image_url=annotated_image_url,
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
