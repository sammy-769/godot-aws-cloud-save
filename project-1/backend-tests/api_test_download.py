
import json
from pathlib import Path

import requests

API_URL = "YOUR_API_ENDPOINT"
BASE_DIR = Path(__file__).resolve().parent

# Step 1: Request a download URL from API Gateway
api_response = requests.post(
    API_URL,
    headers={"Content-Type": "application/json"},
    json={
        "action": "download",
        "player_id": "PLAYER-002"
    }
)

print("API Gateway status:", api_response.status_code)

if api_response.status_code != 200:
    print(api_response.text)
    exit()

# Step 2: Extract the presigned URL
result = api_response.json()
download_url = result["url"]

print("Requested method:", result["method"])
print("S3 object:", result["object_key"])

# Step 3: Download directly from S3
s3_response = requests.get(download_url)

print("S3 download status:", s3_response.status_code)

if s3_response.status_code == 200:

    player_data = s3_response.json()

    # Step 4: Save the downloaded data
    output_path = BASE_DIR / "API-PLAYER-002-downloaded.json"

    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(player_data, file, indent=2)

    print("\nDownload successful!")
    print(json.dumps(player_data, indent=2))
    print("\nSaved to:", output_path)

else:
    print("S3 download failed:")
    print(s3_response.text[:250])

