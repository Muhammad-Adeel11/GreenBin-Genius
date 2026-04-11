"""
GreenBin Genius – FastAPI Application Entry Point
Starts the server, registers all routers, configures CORS,
and loads AI models at startup.
"""

import os
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from app.db.mongo import ping as ping_db
from app.services import cnn_classifier, yolo_detector
from app.routers import auth, classify, history, bins, analytics

# ── Environment & Logging ────────────────────────────────────
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("greenbin")


# ── Lifespan (startup / shutdown events) ────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load models and verify DB connection when the server starts."""
    logger.info("[START] Starting GreenBin Genius API...")

    # Verify MongoDB
    await ping_db()

    # Load AI models (non-blocking if files are absent)
    cnn_classifier.load_model_on_startup()
    yolo_detector.load_model_on_startup()

    logger.info("[OK] GreenBin Genius API is ready.")
    yield
    logger.info("[STOP] Shutting down GreenBin Genius API.")


# ── FastAPI App ──────────────────────────────────────────────

app = FastAPI(
    title="GreenBin Genius API",
    description=(
        "AI-powered waste classification backend for the GreenBin Genius "
        "mobile application.\n\n"
        "### Features\n"
        "- **Waste Classification** using CNN (.h5) + YOLO (.pt) dual-model inference\n"
        "- **Bilingual** disposal tips (English & Urdu)\n"
        "- **JWT Authentication** (register / login)\n"
        "- **Classification History** (paginated, deletable)\n"
        "- **GPS Bin Locator** (2dsphere geo queries)\n"
        "- **Analytics** (personal + global impact stats)\n"
    ),
    version=os.getenv("APP_VERSION", "1.0.0"),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ─────────────────────────────────────────────────────
# Allow all during development; restrict to your domain in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ──────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(classify.router)
app.include_router(history.router)
app.include_router(bins.router)
app.include_router(analytics.router)


# ── Root Health-Check ────────────────────────────────────────

@app.get("/", tags=["Health"])
async def root():
    return {
        "service":  "GreenBin Genius API",
        "version":  os.getenv("APP_VERSION", "1.0.0"),
        "status":   "running",
        "docs":     "/docs",
    }


@app.get("/health", tags=["Health"])
async def health():
    from app.services.cnn_classifier import _model_loaded as cnn_ok
    from app.services.yolo_detector  import _yolo_loaded  as yolo_ok
    return {
        "api":        "ok",
        "cnn_model":  "loaded" if cnn_ok  else "mock_mode",
        "yolo_model": "loaded" if yolo_ok else "mock_mode",
    }
