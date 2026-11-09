extends Node

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

const COGNITO_ENDPOINT := "https://cognito-idp.eu-north-1.amazonaws.com/"
const CLIENT_ID := "39enqqncspu5ishknb9t9bdhv0"
const CONTENT_TYPE := "application/x-amz-json-1.1"

var _http_request: HTTPRequest
var _operation := ""
var _request_username := ""
var _request_in_progress := false
var _access_token := ""
var _id_token := ""
var _refresh_token := ""
var _token_expires_at := 0


func _ready() -> void:
	_http_request = HTTPRequest.new()
	_http_request.name = "CognitoHTTPRequest"
	_http_request.timeout = 20.0
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


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


func confirm_sign_up(username: String, confirmation_code: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
		"ConfirmationCode": confirmation_code,
	}
	return _send_request("ConfirmSignUp", username, payload)


func resend_confirmation_code(username: String) -> Error:
	var payload := {
		"ClientId": CLIENT_ID,
		"Username": username,
	}
	return _send_request("ResendConfirmationCode", username, payload)


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


func get_valid_access_token() -> String:
	if _access_token.is_empty():
		return ""
	if int(Time.get_unix_time_from_system()) >= _token_expires_at:
		_clear_tokens()
		return ""
	return _access_token


func logout() -> void:
	_clear_tokens()


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
		"InitiateAuth":
			_handle_authentication_response(completed_username, response_data)

	operation_finished.emit(completed_operation)


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


func _clear_tokens() -> void:
	_access_token = ""
	_id_token = ""
	_refresh_token = ""
	_token_expires_at = 0


func _parse_response(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


func _emit_failure(operation: String, message: String) -> void:
	match operation:
		"SignUp":
			registration_failed.emit(message)
		"ConfirmSignUp":
			confirmation_failed.emit(message)
		"ResendConfirmationCode":
			resend_failed.emit(message)
		"InitiateAuth":
			_clear_tokens()
			login_failed.emit(message)


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
			return "Password does not meet the user pool requirements."
		"InvalidParameterException":
			if operation == "InitiateAuth":
				return "Cognito rejected the login request. Confirm USER_PASSWORD_AUTH is enabled for this app client."
			return "Cognito rejected one or more account details. Check the fields and try again."
		"CodeMismatchException":
			return "The verification code is incorrect."
		"ExpiredCodeException":
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
			return "Cognito could not authorize this request. Check the username and account status."
		"UserNotEnabledException":
			return "This account is disabled. Contact the account administrator."
		"PasswordResetRequiredException":
			return "This account must reset its password before signing in."
		"AuthFlowNotSupportedException":
			return "USER_PASSWORD_AUTH is not enabled for this Cognito app client."
		"CodeDeliveryFailureException":
			return "Cognito could not send the verification code."
		"LimitExceededException", "TooManyRequestsException":
			return "Too many requests. Wait a while and try again."
		_:
			match operation:
				"InitiateAuth":
					return "Cognito could not complete sign-in. Check your connection and account, then try again."
				"SignUp":
					return "Cognito could not complete registration. Check the account details and try again."
				"ConfirmSignUp":
					return "Cognito could not verify this account. Check the username and code, then try again."
				"ResendConfirmationCode":
					return "Cognito could not resend the verification code. Check the username and try again."
	return "Cognito could not complete the request. Try again."
