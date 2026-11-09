extends Node

signal operation_started(operation: String)
signal operation_finished(operation: String)
signal registration_accepted(username: String, message: String)
signal registration_failed(message: String)
signal confirmation_succeeded
signal confirmation_failed(message: String)
signal resend_succeeded(message: String)
signal resend_failed(message: String)

const COGNITO_ENDPOINT := "https://cognito-idp.eu-north-1.amazonaws.com/"
const CLIENT_ID := "39enqqncspu5ishknb9t9bdhv0"
const CONTENT_TYPE := "application/x-amz-json-1.1"

var _http_request: HTTPRequest
var _operation := ""
var _request_username := ""
var _request_in_progress := false


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

	operation_finished.emit(completed_operation)


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
			return "Cognito rejected one or more account details. Check the fields and try again."
		"CodeMismatchException":
			return "The verification code is incorrect."
		"ExpiredCodeException":
			return "The verification code has expired. Request a new code."
		"UserNotFoundException":
			return "No account was found for that username."
		"UserNotConfirmedException":
			return "This account still needs email verification."
		"UserAlreadyConfirmedException":
			return "This account has already been verified. You can sign in."
		"NotAuthorizedException":
			return "Cognito could not authorize this request. Check the username and account status."
		"CodeDeliveryFailureException":
			return "Cognito could not send the verification code."
		"LimitExceededException", "TooManyRequestsException":
			return "Too many requests. Wait a while and try again."
		_:
			match operation:
				"SignUp":
					return "Cognito could not complete registration. Check the account details and try again."
				"ConfirmSignUp":
					return "Cognito could not verify this account. Check the username and code, then try again."
				"ResendConfirmationCode":
					return "Cognito could not resend the verification code. Check the username and try again."
	return "Cognito could not complete the request. Try again."
