import asyncio
import os
import sys

# Add backend to path
sys.path.append(os.getcwd())

from app.db.mongo import bins_col

async def fix_index():
    try:
        col = bins_col()
        print("Creating 2dsphere index on 'location' field...")
        
        # Create the index
        result = await col.create_index([("location", "2dsphere")])
        
        print(f"DONE: Index created name: {result}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    asyncio.run(fix_index())
