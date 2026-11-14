
import boto3
from getpass import getpass

REGION = "eu-north-1"
CLIENT_ID = "YOUR_APP_CLIENT_ID"

cognito = boto3.client(
    "cognito-idp",
    region_name=REGION
)

username = input("Choose a username: ").strip()
email = input("Enter your email address: ").strip()
password = getpass("Choose a password: ")

try:
    result = cognito.sign_up(
        ClientId=CLIENT_ID,
        Username=username,
        Password=password,
        UserAttributes=[
            {
                "Name": "email",
                "Value": email
            }
        ]
    )

    print("\nRegistration successful!")
    print("Cognito User ID:", result["UserSub"])

    delivery = result.get("CodeDeliveryDetails", {})
    print("Verification sent to:", delivery.get("Destination", email))

    code = input("\nEnter the email verification code: ").strip()

    cognito.confirm_sign_up(
        ClientId=CLIENT_ID,
        Username=username,
        ConfirmationCode=code
    )

    print("\nEmail verified! Your account is confirmed.")

except cognito.exceptions.UsernameExistsException:
    print("\nThis username is already registered.")

except cognito.exceptions.InvalidPasswordException as error:
    print("\nPassword does not meet Cognito's requirements.")
    print(error)

except Exception as error:
    print("\nSomething went wrong:")
    print(error)
