"""
GreenBin Genius – MongoDB Connection
Async motor client shared across the app lifetime.
"""

import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "")

# Singleton client – initialised once at startup
_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        _client = AsyncIOMotorClient(MONGO_URI)
    return _client


def get_db():
    """Return the 'greenbin' database object."""
    return get_client()["greenbin"]


# ── Collection helpers ─────────────────────────────────────

def users_col():
    return get_db()["users"]


def classifications_col():
    return get_db()["classifications"]


def bins_col():
    return get_db()["bins"]


def analytics_col():
    return get_db()["analytics"]


async def ping():
    """Check connectivity – called at startup."""
    try:
        await get_client().admin.command("ping")
        print("[OK] MongoDB connected successfully.")
    except Exception as exc:
        print(f"[ERROR] MongoDB connection FAILED: {exc}")
