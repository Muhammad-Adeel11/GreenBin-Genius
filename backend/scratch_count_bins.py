import asyncio
import os
import sys

# Add backend to path
sys.path.append(os.getcwd())

from app.db.mongo import bins_col

async def count_bins():
    try:
        col = bins_col()
        total = await col.count_documents({})
        print(f"TOTAL_BINS: {total}")
        
        # Also print the bins to see their coordinates
        cursor = col.find({})
        async for bin in cursor:
            print(f"BIN: {bin.get('name')} | TYPE: {bin.get('bin_type')} | COORDS: {bin.get('location', {}).get('coordinates')}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    asyncio.run(count_bins())
