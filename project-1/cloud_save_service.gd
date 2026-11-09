extends Node

signal operation_started(operation: String)
signal operation_finished(operation: String)
signal progress_updated(message: String)
signal operation_succeeded(operation: String, message: String, save_data: Dictionary)
signal operation_failed(message: String, requires_login: bool)

const API_ENDPOINT := "https://29xudoj1ra.execute-api.eu-north-1.amazonaws.com/presigned-url"
const MAX_PROFILE_VALUE := 2147483647

var _gateway_request: HTTPRequest
var _s3_request: HTTPRequest
var _operation := ""
var _expected_s3_method := ""
var _presigned_url := ""
var _pending_save_data: Dictionary = {}


func _ready() -> void:
	_gateway_request = HTTPRequest.new()
	_gateway_request.name = "ApiGatewayHTTPRequest"
	_gateway_request.timeout = 20.0
	add_child(_gateway_request)
	_gateway_request.request_completed.connect(_on_gateway_request_completed)

	_s3_request = HTTPRequest.new()
	_s3_request.name = "S3HTTPRequest"
	_s3_request.timeout = 30.0
	add_child(_s3_request)
	_s3_request.request_completed.connect(_on_s3_request_completed)


func is_busy() -> bool:
	return not _operation.is_empty()


func save_player_data(access_token: String, save_data: Dictionary) -> Error:
	return _start_operation("save", access_token, save_data)


func load_player_data(access_token: String) -> Error:
	return _start_operation("load", access_token, {})


func _start_operation(operation: String, access_token: String, save_data: Dictionary) -> Error:
	if is_busy():
		return ERR_BUSY
	if access_token.is_empty():
		return ERR_UNAUTHORIZED
	if operation == "save" and not _is_valid_save_data(save_data):
		return ERR_INVALID_DATA

	_operation = operation
	_pending_save_data = save_data
	var action := "upload" if operation == "save" else "download"
	var headers := PackedStringArray([
		"Authorization: Bearer %s" % access_token,
		"Content-Type: application/json",
	])
	var request_error := _gateway_request.request(
		API_ENDPOINT,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({"action": action})
	)
	if request_error != OK:
		_reset_operation()
		return request_error

	operation_started.emit(operation)
	progress_updated.emit("Requesting %s URL..." % ("upload" if operation == "save" else "download"))
	return OK


func _on_gateway_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _operation.is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail_operation("Could not reach the cloud save service. Check your connection and try again.")
		return
	if response_code == 401 or response_code == 403:
		_fail_operation("Your authentication has expired or is invalid. Please log in again.", true)
		return
	if response_code < 200 or response_code >= 300:
		_fail_operation("The cloud save service could not provide a download URL." if _operation == "load" else "The cloud save service could not provide an upload URL.")
		return

	var response_data := _parse_json_dictionary(body)
	var url_value: Variant = response_data.get("url", "")
	var method_value: Variant = response_data.get("method", "")
	var expected_method := "PUT" if _operation == "save" else "GET"
	if not url_value is String or not method_value is String:
		_fail_operation("The cloud save service returned an invalid response.")
		return
	_presigned_url = url_value
	if not _is_https_url(_presigned_url) or method_value.to_upper() != expected_method:
		_fail_operation("The cloud save service returned an invalid transfer URL.")
		return

	_expected_s3_method = expected_method
	if _operation == "save":
		progress_updated.emit("Uploading player data...")
		_start_s3_request(
			HTTPClient.METHOD_PUT,
			PackedStringArray(["Content-Type: application/json"]),
			JSON.stringify(_pending_save_data)
		)
	else:
		progress_updated.emit("Downloading player data...")
		_start_s3_request(HTTPClient.METHOD_GET, PackedStringArray(), "")


func _start_s3_request(
	method: HTTPClient.Method,
	headers: PackedStringArray,
	request_body: String
) -> void:
	var request_error := _s3_request.request(_presigned_url, headers, method, request_body)
	if request_error != OK:
		_fail_operation("Could not start the S3 transfer. Please try again.")


func _on_s3_request_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _operation.is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail_operation("The S3 transfer failed. Check your connection and try again.")
		return
	if _operation == "load" and response_code == 404:
		_fail_operation("No cloud save found yet. Save your profile to create one.")
		return
	if response_code == 403:
		_fail_operation("The presigned S3 URL expired or was rejected. Please try again.")
		return
	if response_code < 200 or response_code >= 300:
		_fail_operation("The S3 transfer failed. Please try again.")
		return

	if _expected_s3_method == "PUT":
		_complete_operation("Cloud save completed successfully.")
		return

	var downloaded_data := _parse_json_dictionary(body)
	if downloaded_data.is_empty():
		_fail_operation("The cloud save is empty or contains invalid JSON.")
		return
	var validated_data := _validate_downloaded_save(downloaded_data)
	if validated_data.is_empty():
		_fail_operation("The cloud save is missing valid profile fields. Your current profile was not changed.")
		return
	_complete_operation("Cloud data loaded successfully.", validated_data)


func _validate_downloaded_save(save_data: Dictionary) -> Dictionary:
	if not save_data.has("schema_version") or not _is_nonnegative_integer(save_data["schema_version"]):
		return {}
	if int(save_data["schema_version"]) != 1:
		return {}

	var validated := {"schema_version": 1}
	for field in ["level", "coins", "high_score", "games_played"]:
		if not save_data.has(field) or not _is_nonnegative_integer(save_data[field]):
			return {}
		validated[field] = int(save_data[field])
	return validated


func _is_valid_save_data(save_data: Dictionary) -> bool:
	if save_data.get("schema_version") != 1:
		return false
	for field in ["level", "coins", "high_score", "games_played"]:
		if not save_data.has(field) or not _is_nonnegative_integer(save_data[field]):
			return false
	return true


func _is_nonnegative_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return value >= 0 and value <= MAX_PROFILE_VALUE
	if typeof(value) == TYPE_FLOAT:
		return is_finite(value) \
				and value >= 0.0 \
				and value <= MAX_PROFILE_VALUE \
				and floor(value) == value
	return false


func _parse_json_dictionary(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {}
	return json.data


func _is_https_url(url: String) -> bool:
	return url.begins_with("https://") and not url.contains("\n") and not url.contains("\r")


func _complete_operation(message: String, save_data: Dictionary = {}) -> void:
	var completed_operation := _operation
	_reset_operation()
	operation_succeeded.emit(completed_operation, message, save_data)
	operation_finished.emit(completed_operation)


func _fail_operation(message: String, requires_login: bool = false) -> void:
	var completed_operation := _operation
	_reset_operation()
	operation_failed.emit(message, requires_login)
	operation_finished.emit(completed_operation)


func _reset_operation() -> void:
	_operation = ""
	_expected_s3_method = ""
	_presigned_url = ""
	_pending_save_data.clear()
