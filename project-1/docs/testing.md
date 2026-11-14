# Testing — Project 1

## 1. Overview

Project 1 was tested in two main stages:

1. **Backend testing:** Python scripts were used on Ubuntu to test AWS services independently of the Godot application.
2. **Godot application testing:** The complete application was tested to verify registration, authentication, password reset, saving, downloading and restoring player data.

Testing the backend separately made it easier to identify whether a problem came from AWS configuration, API communication or the Godot application.

The main components tested were:

- Amazon Cognito
- Amazon API Gateway
- AWS Lambda
- Amazon S3
- Presigned upload and download URLs
- Godot authentication and cloud-save functionality

## 2. Testing Environment

Backend tests were performed on Ubuntu using Python.

The Python environment included the AWS SDK for Python (`boto3`) and the required dependencies for making HTTP requests and communicating with AWS services.

A virtual environment was used to keep the testing dependencies separate from the system Python installation.

The testing scripts included:

| Script | Purpose |
|---|---|
| `upload_test.py` | Tests uploading a JSON file to S3 using a presigned URL. |
| `download_test.py` | Tests downloading a JSON file from S3 using a presigned URL. |
| `api_test_upload.py` | Tests the API-based upload URL generation and subsequent S3 upload. |
| `api_test_download.py` | Tests the API-based download URL generation and subsequent S3 download. |
| `cognito_signup_test.py` | Tests user registration with Cognito. |
| `cognito_signin_test.py` | Tests user authentication with Cognito. |
| `cognito_upload_test.py` | Tests authenticated upload URL generation and uploading player data. |
| `cognito_download_test.py` | Tests authenticated download URL generation and downloading player data. |

The test scripts were used to verify individual parts of the backend before relying on the Godot interface. These scripts read and write their sample files beside the script files in `project-1/backed-tests/` so they do not depend on a machine-specific `~/Sam` folder.

## 3. Amazon S3 Testing

The first tests focused on direct S3 access through presigned URLs.

A sample JSON file containing player information was used:

```json
{
    "player_id": "PLAYER-002",
    "username": "Sammy",
    "level": 12,
    "coins": 850,
    "high_score": 4500,
    "games_played": 36
}
```

### Upload test

The upload test generated a presigned PUT URL and used it to upload the JSON file to the S3 bucket.

The upload was successful after correcting an earlier signature-related issue.

The upload request used the expected `application/json` content type.

### Download test

The download test generated a presigned GET URL and downloaded the stored JSON file.

The downloaded file was saved beside the project test scripts in:

`project-1/backed-tests/API-PLAYER-002-downloaded.json`

The downloaded data was checked against the original player information to confirm that the values had been stored and retrieved correctly.

These tests confirmed that private S3 objects could be uploaded and downloaded using temporary presigned URLs without making the bucket public or giving the testing application AWS access keys.

## 4. AWS Lambda Testing

Before connecting the function to API Gateway, the Lambda function was tested directly using the AWS Lambda console.

Two test events were used:

- `TestUploadURL`
- `TestDownloadURL`

These tests checked whether Lambda could generate the correct presigned URL for each operation.

The upload test verified that the function could generate a PUT URL for a player object.

The download test verified that it could generate a GET URL for the same object.

Both direct Lambda tests succeeded.

This confirmed that the Lambda function could communicate with S3 using its execution role and generate the required URLs.

## 5. API Gateway Testing

After testing Lambda independently, API Gateway was tested to verify that it could invoke the function through the configured HTTP API.

The route used was:

```text
POST /presigned-url
```

The API was configured with the `$default` stage and automatic deployment.

### Initial endpoint issue

An early API test returned:

```text
404 Not Found
```

The problem was caused by using an incorrect endpoint path in the test request.

The correct endpoint includes the `/presigned-url` route:

```text
https://0mnj6h83vi.execute-api.eu-north-1.amazonaws.com/presigned-url
```

After correcting the endpoint, the API request succeeded.

### Upload test

The `api_test_upload.py` script tested the complete API-based upload process:

1. The Python script sent a request to API Gateway.
2. API Gateway invoked Lambda.
3. Lambda generated a presigned S3 PUT URL.
4. The API returned the URL.
5. The Python script uploaded the JSON file directly to S3.

The API request returned HTTP `200`, and the S3 upload returned HTTP `200`.

This confirmed that API Gateway, Lambda and S3 were communicating correctly.

## 6. Amazon Cognito Testing

Cognito was tested independently before completing the authentication flow in Godot.

The tests covered user registration and authentication.

### Registration

The registration test checked whether a new user could be created using Cognito.

The registration process required a username, password and email address.

Cognito sent an email verification code to confirm the account.

### Email verification

The account confirmation process was tested using the verification code.

After successful confirmation, the account could be used for authentication.

### Sign-in

The sign-in test checked whether a confirmed user could authenticate using the configured `USER_PASSWORD_AUTH` flow.

The test verified that Cognito returned the required authentication tokens.

