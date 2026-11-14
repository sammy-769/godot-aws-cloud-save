extends Node

# Project 1's Cognito gateway.
# This node talks directly to Amazon Cognito over HTTPS and emits signals back to
# the UI when a request starts, succeeds, or fails. The authentication logic stays
# completely separate from the save/load service and the scene controller.

signal operation_started(operation: String)
signal operation_finished(operation: String)
signal registration_accepted(username: String, message: String)
signal registration_failed(message: String)
signal confirmation_succeeded
signal confirmation_failed(message: String)
signal resend_succeeded(message: String)
signal resend_failed(message: String)
signal login_succeeded(username: String)
signal login_failed(message: String)
signal password_reset_code_sent(username: String, message: String)
signal password_reset_code_failed(message: String)
signal password_reset_succeeded(username: String)
signal password_reset_failed(message: String)

const COGNITO_ENDPOINT := "https://cognito-idp.eu-north-1.amazonaws.com/"
const CLIENT_ID := "YOUR_APP_CLIENT_ID"
const CONTENT_TYPE := "application/x-amz-json-1.1"

var _http_request: HTTPRequest
var _operation := ""
var _request_username := ""
var _request_in_progress := false
var _access_token := ""
var _id_token := ""
var _refresh_token := ""
var _token_expires_at := 0


# Creates the internal HTTPRequest node that performs all Cognito calls.
# We keep the transfer asynchronous so the Godot UI remains responsive while AWS
# is processing the request.
func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.name = "CognitoHTTPRequest"
	_http_request.timeout = 20.0
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


# Sends a new user registration request to Cognito.
# This is the SignUp flow used for creating a new account with a verified email.
func sign_up(username: String, email: String, password: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
		"Password": password,
		"UserAttributes": [
			{
				"Name": "email",
				"Value": email,
			},
		],
	}
	return _send_request("SignUp", username, payload)


# Confirms the emailed verification code for a newly created account.
func confirm_sign_up(username: String, confirmation_code: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
		"ConfirmationCode": confirmation_code,
	}
	return _send_request("ConfirmSignUp", username, payload)


# Requests a fresh email verification code for a user who has not yet confirmed.
func resend_confirmation_code(username: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
	}
	return _send_request("ResendConfirmationCode", username, payload)


# Starts the password reset flow by asking Cognito to send a reset code to the
# verified email for the provided username or email address.
func forgot_password(username: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
	}
	return _send_request("ForgotPassword", username, payload)


# Completes the password reset by sending the verification code and the new
# password back to Cognito.
func confirm_forgot_password(
	username: String,
	confirmation_code: String,
	new_password: String
) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
		"ConfirmationCode": confirmation_code,
		"Password": new_password,
	}
	return _send_request("ConfirmForgotPassword", username, payload)


# Starts Cognito's USER_PASSWORD_AUTH flow for sign-in.
# This keeps the login request fully asynchronous while returning the access token
# once Cognito responds.
func initiate_password_auth(username: String, password: String) -> Error:
	if _request_in_progress:
		return ERR_BUSY
	_clear_tokens()
	var payload := {
		"AuthFlow": "USER_PASSWORD_AUTH",
		"ClientId": CLIENT_ID,
		"AuthParameters": {
			"USERNAME": username,
			"PASSWORD": password,
		},
	}
	return _send_request("InitiateAuth", username, payload)


# Returns the cached access token only when it has not expired.
# If the token has expired, the browser-style in-memory cache is cleared.
func get_valid_access_token() -> String:
	if _access_token.is_empty():
		return ""
	if int(Time.get_unix_time_from_system()) >= _token_expires_at:
		_clear_tokens()
		return ""
	return _access_token


# Clears the cached Cognito tokens so the session ends cleanly.
func logout() -> void:
	_clear_tokens()


# Builds a Cognito request using the AWS JSON API format and the correct
# X-Amz-Target header for the selected operation.
func _send_request(operation: String, username: String, payload: Dictionary) -> Error:
	if _request_in_progress:
		return ERR_BUSY

	var headers := PackedStringArray([
		"Content-Type: %s" % CONTENT_TYPE,
		"X-Amz-Target: AWSCognitoIdentityProviderService.%s" % operation,
	])
	var request_body := JSON.stringify(payload)
	_operation = operation
	_request_username = username
	_request_in_progress = true

	var request_error := _http_request.request(
		COGNITO_ENDPOINT,
		headers,
		HTTPClient.METHOD_POST,
		request_body
	)
	if request_error != OK:
		_operation = ""
		_request_username = ""
		_request_in_progress = false
		return request_error

	operation_started.emit(operation)
	return OK


