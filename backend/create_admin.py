import asyncio
from app.db.mongo import users_col
from app.routers.auth import hash_password as get_password_hash
import os
from dotenv import load_dotenv

# Load environment variables (DB_URL, etc.)
load_dotenv()

async def create_admin(name, email, password):
    # Hash the password to match backend security
    hashed_password = get_password_hash(password)
    
    admin_doc = {
        "name": name,
        "email": email,
        "password": hashed_password,
        "role": "admin",
        "is_active": True,
        "total_scans": 0,
        "language": "en"
    }
    
    # Check if user already exists
    col = users_col()
    existing = await col.find_one({"email": email})
    if existing:
        print(f"User {email} already exists. Updating role to admin...")
        await col.update_one({"email": email}, {"$set": {"role": "admin"}})
    else:
        await col.insert_one(admin_doc)
        print(f"Successfully created Admin: {email}")

if __name__ == "__main__":
    # Change these to your desired admin credentials
    NAME = "Super Admin"
    EMAIL = "admin@greenbin.ai"
    PASSWORD = "AdminPassword123"
    
    asyncio.run(create_admin(NAME, EMAIL, PASSWORD))
