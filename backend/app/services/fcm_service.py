"""
GreenBin Genius – FCM Service
Singleton Firebase Admin SDK. Provides send_push() and send_push_multicast()
used by the notifications router to deliver real push alerts to Android/iOS.
"""

import os
import logging
import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger("greenbin")

# ── Singleton init ────────────────────────────────────────────
_initialized = False

def _init():
    global _initialized
    if _initialized:
        return
    # Locate service-account JSON relative to this file's project root.
    # Tries the exact filename placed by the user, then a generic fallback name.
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", "..", "greenbin-genius-firebase-adminsdk-fbsvc-effabb2cbd.json"),
        os.path.join(os.path.dirname(__file__), "..", "..", "firebase_service_account.json"),
    ]
    sa_path = None
    for c in candidates:
        if os.path.isfile(c):
            sa_path = os.path.abspath(c)
            break

    if not sa_path:
        logger.warning("[FCM] Service account file not found – push notifications disabled.")
        return

    try:
        cred = credentials.Certificate(sa_path)
        firebase_admin.initialize_app(cred)
        _initialized = True
        logger.info(f"[FCM] Firebase Admin SDK initialised from '{sa_path}'.")
    except Exception as exc:
        logger.error(f"[FCM] Failed to initialise Firebase Admin SDK: {exc}")


_init()   # Run at import time


# ── Public helpers ────────────────────────────────────────────

async def send_push(
    token:   str,
    title:   str,
    body:    str,
    data:    dict | None = None,
) -> bool:
    """
    Send a push notification to a single FCM device token.
    Returns True on success, False on failure.
    """
    if not _initialized or not token:
        return False
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#2196F3",
                    sound="default",
                    channel_id="greenbin_default",
                ),
            ),
        )
        messaging.send(message)
        return True
    except Exception as exc:
        logger.warning(f"[FCM] send_push failed: {exc}")
        return False


async def send_push_multicast(
    tokens:  list[str],
    title:   str,
    body:    str,
    data:    dict | None = None,
) -> dict:
    """
    Send the same push notification to up to 500 device tokens at once.
    Automatically batches if len(tokens) > 500.
    Returns {"success": N, "failure": N}.
    """
    if not _initialized or not tokens:
        return {"success": 0, "failure": 0}

    success_count = 0
    failure_count = 0
    batch_size    = 500

    for i in range(0, len(tokens), batch_size):
        batch = tokens[i : i + batch_size]
        try:
            multicast_msg = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data={k: str(v) for k, v in (data or {}).items()},
                tokens=batch,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        icon="ic_notification",
                        color="#2196F3",
                        sound="default",
                        channel_id="greenbin_default",
                    ),
                ),
            )
            response = messaging.send_each_for_multicast(multicast_msg)
            success_count += response.success_count
            failure_count += response.failure_count
        except Exception as exc:
            logger.warning(f"[FCM] send_push_multicast batch failed: {exc}")
            failure_count += len(batch)

    logger.info(f"[FCM] Multicast done – success={success_count}, failure={failure_count}")
    return {"success": success_count, "failure": failure_count}
