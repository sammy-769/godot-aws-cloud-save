
from pathlib import Path

import boto3
import requests
from getpass import getpass

BASE_DIR = Path(__file__).resolve().parent

# AWS configuration
REGION = "eu-north-1"
CLIENT_ID = "YOUR_APP_CLIENT_ID"

# API Gateway endpoint
API_URL = "YOUR_API_ENDPOINT"

# Initialise Cognito client
cognito = boto3.client(
    "cognito-idp",
    region_name=REGION
)


def main():

    # Step 1: Sign in to Cognito
    username = input("Enter your username or email: ").strip()
    password = getpass("Enter your password: ")

    try:
        auth_response = cognito.initiate_auth(
            AuthFlow="USER_AUTH",
            ClientId=CLIENT_ID,
            AuthParameters={
                "USERNAME": username,
                "PREFERRED_CHALLENGE": "PASSWORD",
                "PASSWORD": password
            }
        )

        auth_result = auth_response.get("AuthenticationResult")

        if not auth_result:
            print("Additional authentication challenge required:")
            print(auth_response.get("ChallengeName"))
            return

        access_token = auth_result["AccessToken"]

        print("\nCognito authentication successful!")

        # Step 2: Request an authenticated upload URL
        api_response = requests.post(
            API_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            },
            json={
                "action": "upload"
            },
            timeout=15
        )

        print("API Gateway status:", api_response.status_code)

        if api_response.status_code != 200:
            print("API request failed:", api_response.text)
            return

        result = api_response.json()

        print("S3 object:", result["object_key"])

        # Step 3: Upload the player save directly to S3
        with open(BASE_DIR / "player_save_1.json", "rb") as file:
            upload_response = requests.put(
                result["url"],
                data=file,
                headers={
                    "Content-Type": "application/json"
                },
                timeout=30
            )

        print("S3 upload status:", upload_response.status_code)

        if upload_response.status_code == 200:
            print("\nPlayer save uploaded successfully!")
        else:
            print("\nUpload failed:", upload_response.text)

    except FileNotFoundError:
        print("\nError: player_save.json was not found.")

    except cognito.exceptions.NotAuthorizedException:
        print("\nIncorrect username or password.")

    except cognito.exceptions.UserNotConfirmedException:
        print("\nYour account has not been confirmed.")

    except requests.RequestException as error:
        print("\nNetwork request failed:", error)

    except Exception as error:
        print("\nSomething went wrong:", error)


if __name__ == "__main__":
    main()
