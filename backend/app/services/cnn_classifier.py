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

# ── Class labels (must match training order: e-waste, glass, metal, plastic, textile, wood)
CLASS_LABELS = [
    "e-waste",   # 0
    "glass",     # 1
    "metal",     # 2
    "plastic",   # 3
    "textile",   # 4
    "wood",      # 5
]

# ── Disposal guidance per category ──────────────────────────
DISPOSAL_TIPS = {
    "e-waste":        ("Take to an authorised e-waste collection centre.",
                       "مجاز ای-ویسٹ مرکز پر لے جائیں۔"),
    "glass":          ("Rinse and place in the glass recycling bin.",
                       "صاف کریں اور شیشہ ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "metal":          ("Rinse and place in the metal recycling bin.",
                       "صاف کریں اور دھات ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "plastic":        ("Rinse and place in the plastic recycling (blue) bin.",
                       "صاف کریں اور نیلے پلاسٹک ری سائیکلنگ ڈبے میں ڈالیں۔"),
    "textile":        ("Donate if usable; otherwise place in textile bins.",
                       "اگر قابل استعمال ہو تو عطیہ کریں، ورنہ ٹیکسٹائل ڈبے میں ڈالیں۔"),
    "wood":           ("Repurpose if possible or take to a timber recycling facility.",
                       "اگر ہو سکے تو دوبارہ استعمال کریں یا لکڑی ری سائیکلنگ مرکز پر لے جائیں۔"),
    "food_waste":     ("Compost or dispose in the organic (green) bin.",
                       "کمپوسٹ کریں یا نامیاتی (سبز) ڈبے میں ڈالیں۔"),
    "not_food_waste": ("Dispose in the general waste bin.",
                       "عام کوڑے کے ڈبے میں ڈالیں۔"),
    "Scanning...":    ("Refining results with expert system...",
                        "ایکسپرٹ سسٹم سے نتائج کی تصدیق کی جا رہی ہے..."),
                       "تصدیق کا انتظار کریں..."),
}

# ── Categories considered recyclable ────────────────────────
RECYCLABLE_CATEGORIES = {
    "glass", "metal", "plastic", "e-waste", "textile"
}

# ── Material mapping ─────────────────────────────────────────
MATERIAL_MAP = {
    "e-waste":        "Electronics",
    "glass":          "Glass",
    "metal":          "Metal",
    "plastic":        "Plastic",
    "textile":        "Textile",
    "wood":           "Wood",
    "food_waste":     "Organic",
    "not_food_waste": "Mixed",
    "Scanning...":    "Scanning...",
}

# ── Singleton model state ────────────────────────────────────
_model = None
_food_waste_model = None
_model_loaded = False
_fw_loaded = False


def load_model_on_startup():
    """Load both the primary .h5 model and the secondary TFSMLayer model."""
    global _model, _model_loaded, _food_waste_model, _fw_loaded
    
    primary_path = os.getenv("CNN_MODEL_PATH", "ml/trashbox_cnn_model.h5")
    fw_h5_path = os.getenv("FOOD_WASTE_MODEL_H5", "ml/food_waste_model.h5")
    fw_path = os.getenv("FOOD_WASTE_MODEL_PATH", "ml/food_waste_savedmodel")

    # Load Primary .h5 Model
    if os.path.exists(primary_path):
        try:
            from tensorflow.keras.models import load_model  # type: ignore
            _model = load_model(primary_path, compile=False)
            _model_loaded = True
            logger.info(f"[OK] CNN model loaded from '{primary_path}'.")
        except Exception as exc:
            logger.error(f"[ERROR] Failed to load primary CNN: {exc}")
    
    # Load Secondary Food Waste (.h5) Model
    if os.path.exists(fw_h5_path):
        try:
            from tensorflow.keras.models import load_model # type: ignore
            _food_waste_model = load_model(fw_h5_path, compile=False)
            _fw_loaded = True
            logger.info(f"[OK] Food waste model loaded from '{fw_h5_path}'.")
        except Exception as exc:
            logger.error(f"[ERROR] Failed to load food waste .h5 model: {exc}")
    elif os.path.exists(fw_path):
        # Fallback to SavedModel if directory exists
        try:
            from tensorflow.keras.layers import Input, TFSMLayer # type: ignore
            from tensorflow.keras import Model # type: ignore
            input_tensor = Input(shape=(224, 224, 3))
            layer = TFSMLayer(fw_path, call_endpoint="serving_default")
            output = layer(input_tensor)
            _food_waste_model = Model(inputs=input_tensor, outputs=output)
            _fw_loaded = True
            logger.info(f"[OK] Food waste SavedModel loaded from '{fw_path}'.")
        except Exception:
            pass