# Handles the asynchronous completion of every Cognito request.
# This central callback interprets the HTTP status, maps AWS errors to friendly
# messages, and emits a signal for the UI to react to.
func _on_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var completed_operation := _operation
	var completed_username := _request_username
	_operation = ""
	_request_username = ""
	_request_in_progress = false

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_failure(completed_operation, "Could not connect to Cognito. Check your connection and try again.")
		operation_finished.emit(completed_operation)
		return

	var response_data := _parse_response(body)
	if response_code < 200 or response_code >= 300:
		_emit_failure(completed_operation, _error_message(completed_operation, response_data))
		operation_finished.emit(completed_operation)
		return

	match completed_operation:
		"SignUp":
			var delivery_details: Variant = response_data.get("CodeDeliveryDetails", {})
			var message := "Registration accepted. Check your email for a verification code."
			if not delivery_details is Dictionary or delivery_details.is_empty():
				message = "Registration accepted. Cognito did not return code delivery details; the account is not assumed verified."
			registration_accepted.emit(completed_username, message)
		"ConfirmSignUp":
			confirmation_succeeded.emit()
		"ResendConfirmationCode":
			resend_succeeded.emit("A new verification code was sent.")
		"ForgotPassword":
			var delivery_details: Variant = response_data.get("CodeDeliveryDetails", {})
			var message := "Password reset request accepted. Check your verified email for a code."
			if not delivery_details is Dictionary or delivery_details.is_empty():
				message = "Password reset request accepted, but Cognito did not return code delivery details. Check the account's verified contact method."
			password_reset_code_sent.emit(
				completed_username,
				message
			)
		"ConfirmForgotPassword":
			password_reset_succeeded.emit(completed_username)
		"InitiateAuth":
			_handle_authentication_response(completed_username, response_data)

	operation_finished.emit(completed_operation)


# Extracts the issued Cognito tokens from a successful login response and stores
# them in memory for later API calls.
func _handle_authentication_response(username: String, response_data: Dictionary) -> void:
	var authentication_result: Variant = response_data.get("AuthenticationResult")
	if not authentication_result is Dictionary:
		login_failed.emit(_challenge_message(response_data))
		return

	var access_token := str(authentication_result.get("AccessToken", ""))
	var id_token := str(authentication_result.get("IdToken", ""))
	var refresh_token := str(authentication_result.get("RefreshToken", ""))
	var expires_in := int(authentication_result.get("ExpiresIn", 0))
	if access_token.is_empty() or id_token.is_empty() or expires_in <= 0:
		_clear_tokens()
		login_failed.emit("Cognito returned an incomplete authentication response. Please try again.")
		return

	_access_token = access_token
	_id_token = id_token
	_refresh_token = refresh_token
	_token_expires_at = int(Time.get_unix_time_from_system()) + expires_in
	login_succeeded.emit(username)


# Turns a challenge-style Cognito response into a human-readable message.
# This helps the UI explain why sign-in could not complete without exposing AWS
# internals.
func _challenge_message(response_data: Dictionary) -> String:
	var challenge_name := str(response_data.get("ChallengeName", ""))
	match challenge_name:
		"SMS_MFA", "SOFTWARE_TOKEN_MFA", "EMAIL_OTP", "SMS_OTP":
			return "This account requires an additional verification step, which is not supported yet."
		"NEW_PASSWORD_REQUIRED":
			return "This account must change its password before it can sign in."
		"PASSWORD_RESET_REQUIRED":
			return "This account must reset its password before it can sign in."
		"SELECT_MFA_TYPE", "MFA_SETUP":
			return "This account requires MFA setup, which is not supported yet."
		_:
			return "Cognito did not complete sign-in. An unsupported authentication challenge may be required."


# Removes the in-memory auth state so future calls do not reuse stale tokens.
func _clear_tokens() -> void:
	_access_token = ""
	_id_token = ""
	_refresh_token = ""
	_token_expires_at = 0


