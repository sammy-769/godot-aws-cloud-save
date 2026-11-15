import json
from pathlib import Path

import requests

BASE_DIR = Path(__file__).resolve().parent
url = input("Paste your fresh presigned GET URL: ").strip().strip('"').strip("'")

while url.endswith(("\\", "]", ")")):
    url = url[:-1]

response = requests.get(url)

print("HTTP status:", response.status_code)

if response.status_code == 200:

    data = response.json()

    print("\nDownload successful!")
    print(json.dumps(data, indent=2))

    output_path = BASE_DIR / "PLAYER-002-downloaded.json"

    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2)

    print("\nFile saved to:", output_path)

else:
    print("Download failed.")
    print(response.text[:250])
