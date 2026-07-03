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

import asyncio
from app.db.mongo import ping as ping_db
from app.services import cnn_classifier, yolo_detector
from app.routers import auth, classify, history, bins, analytics, admin, notifications, leaderboard, eco_tips, faqs, stories, tasks, broadcast
import cloudinary

# import cloudinary.config  -- Removed as it's not a valid module

# ── Environment & Logging ────────────────────────────────────
load_dotenv()

# Cloudinary Setup
if os.getenv("CLOUDINARY_URL"):
    cloudinary.config(secure=True)
elif os.getenv("CLOUDINARY_CLOUD_NAME"):
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
        api_key=os.getenv("CLOUDINARY_API_KEY"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET"),
        secure=True
    )

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("greenbin")

# Suppress outbound HTTP request logs from httpx/httpcore
# (prevents internal service URLs from appearing in server output)
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("httpcore").setLevel(logging.WARNING)



# ── Broadcast Scheduler Loop ──────────────────────────────────

async def _broadcast_scheduler_loop():
    from app.db.mongo import broadcast_schedules_col, users_col
    from app.routers.notifications import create_notification
    from datetime import datetime, timedelta
    
    logger.info("[Scheduler] Starting Eco Tips broadcast scheduler loop...")
    while True:
        try:
            now = datetime.utcnow()
            col = broadcast_schedules_col()
            # Find unsent/pending schedules that are due
            cursor = col.find({"sent_at": None, "send_at": {"$lte": now}})
            async for sched in cursor:
                # If weekly mode, check if the weekday matches the schedule's weekday (0-6)
                if sched.get("send_mode") == "weekly":
                    # weekday: 0=Mon ... 6=Sun
                    if sched.get("weekday") is not None and now.weekday() != sched["weekday"]:
                        continue

                # Query users who have notifications enabled
                u_col = users_col()
                users_cursor = u_col.find({"notifications_enabled": {"$ne": False}}, {"_id": 1})
                user_ids = [str(u["_id"]) async for u in users_cursor]

                if user_ids:
                    title_en = "🌱 Eco Tip of the Day"
                    title_ur = "🌱 آج کا ماحولیاتی مشورہ"
                    q_en = sched.get("quote_en", "")
                    q_ur = sched.get("quote_ur", "")
                    auth_en = sched.get("author_en", "")
                    auth_ur = sched.get("author_ur", "")

                    msg_en = f"\"{q_en}\" - {auth_en}" if auth_en else f"\"{q_en}\""
                    msg_ur = f"\"{q_ur}\" - {auth_ur}" if auth_ur else f"\"{q_ur}\""

                    for uid in user_ids:
                        await create_notification(
                            user_id=uid,
                            title_en=title_en,
                            title_ur=title_ur,
                            message_en=msg_en,
                            message_ur=msg_ur,
                            notif_type="system"
                        )

                # Post-process schedule
                if sched.get("send_mode") == "weekly":
                    # Reschedule for next week (7 days later)
                    next_send = sched["send_at"] + timedelta(days=7)
                    await col.update_one(
                        {"_id": sched["_id"]},
                        {"$set": {"send_at": next_send, "sent_at": None}}
                    )
                    logger.info(f"[Scheduler] Weekly broadcast sent. Rescheduled for {next_send}")
                else:
                    # One time: mark as sent
                    await col.update_one(
                        {"_id": sched["_id"]},
                        {"$set": {"sent_at": now}}
                    )
                    logger.info(f"[Scheduler] One-time broadcast sent at {now}")
        except Exception as e:
            logger.error(f"[Scheduler Error] Exception in broadcast loop: {e}")
        
        await asyncio.sleep(60)

# ── Lifespan (startup / shutdown events) ────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load models, verify DB connection and start schedules when the server starts."""
    logger.info("[START] Starting GreenBin Genius API...")

    # Verify MongoDB
    await ping_db()

    # Load AI models (non-blocking if files are absent)
    cnn_classifier.load_model_on_startup()
    yolo_detector.load_model_on_startup()

    # Start broadcast scheduler loop
    scheduler_task = asyncio.create_task(_broadcast_scheduler_loop())

    logger.info("[OK] GreenBin Genius API is ready.")
    yield
    scheduler_task.cancel()
    try:
        await scheduler_task
    except asyncio.CancelledError:
        pass
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
app.include_router(admin.router)
app.include_router(leaderboard.router)
app.include_router(notifications.router)
app.include_router(eco_tips.router)
app.include_router(faqs.router)
app.include_router(stories.router)
app.include_router(tasks.router)
app.include_router(broadcast.router)



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
