
import boto3
import requests
import json
from getpass import getpass

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
    password = input("Enter your password: ")

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

        # Step 2: Request an authenticated download URL
        api_response = requests.post(
            API_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            },
            json={
                "action": "download"
            },
            timeout=15
        )

        print("API Gateway status:", api_response.status_code)

        if api_response.status_code != 200:
            print("API request failed:", api_response.text)
            return

        result = api_response.json()

        print("S3 object:", result["object_key"])

        # Step 3: Download the player save directly from S3
        download_response = requests.get(
            result["url"],
            timeout=30
        )

        print("S3 download status:", download_response.status_code)

        if download_response.status_code != 200:
            print("Download failed:", download_response.text)
            return

        # Step 4: Convert the downloaded JSON into Python data
        player_data = download_response.json()

        print("\nPlayer save downloaded successfully!")
        print("\nDownloaded player data:")

        print(json.dumps(
            player_data,
            indent=4
        ))

    except cognito.exceptions.NotAuthorizedException:
        print("\nIncorrect username or password.")

    except cognito.exceptions.UserNotConfirmedException:
        print("\nYour account has not been confirmed.")

    except requests.RequestException as error:
        print("\nNetwork request failed:", error)

    except json.JSONDecodeError:
        print("\nThe downloaded file is not valid JSON.")

    except Exception as error:
        print("\nSomething went wrong:", error)


if __name__ == "__main__":
    main()
