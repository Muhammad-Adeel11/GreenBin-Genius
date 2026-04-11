"""
GreenBin Genius – CNN Classifier Service
Loads the Keras .h5 model at startup and runs inference
against the 13 waste categories.
"""

import os
import io
import logging
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

# ── Class labels (must match training order) ───────────────
CLASS_LABELS = [
    "Trash",          # 0
    "Vegetation",     # 1
    "cardboard",      # 2
    "clothes",        # 3
    "e-waste",        # 4
    "food_waste",     # 5
    "glass",          # 6
    "medical",        # 7
    "metal",          # 8
    "not_food_waste", # 9
    "paper",          # 10
    "plastic",        # 11
    "shoes",          # 12
]

# ── Disposal guidance per category ──────────────────────────
DISPOSAL_TIPS = {
    "Trash":          ("Dispose in the general waste (black) bin.",
                       "عام کوڑے کے ڈبے (کالے) میں ڈالیں۔"),
    "Vegetation":     ("Compost or place in the organic (green) bin.",
                       "کمپوسٹ کریں یا نامیاتی (سبز) ڈبے میں ڈالیں۔"),
    "cardboard":      ("Flatten, keep dry, and place in the recycling bin.",
                       "چپٹا کریں، خشک رکھیں اور ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "clothes":        ("Donate if usable; otherwise place in textile bins.",
                       "اگر قابل استعمال ہو تو عطیہ کریں، ورنہ ٹیکسٹائل ڈبے میں ڈالیں۔"),
    "e-waste":        ("Take to an authorised e-waste collection centre.",
                       "مجاز ای-ویسٹ مرکز پر لے جائیں۔"),
    "food_waste":     ("Compost or dispose in the organic (green) bin.",
                       "کمپوسٹ کریں یا نامیاتی (سبز) ڈبے میں ڈالیں۔"),
    "glass":          ("Rinse and place in the glass recycling bin.",
                       "صاف کریں اور شیشہ ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "medical":        ("Dispose at a pharmacy or medical waste facility.",
                       "فارمیسی یا طبی فضلہ مرکز پر ڈالیں۔"),
    "metal":          ("Rinse and place in the metal recycling bin.",
                       "صاف کریں اور دھات ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "not_food_waste": ("Dispose in the general waste bin.",
                       "عام کوڑے کے ڈبے میں ڈالیں۔"),
    "paper":          ("Keep dry and place in the paper recycling bin.",
                       "خشک رکھیں اور کاغذ ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "plastic":        ("Rinse and place in the plastic recycling (blue) bin.",
                       "صاف کریں اور نیلے پلاسٹک ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "shoes":          ("Donate if usable; otherwise place in textile bins.",
                       "اگر قابل استعمال ہو تو عطیہ کریں، ورنہ ٹیکسٹائل ڈبے میں ڈالیں۔"),
}

# ── Categories considered recyclable ────────────────────────
RECYCLABLE_CATEGORIES = {
    "cardboard", "glass", "metal", "paper", "plastic"
}

# ── Material mapping ─────────────────────────────────────────
MATERIAL_MAP = {
    "Trash":          "Mixed",
    "Vegetation":     "Organic",
    "cardboard":      "Cardboard",
    "clothes":        "Textile",
    "e-waste":        "Electronics",
    "food_waste":     "Organic",
    "glass":          "Glass",
    "medical":        "Biohazard",
    "metal":          "Metal",
    "not_food_waste": "Mixed",
    "paper":          "Paper",
    "plastic":        "PET/HDPE",
    "shoes":          "Textile",
}

# ── Singleton model state ────────────────────────────────────
_model = None
_model_loaded = False


def load_model_on_startup():
    """
    Called once at FastAPI startup.
    Gracefully handles the case where the model file is not yet present
    (placeholder mode) so the API starts successfully regardless.
    """
    global _model, _model_loaded
    model_path = os.getenv("CNN_MODEL_PATH", "ml/cnn_model.h5")

    if not os.path.exists(model_path):
        logger.warning(
            f"[WARN] CNN model NOT found at '{model_path}'. "
            "Running in MOCK mode - upload cnn_model.h5 to activate real inference."
        )
        _model_loaded = False
        return

    try:
        from tensorflow.keras.models import load_model  # type: ignore
        _model = load_model(model_path)
        _model_loaded = True
        logger.info(f"[OK] CNN model loaded from '{model_path}'.")
    except Exception as exc:
        logger.error(f"[ERROR] Failed to load CNN model: {exc}")
        _model_loaded = False


def _preprocess(image_bytes: bytes) -> np.ndarray:
    """Resize image to 224×224 and normalise pixel values to [0, 1]."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)  # shape: (1, 224, 224, 3)


def predict(image_bytes: bytes) -> dict:
    """
    Run CNN inference on raw image bytes.
    Returns a dict with category, material, confidence, disposal tips,
    and recyclable flag.

    Falls back to a deterministic mock if the model is not loaded.
    """
    if not _model_loaded or _model is None:
        # ── MOCK response while model file is absent ────────────
        label = "plastic"
        return {
            "category":     label,
            "material":     MATERIAL_MAP[label],
            "confidence":   0.91,
            "recyclable":   label in RECYCLABLE_CATEGORIES,
            "disposal_tip":    DISPOSAL_TIPS[label][0],
            "disposal_tip_ur": DISPOSAL_TIPS[label][1],
            "mock":         True,
        }

    # ── Real inference ──────────────────────────────────────────
    array = _preprocess(image_bytes)
    predictions = _model.predict(array, verbose=0)   # shape: (1, 13)
    class_idx = int(np.argmax(predictions[0]))
    confidence = float(predictions[0][class_idx])
    label = CLASS_LABELS[class_idx]

    return {
        "category":     label,
        "material":     MATERIAL_MAP[label],
        "confidence":   round(confidence, 4),
        "recyclable":   label in RECYCLABLE_CATEGORIES,
        "disposal_tip":    DISPOSAL_TIPS[label][0],
        "disposal_tip_ur": DISPOSAL_TIPS[label][1],
        "mock":         False,
    }