def _preprocess(image_bytes: bytes) -> np.ndarray:
    """Resize image to 224×224 and normalise pixel values to [0, 1]."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)


def predict(image_bytes: bytes, mode: str = "single") -> dict:
    """Run CNN inference with potential two-step check for organic waste."""
    if not _model_loaded or _model is None:
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

    array = _preprocess(image_bytes)
    
    # ── FOOD Mode Branch ──────────────────────────────────────
    if mode == "food":
        if _fw_loaded and _food_waste_model:
            try:
                # 1. Preprocess: The food model has built-in Rescaling(1./255).
                # So we pass the raw pixel array [0-255].
                img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
                img = img.resize((224, 224))
                raw_array = np.expand_dims(np.array(img, dtype=np.float32), axis=0)

                res = _food_waste_model.predict(raw_array, verbose=0)
                
                # 2. Logic: Sigmoid outputs prob of class 1.
                # Alphabetical: 0: food_waste, 1: not_food_waste
                if isinstance(res, dict):
                    # SavedModel logic
                    prob = list(res.values())[0][0][0]
                    label = "not_food_waste" if prob > 0.5 else "food_waste"
                    confidence = float(prob if prob > 0.5 else 1 - prob)
                elif res.shape[-1] > 1:
                    # Softmax [prob_food, prob_not_food]
                    idx = int(np.argmax(res[0]))
                    label = "food_waste" if idx == 0 else "not_food_waste"
                    confidence = float(res[0][idx])
                else:
                    # Sigmoid [prob_not_food]
                    prob = float(res[0][0])
                    label = "not_food_waste" if prob > 0.5 else "food_waste"
                    confidence = float(prob if prob > 0.5 else 1 - prob)

                return {
                    "category":     label,
                    "material":     MATERIAL_MAP.get(label, "Organic"),
                    "confidence":   round(confidence, 4),
                    "recyclable":   False,
                    "disposal_tip":    DISPOSAL_TIPS.get(label, DISPOSAL_TIPS["organic"])[0],
                    "disposal_tip_ur": DISPOSAL_TIPS.get(label, DISPOSAL_TIPS["organic"])[1],
                    "mock":         False,
                }
            except Exception as e:
                logger.error(f"Direct Food model inference failed: {e}")
        
        # If local model is missing or failed, return a temporary state for Expert System to fill
        return {
            "category":     "Scanning...",
            "material":     "Scanning...",
            "confidence":   0.0,
            "recyclable":   False,
            "disposal_tip":    "Refining results with expert system...",
            "disposal_tip_ur": "تصدیق کا انتظار کریں...",
            "mock":         True,
        }

    # ── Standard Single/Multiple Mode ────────────────────────
    preds = _model.predict(array, verbose=0)
    idx = int(np.argmax(preds[0]))
    confidence = float(preds[0][idx])
    label = CLASS_LABELS[idx]

    return {
        "category":     label,
        "material":     MATERIAL_MAP[label],
        "confidence":   round(confidence, 4),
        "recyclable":   label in RECYCLABLE_CATEGORIES,
        "disposal_tip":    DISPOSAL_TIPS[label][0],
        "disposal_tip_ur": DISPOSAL_TIPS[label][1],
        "mock":         False,
    }

def get_disposal_tip(category: str):
    """Helper to get tip and Urdu translation for a category."""
    tip = DISPOSAL_TIPS.get(category, ("Dispose in general waste.", "عام کوڑے میں ڈالیں۔"))
    return tip[0], tip[1]

def get_material(category: str):
    """Helper to get material name for a category."""
    return MATERIAL_MAP.get(category, "Mixed")
