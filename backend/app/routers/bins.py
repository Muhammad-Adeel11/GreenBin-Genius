"""
GreenBin Genius – Bins Router
GET /api/bins/nearby  – returns nearby waste bins using a geo query.
Follows FR-5 (GPS Bin Locator) from SRS.
"""

from fastapi import APIRouter, Query, HTTPException
from app.db.mongo import bins_col
from app.models.schemas import BinCreate, SuccessResponse

router = APIRouter(prefix="/api/bins", tags=["Bin Locator"])


@router.post("/", summary="Add a new bin location", response_model=SuccessResponse)
async def create_bin(bin_data: BinCreate):
    """
    Creates a new waste bin in the system with geo-coordinates.
    """
    doc = {
        "name": bin_data.name,
        "bin_type": bin_data.bin_type,
        "address": bin_data.address,
        "waste_types": bin_data.waste_types or ["PLASTIC"],
        "status": "ACTIVE",
        "location": {
            "type": "Point",
            "coordinates": [bin_data.longitude, bin_data.latitude]
        }
    }
    
    col = bins_col()
    result = await col.insert_one(doc)
    
    return {
        "success": True,
        "message": f"Bin '{bin_data.name}' added successfully with ID {result.inserted_id}"
    }


@router.get(
    "/",
    summary="Fetch all waste bin locations",
)
async def get_all_bins():
    """
    Returns a list of all waste bins in the system.
    """
    cursor = bins_col().find({})
    bins = []
    async for doc in cursor:
        coords = doc.get("location", {}).get("coordinates", [0, 0])
        bins.append({
            "id":           str(doc["_id"]),
            "_id":          str(doc["_id"]),
            "name":         doc.get("name", "Unnamed Bin"),
            "bin_type":     doc.get("bin_type", "General"),
            "status":       doc.get("status", "ACTIVE"),
            "latitude":     coords[1],
            "longitude":    coords[0],
            "address":      doc.get("address"),
            "waste_types":  doc.get("waste_types", ["PLASTIC"]),
        })

    return {"success": True, "total": len(bins), "data": bins}




@router.get(
    "/nearby",
    summary="Find the nearest waste disposal bins",
    description=(
        "Pass the user's latitude and longitude. "
        "Returns up to `limit` bins within `max_distance_m` metres, "
        "sorted by distance (nearest first). "
        "Uses MongoDB 2dsphere geo query."
    ),
)
async def get_nearby_bins(
    lat: float = Query(..., description="User latitude",  example=34.1558),
    lng: float = Query(..., description="User longitude", example=73.2215),
    max_distance_m: int  = Query(default=5000, description="Search radius in metres"),
    limit: int           = Query(default=10,   description="Max number of results"),
    bin_type: str | None = Query(default=None, description="Filter by bin type (e.g. 'plastic')"),
):
    query: dict = {
        "location": {
            "$near": {
                "$geometry": {
                    "type": "Point",
                    "coordinates": [lng, lat],   # GeoJSON: [lng, lat]
                },
                "$maxDistance": max_distance_m,
            }
        }
    }

    if bin_type:
        query["bin_type"] = {"$regex": bin_type, "$options": "i"}

    cursor = bins_col().find(query).limit(limit)
    bins = []
    async for doc in cursor:
        coords = doc.get("location", {}).get("coordinates", [0, 0])
        bins.append({
            "id":           str(doc["_id"]),
            "name":         doc.get("name", "Unnamed Bin"),
            "bin_type":     doc.get("bin_type", "General"),
            "latitude":     coords[1],
            "longitude":    coords[0],
            "address":      doc.get("address"),
        })

    return {"total": len(bins), "bins": bins}


@router.post(
    "/seed",
    summary="[Admin] Seed sample bin locations into MongoDB",
    description="Inserts a few sample bins for Abbottabad area. Run once during setup.",
)
async def seed_bins():
    """
    Seeds sample bin locations – useful for testing the nearby query.
    All coordinates are approximate.
    """
    sample_bins = [
        {
            "name": "Jinnah Abbottabad Recycling Point",
            "bin_type": "Plastic / Recyclable",
            "address": "Jinnah Road, Abbottabad",
            "location": {"type": "Point", "coordinates": [73.2119, 34.1463]},
        },
        {
            "name": "COMSATS Campus Waste Station",
            "bin_type": "General / E-waste",
            "address": "COMSATS University, Abbottabad",
            "location": {"type": "Point", "coordinates": [73.2215, 34.1558]},
        },
        {
            "name": "Mansehra Road Green Bin",
            "bin_type": "Organic / Vegetation",
            "address": "Mansehra Road, Abbottabad",
            "location": {"type": "Point", "coordinates": [73.2057, 34.1601]},
        },
    ]

    col = bins_col()
    # Create 2dsphere index if not present
    await col.create_index([("location", "2dsphere")])
    result = await col.insert_many(sample_bins)

    return {
        "success": True,
        "inserted": len(result.inserted_ids),
        "message": "Sample bins seeded.",
    }
