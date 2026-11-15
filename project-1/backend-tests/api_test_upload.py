
from pathlib import Path

import requests

API_URL = "YOUR_API_ENDPOINT"
BASE_DIR = Path(__file__).resolve().parent
FILE_PATH = BASE_DIR / "PLAYER-002.json"

# Step 1: Request an upload URL from API Gateway
api_response = requests.post(
    API_URL,
    headers={"Content-Type": "application/json"},
    json={
        "action": "upload",
        "player_id": "PLAYER-002"
    }
)

print("API Gateway status:", api_response.status_code)

if api_response.status_code != 200:
    print(api_response.text)
    exit()

# Step 2: Extract the presigned URL
result = api_response.json()
upload_url = result["url"]

print("Requested method:", result["method"])
print("S3 object:", result["object_key"])

# Step 3: Upload the file directly to S3
with open(FILE_PATH, "rb") as file:
    s3_response = requests.put(
        upload_url,
        data=file,
        headers={
            "Content-Type": "application/json"
        }
    )

print("S3 upload status:", s3_response.status_code)

if s3_response.status_code == 200:
    print("Upload successful!")
else:
    print("Upload failed:")
    print(s3_response.text[:250])