# Parses the raw AWS JSON body and returns a dictionary when the payload is valid.
func _parse_response(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


# Routes a failure to the correct signal so the UI shows the relevant status.
func _emit_failure(operation: String, message: String) -> void:
	match operation:
		"SignUp":
			registration_failed.emit(message)
		"ConfirmSignUp":
			confirmation_failed.emit(message)
		"ResendConfirmationCode":
			resend_failed.emit(message)
		"ForgotPassword":
			password_reset_code_failed.emit(message)
		"ConfirmForgotPassword":
			password_reset_failed.emit(message)
		"InitiateAuth":
			_clear_tokens()
			login_failed.emit(message)


# Maps raw Cognito error payloads such as UsernameExistsException and
# CodeMismatchException into friendly UI messages without leaking sensitive data.
func _error_message(operation: String, response_data: Dictionary) -> String:
	var error_type := str(response_data.get("__type", response_data.get("code", "")))
	var cognito_message := str(response_data.get("message", response_data.get("Message", ""))).to_lower()
	if error_type.contains("#"):
		error_type = error_type.get_slice("#", error_type.get_slice_count("#") - 1)
	if error_type.contains(":"):
		error_type = error_type.get_slice(":", 0)

	if operation == "ConfirmSignUp" \
			and error_type == "NotAuthorizedException" \
			and (cognito_message.contains("already confirmed") or cognito_message.contains("current status is confirmed")):
		return "This account has already been verified. You can sign in."

	match error_type:
		"UsernameExistsException":
			return "An account with that username already exists."
		"AliasExistsException":
			return "An account is already registered with that email address."
		"InvalidPasswordException":
			if operation == "ConfirmForgotPassword":
				return "The new password does not meet the user pool requirements."
			return "Password does not meet the user pool requirements."
		"PasswordHistoryPolicyViolationException":
			return "Choose a new password that you have not used before."
		"InvalidParameterException":
			if operation == "InitiateAuth":
				return "Cognito rejected the login request. Confirm USER_PASSWORD_AUTH is enabled for this app client."
			if operation == "ConfirmForgotPassword":
				return "Cognito rejected the password reset details. Check the code and try again."
			return "Cognito rejected one or more account details. Check the fields and try again."
		"CodeMismatchException":
			if operation == "ConfirmForgotPassword":
				return "The password reset code is incorrect."
			return "The verification code is incorrect."
		"ExpiredCodeException":
			if operation == "ConfirmForgotPassword":
				return "The password reset code has expired. Request a new one."
			return "The verification code has expired. Request a new code."
		"UserNotFoundException":
			if operation == "InitiateAuth":
				return "Incorrect username/email or password."
			return "No account was found for that username."
		"UserNotConfirmedException":
			return "This account still needs email verification."
		"UserAlreadyConfirmedException":
			return "This account has already been verified. You can sign in."
		"NotAuthorizedException":
			if operation == "InitiateAuth":
				return "Incorrect username/email or password."
			if operation == "ConfirmForgotPassword":
				return "Cognito could not complete the password reset. Request a new code and try again."
			if operation == "ForgotPassword":
				return "Cognito could not start a reset for this account. Check its status and verified contact method."
			return "Cognito could not authorize this request. Check the username and account status."
		"UserNotEnabledException":
			return "This account is disabled. Contact the account administrator."
		"PasswordResetRequiredException":
			return "This account must reset its password before signing in."
		"AuthFlowNotSupportedException":
			return "USER_PASSWORD_AUTH is not enabled for this Cognito app client."
		"CodeDeliveryFailureException":
			if operation == "ForgotPassword":
				return "Cognito could not deliver the password reset code. Check the verified email on the account."
			return "Cognito could not send the verification code."
		"LimitExceededException", "TooManyRequestsException":
			return "Too many requests. Wait a while and try again."
		"TooManyFailedAttemptsException":
			if operation == "ConfirmForgotPassword":
				return "Too many failed reset attempts. Request a new code or wait before trying again."
			return "Too many failed attempts. Wait a while before trying again."
		_:
			match operation:
				"InitiateAuth":
					return "Cognito could not complete sign-in. Check your connection and account, then try again."
				"ForgotPassword":
					return "Cognito could not send a password reset code. Check the username/email and try again."
				"ConfirmForgotPassword":
					return "Cognito could not reset the password. Check the code and new password, then try again."
				"SignUp":
					return "Cognito could not complete registration. Check the account details and try again."
				"ConfirmSignUp":
					return "Cognito could not verify this account. Check the username and code, then try again."
				"ResendConfirmationCode":
					return "Cognito could not resend the verification code. Check the username and try again."
	return "Cognito could not complete the request. Try again."
