from pathlib import Path
from urllib.parse import parse_qs, urlsplit

import requests

BASE_DIR = Path(__file__).resolve().parent
file_path = BASE_DIR / "PLAYER-002.json"

url = input("Paste a fresh presigned URL: ").strip().strip('"').strip("'")

# Remove accidental Markdown characters after the URL
while url.endswith(("\\", "]", ")")):
    url = url[:-1]

parts = urlsplit(url)
params = parse_qs(parts.query)

print("\n--- URL diagnostics ---")
print("HTTPS:", parts.scheme == "https")
print("Correct regional host:",
      parts.hostname == "godot-project-1.s3.eu-north-1.amazonaws.com")
print("Correct object path:",
      parts.path == "/players/PLAYER-002.json")
print("Signature present:", "X-Amz-Signature" in params)
print("Signature length:",
      len(params.get("X-Amz-Signature", [""])[0]))
print("Security token present:", "X-Amz-Security-Token" in params)
print("Signed headers:",
      params.get("X-Amz-SignedHeaders", ["Missing"])[0])
print("Credential scope:",
      params.get("X-Amz-Credential", ["Missing"])[0].split("/", 1)[-1])
print("URL expiry:",
      params.get("X-Amz-Expires", ["Missing"])[0], "seconds")

with open(file_path, "rb") as file:
    response = requests.put(
        url,
        data=file,
        headers={"Content-Type": "application/json"}
    )

print("\nHTTP status:", response.status_code)

if response.status_code == 200:
    print("Upload successful!")
else:
    print("S3 error:", response.text[:200])


params = parse_qs(urlsplit(url).query)
signature = params.get("X-Amz-Signature", [""])[0]

print("Signature length:", len(signature))
print(
    "Valid signature format:",
    len(signature) == 64 and all(c in "0123456789abcdefABCDEF" for c in signature)
)
