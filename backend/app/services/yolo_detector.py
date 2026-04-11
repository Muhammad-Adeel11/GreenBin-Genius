"""
GreenBin Genius – YOLO Detector Service
Loads the YOLOv8 .pt model at startup and detects
the dominant object in the uploaded image.
"""

import os
import io
import logging
from PIL import Image

logger = logging.getLogger(__name__)

# ── Singleton state ──────────────────────────────────────────
_yolo_model = None
_yolo_loaded = False


def load_model_on_startup():
    """
    Called once at FastAPI startup.
    Gracefully skips if model file is absent (placeholder mode).
    """
    global _yolo_model, _yolo_loaded
    model_path = os.getenv("YOLO_MODEL_PATH", "ml/yolo_model.pt")

    if not os.path.exists(model_path):
        logger.warning(
            f"[WARN] YOLO model NOT found at '{model_path}'. "
            "Object detection disabled - upload yolo_model.pt to activate."
        )
        _yolo_loaded = False
        return

    try:
        from ultralytics import YOLO  # type: ignore
        _yolo_model = YOLO(model_path)
        _yolo_loaded = True
        logger.info(f"[OK] YOLO model loaded from '{model_path}'.")
    except Exception as exc:
        logger.error(f"[ERROR] Failed to load YOLO model: {exc}")
        _yolo_loaded = False


def detect(image_bytes: bytes) -> dict:
    """
    Run YOLO object detection on raw image bytes.
    Returns the top detected object label and its confidence.

    Falls back to a mock if model is not loaded.
    """
    if not _yolo_loaded or _yolo_model is None:
        return {
            "object_detected": "Bottle",
            "yolo_confidence": 0.88,
            "mock": True,
        }

    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        results = _yolo_model(img, verbose=False)

        # Extract the highest-confidence detection
        top_label = "Unknown"
        top_conf = 0.0

        for result in results:
            if result.boxes is not None and len(result.boxes) > 0:
                best_idx = result.boxes.conf.argmax().item()
                cls_id = int(result.boxes.cls[best_idx].item())
                top_conf = float(result.boxes.conf[best_idx].item())
                top_label = result.names.get(cls_id, "Unknown")
                break

        return {
            "object_detected": top_label.capitalize(),
            "yolo_confidence": round(top_conf, 4),
            "mock": False,
        }
    except Exception as exc:
        logger.error(f"YOLO inference error: {exc}")
        return {
            "object_detected": "Unknown",
            "yolo_confidence": 0.0,
            "mock": True,
        }
