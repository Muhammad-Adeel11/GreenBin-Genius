import os
import httpx
import logging
from typing import Optional, Dict

logger = logging.getLogger("greenbin")

# ── Expert System Configuration ──────────────────────────
# These endpoints handle advanced result refinement
EXPERT_BASE_URL = "https://gemini-proxy-server-production-89c4.up.railway.app"
VERIFIER_URL = f"{EXPERT_BASE_URL}/classify/single-object"
MULTI_REFINE_URL = f"{EXPERT_BASE_URL}/classify/multiple-objects"
FOOD_ANALYZE_URL = f"{EXPERT_BASE_URL}/classify/food"

EXPERT_API_KEY = os.getenv("EXPERT_SYSTEM_KEY", "my_friend_secret_key_123")

async def refine_single_object_result(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the expert verification layer for high-precision single-object analysis.
    """
    if not EXPERT_API_KEY:
        return None

    try:
        headers = { "X-API-Key": EXPERT_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(VERIFIER_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[EXPERT-SYSTEM] Precision Analysis Complete.")
                return {
                    "category": res_data.get("class", "plastic"),
                    "material": res_data.get("material", "plastic"),
                    "confidence": res_data.get("confidence", 90) / 100.0,
                    "recyclable": res_data.get("recyclable", True),
                    "verified_by": "Expert-Ensemble-Model"
                }
            else:
                logger.error(f"[EXPERT-SYSTEM] Analysis Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[EXPERT-SYSTEM] Refinement failed: {e}")
        return None

async def analyze_food_waste_content(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the expert layer for specialized organic/food waste validation.
    """
    if not EXPERT_API_KEY:
        return None

    try:
        headers = { "X-API-Key": EXPERT_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(FOOD_ANALYZE_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[EXPERT-SYSTEM] Organic Analysis Complete.")
                return res_data # returns {"food": "waste", "confidence": 100}
            else:
                logger.error(f"[EXPERT-SYSTEM] Organic Analysis Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[EXPERT-SYSTEM] Organic validation failed: {e}")
        return None

async def refine_multiple_object_detections(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the expert layer for complex multi-object scene refinement.
    """
    if not EXPERT_API_KEY:
        return None

    try:
        headers = { "X-API-Key": EXPERT_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(MULTI_REFINE_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[EXPERT-SYSTEM] Scene Refinement Complete.")
                return res_data # returns {"object_count": X, "objects": [...]}
            else:
                logger.error(f"[EXPERT-SYSTEM] Scene Refinement Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[EXPERT-SYSTEM] Scene refinement failed: {e}")
        return None
