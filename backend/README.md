# GreenBin Genius – Backend API

A production-ready **FastAPI** backend powering the GreenBin Genius smart waste sorting mobile application.

---

## 🏗️ Architecture

```
backend/
├── main.py                    # App entry, CORS, routers, model loading
├── requirements.txt
├── Dockerfile                 # Hugging Face Spaces deployment
├── .env.example               # Copy to .env and fill values
├── ml/
│   ├── cnn_model.h5           # ← Place your CNN model here
│   └── yolo_model.pt          # ← Place your YOLO model here
└── app/
    ├── routers/
    │   ├── auth.py            # POST /api/auth/register, /login, GET /api/auth/me
    │   ├── classify.py        # POST /api/classify
    │   ├── history.py         # GET /api/history, DELETE /api/history/{id}
    │   ├── bins.py            # GET /api/bins/nearby, POST /api/bins/seed
    │   └── analytics.py       # GET /api/analytics/me, /global
    ├── services/
    │   ├── cnn_classifier.py  # Keras .h5 inference (13 CNN classes)
    │   └── yolo_detector.py   # Ultralytics YOLO .pt inference
    ├── models/
    │   └── schemas.py         # Pydantic request/response schemas
    └── db/
        └── mongo.py           # Async Motor MongoDB client
```

---

## 🚀 Quick Start (Local)

```bash
# 1. Create virtual environment
python -m venv venv
venv\Scripts\activate      # Windows
# source venv/bin/activate # Linux/Mac

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set environment variables
copy .env.example .env
# Edit .env with your MONGO_URI, JWT_SECRET, etc.

# 4. Drop your models into ml/
#    ml/cnn_model.h5
#    ml/yolo_model.pt

# 5. Run the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open **http://localhost:8000/docs** for the interactive Swagger UI.

---

## 🤖 AI Models

| Model | File | Classes |
|---|---|---|
| CNN (Keras) | `ml/cnn_model.h5` | Trash, Vegetation, cardboard, clothes, e-waste, food_waste, glass, medical, metal, not_food_waste, paper, plastic, shoes |
| YOLO (Ultralytics) | `ml/yolo_model.pt` | Object detection (any class) |

> **Mock Mode**: If model files are absent, the API runs in **mock mode** – returning realistic placeholder data. This lets the Flutter frontend be developed and tested without real models.

---

## 📡 API Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | ❌ | Register new user |
| POST | `/api/auth/login` | ❌ | Login & receive JWT |
| GET  | `/api/auth/me` | ✅ | Get current user profile |
| POST | `/api/classify` | ✅ | Upload image → AI result |
| GET  | `/api/classify/test` | ❌ | Model load status |
| GET  | `/api/history` | ✅ | Paginated scan history |
| DELETE | `/api/history/{id}` | ✅ | Delete history entry |
| GET  | `/api/bins/nearby` | ❌ | Nearest waste bins |
| POST | `/api/bins/seed` | ❌ | Seed sample bins |
| GET  | `/api/analytics/me` | ✅ | Personal impact stats |
| GET  | `/api/analytics/global` | ❌ | Global impact stats |
| GET  | `/health` | ❌ | Server & model status |

---

## ☁️ Hugging Face Spaces Deployment

1. Create a new Space → **Docker** SDK
2. Push the `backend/` folder contents to the Space repo
3. Upload `ml/cnn_model.h5` and `ml/yolo_model.pt` via the HF web UI
4. Add **Secrets** in Space Settings:
   - `MONGO_URI`
   - `JWT_SECRET`
5. HF auto-builds → your API is live at `https://your-username-greenbin.hf.space`

---

## 🌐 Bilingual Support

Every classification response includes **English and Urdu** disposal guidance:
```json
{
  "disposal_tip":    "Rinse and place in the plastic recycling (blue) bin.",
  "disposal_tip_ur": "صاف کریں اور نیلے پلاسٹک ری سائیکلنگ ڈبے میں ڈالیں۔"
}
```