The access token was particularly important because it would later be used to authenticate requests to API Gateway.

## 7. Authenticated Upload and Download Testing

After Cognito and the API had been tested separately, they were combined.

The authenticated Python tests checked the complete process:

1. Authenticate with Cognito.
2. Obtain an access token.
3. Send an authenticated request to API Gateway.
4. Allow API Gateway to validate the JWT.
5. Let Lambda obtain the player's identity from the verified claims.
6. Generate a player-specific presigned URL.
7. Upload or download the save file directly through S3.

The `cognito_upload_test.py` and `cognito_download_test.py` scripts were used for these tests.

These tests were important because they verified more than basic S3 access. They also checked that the authenticated identity could be used to generate the correct player-specific object key.

## 8. Godot Application Testing

After the backend tests, the functionality was tested through the Godot application.

The following areas were checked:

### Authentication

- Register a new player account.
- Confirm the account using the email verification code.
- Sign in using the registered credentials.
- Sign in using the supported username or email identifier.
- Attempt to sign in with an incorrect password.
- Attempt to sign in with an unknown username.
- Log out and verify that the local session tokens are cleared.

### Password reset

The password-reset interface was implemented and tested.

The process was:

1. Open the Forgot Password interface.
2. Enter the registered account identifier.
3. Request a password-reset code.
4. Receive the verification code through email.
5. Enter the code and a new password.
6. Submit the request to Cognito.
7. Sign in using the new password.

The password-reset flow worked successfully.

### Cloud saving

The save functionality was tested by creating and uploading player data.

The application requested a presigned URL from API Gateway and used it to upload the JSON save file directly to S3.

The test confirmed that the game could save player information without sending the complete save file through Lambda.

### Cloud loading

The application requested a download URL and retrieved the player's save file from S3.

The downloaded JSON was processed by the application, and the player information was restored.

### Persistence

The application was closed and reopened to check whether the saved player data could be retrieved again.

The player could sign in and restore the previously saved information from S3.

### Player isolation

Two separate player accounts were used to test whether their save data remained separate.

Each account used its own Cognito identity, and Lambda generated the corresponding S3 object key from that identity.

This tested the application's player-data isolation mechanism.

### No-save scenario

The application was also tested when a player had no existing save file.

This checked how the application handled the absence of previously stored player data rather than assuming that every player already had a save.

## 9. Development and Project Checks

In addition to functional testing, basic development checks were performed.

The Godot project was checked using Godot 4.7.2 in headless mode to verify that it could start and parse without requiring the graphical editor.

The following Git command was also used:

```bash
git diff --check
```

This checks for common whitespace errors in Git changes, such as trailing whitespace and whitespace problems in patches. It does not replace a full code review or runtime test.

Both checks passed during the recorded testing process.

## 10. Issues Encountered and Resolved

A few issues were encountered during development and testing.

### Presigned URL signature mismatch

An early direct S3 upload returned:

```text
403 SignatureDoesNotMatch
```

The generated signature was initially found to have an incorrect length. After correcting the URL-generation issue, the signature had the expected 64-character length and the upload succeeded.

### API Gateway 404 response

The initial API test used an incorrect endpoint path.

After correcting the request URL to include the configured `/presigned-url` route, the API request succeeded.

### Direct S3 transfer

The testing process confirmed that the save file should be transferred directly between the application and S3 rather than sent through API Gateway and Lambda.

This keeps Lambda responsible for authentication-related checks and URL generation, while S3 handles the actual file transfer.

## 11. Test Results Summary

| Component or feature | Result |
|---|---|
| S3 presigned upload | Passed |
| S3 presigned download | Passed |
| Lambda upload URL generation | Passed |
| Lambda download URL generation | Passed |
| API Gateway integration | Passed |
| API-based S3 upload | Passed |
| Cognito registration | Passed |
| Email verification | Passed |
| Cognito sign-in | Passed |
| Invalid sign-in attempts | Tested |
| Authenticated upload | Passed |
| Authenticated download | Passed |
| Godot registration and login | Tested |
| Godot password reset | Passed |
| Godot cloud save and load | Passed |
| Save persistence after restarting | Passed |
| Separate player accounts | Tested |
| No-save scenario | Tested |
| Godot headless project check | Passed |
| `git diff --check` | Passed |

The results represent the development tests performed during this project. They do not constitute a formal security audit, load test or production-readiness assessment.

## 12. Conclusion

Testing was performed progressively, starting with individual AWS services and moving towards the complete Godot application.

Python scripts on Ubuntu helped verify S3 uploads and downloads, Lambda URL generation, API Gateway integration and Cognito authentication independently of the game.

The final Godot tests then verified that these services worked together to provide player registration, email verification, password reset and cloud saving.

The project successfully demonstrated an authenticated cloud-save workflow in which each player's save file is associated with their Cognito identity and stored privately in Amazon S3.

The testing process also helped identify and resolve configuration issues before they became part of the final application.