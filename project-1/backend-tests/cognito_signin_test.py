
import boto3
import requests
from getpass import getpass

REGION = "eu-north-1"
CLIENT_ID = "YOUR_APP_CLIENT_ID"

API_URL = "YOUR_API_ENDPOINT"

cognito = boto3.client(
    "cognito-idp",
    region_name=REGION
)

# Ask for login details
username = input("Enter your username or email: ").strip()
password = getpass("Enter your password: ")

try:
    # Authenticate directly with Cognito
    auth_response = cognito.initiate_auth(
        AuthFlow="USER_AUTH",
        ClientId=CLIENT_ID,
        AuthParameters={
            "USERNAME": username,
            "PREFERRED_CHALLENGE": "PASSWORD",
            "PASSWORD": password
        }
    )

    # Check whether Cognito issued tokens
    auth_result = auth_response.get("AuthenticationResult")

    if not auth_result:
        print("Additional authentication challenge required:")
        print(auth_response.get("ChallengeName"))
        raise SystemExit(1)

    access_token = auth_result["AccessToken"]

    print("\nCognito authentication successful!")
    print("Access token received.")
    print("Token expires in:", auth_result["ExpiresIn"], "seconds")

    # Test our protected API
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

    print("\nAPI Gateway status:", api_response.status_code)

    try:
        result = api_response.json()
        print("Response:", result)

        if api_response.status_code == 200:
            print("\nAuthenticated API request successful!")

    except ValueError:
        print("Unexpected response:", api_response.text)

except cognito.exceptions.NotAuthorizedException:
    print("\nIncorrect username or password.")

except cognito.exceptions.UserNotConfirmedException:
    print("\nYour account has not been confirmed.")

except Exception as error:
    print("\nAuthentication or API request failed:")
    print(error)
