import os
import httpx
import logging
from typing import Optional, Dict

logger = logging.getLogger("greenbin")

GEMINI_PROXY_URL = "https://gemini-proxy-server-production-89c4.up.railway.app/classify-image"
GEMINI_SINGLE_URL = "https://gemini-proxy-server-production-89c4.up.railway.app/classify/single-object"
GEMINI_MULTI_URL = "https://gemini-proxy-server-production-89c4.up.railway.app/classify/multiple-objects"
GEMINI_FOOD_URL = "https://gemini-proxy-server-production-89c4.up.railway.app/classify/food"
GEMINI_API_KEY = os.getenv("GEMINI_PROXY_API_KEY", "my_friend_secret_key_123")

async def classify_single_with_gemini(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the Gemini proxy for structured single-object classification.
    """
    if not GEMINI_API_KEY:
        return None

    try:
        headers = { "X-API-Key": GEMINI_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(GEMINI_SINGLE_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[GEMINI-SINGLE] Proxy Response: {res_data}")
                # Returns {"confidence": 90, "class": "...", "material": "...", "recyclable": true}
                return {
                    "category": res_data.get("class", "plastic"),
                    "material": res_data.get("material", "plastic"),
                    "confidence": res_data.get("confidence", 90) / 100.0,
                    "recyclable": res_data.get("recyclable", True),
                    "verified_by": "Gemini-Pro-Vision"
                }
            else:
                logger.error(f"[GEMINI-SINGLE] Proxy Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[GEMINI-SINGLE] Request failed: {e}")
        return None

async def classify_food_with_gemini(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the Gemini proxy for food classification.
    """
    if not GEMINI_API_KEY:
        return None

    try:
        headers = { "X-API-Key": GEMINI_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(GEMINI_FOOD_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[GEMINI-FOOD] Proxy Response: {res_data}")
                return res_data # returns {"food": "waste", "confidence": 100}
            else:
                logger.error(f"[GEMINI-FOOD] Proxy Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[GEMINI-FOOD] Request failed: {e}")
        return None

async def verify_multiple_objects_with_gemini(image_bytes: bytes) -> Optional[Dict]:
    """
    Calls the Gemini proxy for multi-object classification.
    """
    if not GEMINI_API_KEY:
        return None

    try:
        headers = { "X-API-Key": GEMINI_API_KEY }
        files = { "image": ("image.jpg", image_bytes, "image/jpeg") }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(GEMINI_MULTI_URL, headers=headers, files=files)
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[GEMINI-MULTI] Proxy Response: {res_data}")
                return res_data # returns {"object_count": X, "objects": [...]}
            else:
                logger.error(f"[GEMINI-MULTI] Proxy Error: {response.status_code}")
                return None
    except Exception as e:
        logger.error(f"[GEMINI-MULTI] Request failed: {e}")
        return None
    """
    Calls a hidden Gemini proxy server to verify classification results.
    Used as a fallback when the local model is uncertain.
    """
    if not GEMINI_API_KEY or GEMINI_API_KEY == "DEFAULT_KEY":
        logger.warning("[GEMINI] Skipping verification: No API Key provided.")
        return None

    try:
        # Prompt to ensure we get a category strictly compatible with our 6 core classes
        prompt = (
            "Identify the object in this image and determine which material it is primarily made of. "
            "You MUST classify it into exactly ONE of these categories: "
            "e-waste, glass, metal, plastic, textile, wood. "
            "Return ONLY the category name and if it is recyclable. "
            "Return format: category: <name>, recyclable: <true/false>"
        )

        headers = {
            "X-API-Key": GEMINI_API_KEY
        }
        
        files = {
            "image": ("image.jpg", image_bytes, "image/jpeg")
        }
        data = {
            "prompt": prompt
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                GEMINI_PROXY_URL,
                headers=headers,
                files=files,
                data=data
            )
            
            if response.status_code == 200:
                res_data = response.json()
                logger.info(f"[GEMINI] Proxy Response: {res_data}")
                
                # If the API returns a dict with 'result' key, use that string
                raw_text = ""
                if isinstance(res_data, dict):
                    raw_text = str(res_data.get("result", res_data))
                else:
                    raw_text = str(res_data)

                return _parse_gemini_response(raw_text)
            else:
                logger.error(f"[GEMINI] Proxy Error: {response.status_code} - {response.text}")
                # Raise an exception so the router knows it failed and can fallback
                raise Exception(f"Gemini Proxy returned {response.status_code}")

    except Exception as e:
        logger.error(f"[GEMINI] Failed to call proxy: {e}")
        return None

def _parse_gemini_response(text: str) -> Optional[Dict]:
    """Helper to extract category and recyclability from Gemini's text response."""
    text = text.lower()
    # Updated to match exactly the requested 6 core classes
    categories = ['e-waste', 'glass', 'metal', 'plastic', 'textile', 'wood']
    
    found_category = "plastic" # Default fallback
    for cat in categories:
        if cat in text:
            found_category = cat
            break
            
    recyclable = "true" in text
    
    return {
        "category": found_category,
        "recyclable": recyclable,
        "verified_by": "Gemini-Pro-Vision"
    }
