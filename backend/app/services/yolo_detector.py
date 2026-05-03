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
        
        # ── Compatibility Fix for DFLoss ──────────────────────────
        # Inject DFLoss into ultralytics.utils.loss if it's missing
        # This resolves unpickling errors on some versions
        import ultralytics.utils.loss as loss_module
        if not hasattr(loss_module, 'DFLoss'):
            import torch.nn as nn
            class DFLoss(nn.Module):
                def __init__(self, reg_max=16):
                    super().__init__()
                    self.reg_max = reg_max
                def forward(self, pred_dist, target):
                    return None # Stub for unpickling
            setattr(loss_module, 'DFLoss', DFLoss)
        # ──────────────────────────────────────────────────────────

        _yolo_model = YOLO(model_path)
        _yolo_loaded = True
        logger.info(f"[OK] YOLO model loaded from '{model_path}'.")
    except Exception as exc:
        logger.error(f"[ERROR] Failed to load YOLO model: {exc}")
        _yolo_loaded = False


def detect(image_bytes: bytes, return_annotated: bool = True) -> dict:
    """
    Run YOLO object detection on raw image bytes.
    Returns detections and optionally the annotated image bytes.
    """
    if not _yolo_loaded or _yolo_model is None:
        # Return some realistic mock detections so the UI looks good even without the .pt model
        return {
            "object_detected": "Plastic Bottle",
            "yolo_confidence": 0.92,
            "detections": [
                {
                    "label": "Plastic Bottle",
                    "confidence": 0.92,
                    "box": [150.0, 100.0, 450.0, 500.0] # Mock box
                }
            ],
            "annotated_image": None,
            "mock": True,
        }

    try:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        results = _yolo_model(img, verbose=False)

        detections = []
        top_label = "Unknown"
        top_conf = 0.0
        annotated_bytes = None

        for result in results:
            # 1. Generate annotated image
            if return_annotated:
                # result.plot() returns a BGR numpy array
                import cv2
                import numpy as np
                plot_img = result.plot(labels=False, conf=False)
                is_success, buffer = cv2.imencode(".jpg", plot_img)
                if is_success:
                    annotated_bytes = buffer.tobytes()

            if result.boxes is not None:
                for box in result.boxes:
                    cls_id = int(box.cls[0].item())
                    conf = float(box.conf[0].item())
                    label = result.names.get(cls_id, "Unknown")
                    xyxy = box.xyxy[0].tolist()
                    
                    from app.services.cnn_classifier import MATERIAL_MAP
                    
                    def guess_material(label):
                        l = label.lower()
                        for key, mat in MATERIAL_MAP.items():
                            if key in l: return mat
                        if "bottle" in l or "plastic" in l: return "Plastic"
                        if "can" in l or "metal" in l: return "Metal"
                        if "paper" in l: return "Paper"
                        if "glass" in l: return "Glass"
                        if "cardboard" in l: return "Cardboard"
                        return "Mixed"

                    det = {
                        "label": label.capitalize(),
                        "class": label.lower(),
                        "material": guess_material(label),
                        "confidence": round(conf, 4),
                        "box": xyxy
                    }
                    detections.append(det)
                    
                    if conf > top_conf:
                        top_conf = conf
                        top_label = label

        return {
            "object_detected": top_label.capitalize(),
            "yolo_confidence": round(top_conf, 4),
            "detections": detections,
            "annotated_image": annotated_bytes,
            "mock": False,
        }
    except Exception as exc:
        logger.error(f"YOLO inference error: {exc}")
        return {
            "object_detected": "Unknown",
            "yolo_confidence": 0.0,
            "detections": [],
            "annotated_image": None,
            "mock": True,
        }
