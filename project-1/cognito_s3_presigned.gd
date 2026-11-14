extends Control

@onready var login_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer
@onready var register_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer
@onready var verification_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer
@onready var password_reset_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer
@onready var game_profile_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer

@onready var login_identifier_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/UsernameOrEmailField
@onready var login_password_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/LoginPasswordField
@onready var login_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/LoginStatus
@onready var login_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/LoginButton
@onready var create_new_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/LoginLinks/CreateNewButton
@onready var forgot_password_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer/LoginCenter/LoginForm/LoginLinks/ForgotPasswordButton

@onready var register_username_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterUsernameField
@onready var register_email_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterEmailField
@onready var register_password_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterPasswordField
@onready var confirm_password_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/ConfirmPasswordField
@onready var register_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterStatus
@onready var create_account_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/CreateAccountButton
@onready var register_back_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterLinks/RegisterBackToLoginButton
@onready var go_to_verification_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer/RegisterCenter/RegisterForm/RegisterLinks/GoToVerificationButton

@onready var verification_code_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationCodeField
@onready var verification_username_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationUsernameField
@onready var verification_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationStatus
@onready var verify_email_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerifyEmailButton
@onready var resend_code_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationActions/ResendCodeButton
@onready var verification_back_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationActions/VerificationBackToLoginButton

@onready var password_reset_username_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/PasswordResetUsernameField
@onready var password_reset_code_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/PasswordResetCodeField
@onready var new_password_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/NewPasswordField
@onready var confirm_new_password_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/ConfirmNewPasswordField
@onready var send_reset_code_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/SendResetCodeButton
@onready var reset_password_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/ResetPasswordButton
@onready var password_reset_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/PasswordResetStatus
@onready var password_reset_back_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/PasswordResetContainer/PasswordResetCenter/PasswordResetForm/PasswordResetBackToLoginButton

@onready var save_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileActions/SaveToAwsButton
@onready var load_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileActions/LoadFromAwsButton
@onready var logout_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/LogOutButton
@onready var profile_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ServerStatusSection/ServerStatusMessage
@onready var profile_username_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileFields/ProfileUsernameRow/ProfileUsernameField
@onready var level_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileFields/LevelRow/LevelField
@onready var coins_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileFields/CoinsRow/CoinsField
@onready var high_score_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileFields/HighScoreRow/HighScoreField
@onready var games_played_field: LineEdit = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileFields/GamesPlayedRow/GamesPlayedField

var active_status_label: Label
var pending_username := ""


func _ready() -> void:
	$ProjectScroll/ProjectMargin/ProjectContent/BackToLobbyButton.pressed.connect(_back_to_lobby)
	login_button.pressed.connect(_on_login_pressed)
	create_new_button.pressed.connect(_show_register)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	create_account_button.pressed.connect(_on_create_account_pressed)
	register_back_button.pressed.connect(_show_login)
	go_to_verification_button.pressed.connect(_show_verification)
	verify_email_button.pressed.connect(_on_verify_email_pressed)
	resend_code_button.pressed.connect(_on_resend_code_pressed)
	verification_back_button.pressed.connect(_show_login)
	send_reset_code_button.pressed.connect(_on_send_reset_code_pressed)
	reset_password_button.pressed.connect(_on_reset_password_pressed)
	password_reset_back_button.pressed.connect(_show_login)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	logout_button.pressed.connect(_on_logout_pressed)

	var auth := $CognitoAuth
	var cloud_save := $CloudSaveService
	auth.connect("operation_started", _on_auth_operation_started)
	auth.connect("operation_finished", _on_auth_operation_finished)
	auth.connect("registration_accepted", _on_registration_accepted)
	auth.connect("registration_failed", _on_registration_failed)
	auth.connect("confirmation_succeeded", _on_confirmation_succeeded)
	auth.connect("confirmation_failed", _on_confirmation_failed)
	auth.connect("resend_succeeded", _on_resend_succeeded)
	auth.connect("resend_failed", _on_resend_failed)
	auth.connect("login_succeeded", _on_login_succeeded)
	auth.connect("login_failed", _on_login_failed)
	auth.connect("password_reset_code_sent", _on_password_reset_code_sent)
	auth.connect("password_reset_code_failed", _on_password_reset_code_failed)
	auth.connect("password_reset_succeeded", _on_password_reset_succeeded)
	auth.connect("password_reset_failed", _on_password_reset_failed)
	cloud_save.connect("operation_started", _on_cloud_operation_started)
	cloud_save.connect("operation_finished", _on_cloud_operation_finished)
	cloud_save.connect("progress_updated", _on_cloud_progress_updated)
	cloud_save.connect("operation_succeeded", _on_cloud_operation_succeeded)
	cloud_save.connect("operation_failed", _on_cloud_operation_failed)

	_show_login()


func _show_login() -> void:
	login_container.show()
	register_container.hide()
	verification_container.hide()
	password_reset_container.hide()
	game_profile_container.hide()
	active_status_label = login_status


func _show_register() -> void:
	login_container.hide()
	register_container.show()
	verification_container.hide()
	password_reset_container.hide()
	game_profile_container.hide()
	active_status_label = register_status


func _show_verification() -> void:
	login_container.hide()
	register_container.hide()
	verification_container.show()
	password_reset_container.hide()
	game_profile_container.hide()
	active_status_label = verification_status
	verification_username_field.text = pending_username
	verification_username_field.editable = pending_username.is_empty()
	if pending_username.is_empty():
		_set_status("Enter your Cognito username to verify your email or request another code.")
	else:
		_set_status("")


func _show_password_reset() -> void:
	login_container.hide()
	register_container.hide()
	verification_container.hide()
	password_reset_container.show()
	game_profile_container.hide()
	active_status_label = password_reset_status


func _show_game_profile() -> void:
	login_container.hide()
	register_container.hide()
	verification_container.hide()
	password_reset_container.hide()
	game_profile_container.show()
	active_status_label = profile_status


func _on_login_pressed() -> void:
	var username := login_identifier_field.text.strip_edges()
	if username.is_empty() or login_password_field.text.is_empty():
		_set_status("Enter your username or email and password.")
		return

	var password := login_password_field.text
	login_password_field.clear()
	login_button.disabled = true
	var request_error: int = $CognitoAuth.call("initiate_password_auth", username, password)
	if request_error != OK:
		login_button.disabled = false
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Signing in with Cognito...")


func _on_login_succeeded(username: String) -> void:
	profile_username_field.text = "" if username.contains("@") else username
	_show_game_profile()
	_on_load_pressed()


func _on_login_failed(message: String) -> void:
	_set_status(message)


func _on_forgot_password_pressed() -> void:
	password_reset_username_field.text = login_identifier_field.text.strip_edges()
	password_reset_code_field.clear()
	new_password_field.clear()
	confirm_new_password_field.clear()
	_show_password_reset()
	_set_status("")


func _on_send_reset_code_pressed() -> void:
	var username := password_reset_username_field.text.strip_edges()
	if username.is_empty():
		_set_status("Enter your username or email address.")
		return

	var request_error: int = $CognitoAuth.call("forgot_password", username)
	if request_error != OK:
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Requesting a password reset code from Cognito...")


func _on_reset_password_pressed() -> void:
	var username := password_reset_username_field.text.strip_edges()
	var confirmation_code := password_reset_code_field.text.strip_edges()
	var new_password := new_password_field.text
	var confirmed_password := confirm_new_password_field.text
	if username.is_empty() or confirmation_code.is_empty() \
			or new_password.is_empty() or confirmed_password.is_empty():
		_set_status("Complete all fields to reset your password.")
		return
	if new_password != confirmed_password:
		_set_status("New passwords do not match.")
		return

	var request_error: int = $CognitoAuth.call(
		"confirm_forgot_password",
		username,
		confirmation_code,
		new_password
	)
	if request_error != OK:
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Resetting your password with Cognito...")


func _on_password_reset_code_sent(username: String, message: String) -> void:
	password_reset_username_field.text = username
	_set_status(message)


func _on_password_reset_code_failed(message: String) -> void:
	_set_status(message)


func _on_password_reset_succeeded(username: String) -> void:
	password_reset_code_field.clear()
	new_password_field.clear()
	confirm_new_password_field.clear()
	login_identifier_field.text = username
	login_password_field.clear()
	_show_login()
	_set_status("Password reset successfully. Sign in with your new password.")


func _on_password_reset_failed(message: String) -> void:
	_set_status(message)


func _on_create_account_pressed() -> void:
	if register_username_field.text.strip_edges().is_empty() \
			or register_email_field.text.strip_edges().is_empty() \
			or register_password_field.text.is_empty() \
			or confirm_password_field.text.is_empty():
		_set_status("Complete all fields to create an account.")
		return

	var username := register_username_field.text.strip_edges()
	var email := register_email_field.text.strip_edges()
	if not _is_valid_email(email):
		_set_status("Enter a valid email address.")
		return

	if register_password_field.text != confirm_password_field.text:
		_set_status("Passwords do not match.")
		return

	var password := register_password_field.text
	register_password_field.clear()
	confirm_password_field.clear()
	create_account_button.disabled = true
	var request_error: int = $CognitoAuth.call("sign_up", username, email, password)
	password = ""
	if request_error != OK:
		create_account_button.disabled = false
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Sending registration request to Cognito...")


func _is_valid_email(email: String) -> bool:
	var email_parts := email.split("@", false)
	if email_parts.size() != 2 \
			or email.contains(" ") \
			or email.contains("\t") \
			or email.contains("\n") \
			or email.contains("\r"):
		return false

	var local_part: String = email_parts[0]
	var domain_parts := email_parts[1].split(".", false)
	if local_part.is_empty() or domain_parts.size() < 2:
		return false

	for part in domain_parts:
		if part.is_empty():
			return false

	return true


func _on_verify_email_pressed() -> void:
	var username := _get_verification_username()
	var confirmation_code := verification_code_field.text.strip_edges()
	if username.is_empty():
		_set_status("Enter your Cognito username before verifying your email.")
		return
	if confirmation_code.is_empty():
		_set_status("Enter the verification code.")
		return

	pending_username = username
	verification_username_field.text = username
	verification_username_field.editable = false
	verify_email_button.disabled = true
	var request_error: int = $CognitoAuth.call("confirm_sign_up", username, confirmation_code)
	confirmation_code = ""
	if request_error != OK:
		verify_email_button.disabled = false
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Verifying your email with Cognito...")


func _on_resend_code_pressed() -> void:
	var username := _get_verification_username()
	if username.is_empty():
		_set_status("Enter your Cognito username before requesting a verification code.")
		return

	pending_username = username
	verification_username_field.text = username
	verification_username_field.editable = false
	resend_code_button.disabled = true
	var request_error: int = $CognitoAuth.call("resend_confirmation_code", username)
	if request_error != OK:
		resend_code_button.disabled = false
		_set_status(_request_start_error(request_error))
	else:
		_set_status("Requesting a new verification code...")


func _get_verification_username() -> String:
	if not pending_username.is_empty():
		return pending_username
	return verification_username_field.text.strip_edges()


func _on_auth_operation_started(_operation: String) -> void:
	login_button.disabled = true
	create_account_button.disabled = true
	verify_email_button.disabled = true
	resend_code_button.disabled = true
	send_reset_code_button.disabled = true
	reset_password_button.disabled = true


func _on_auth_operation_finished(_operation: String) -> void:
	login_button.disabled = false
	create_account_button.disabled = false
	verify_email_button.disabled = false
	resend_code_button.disabled = false
	send_reset_code_button.disabled = false
	reset_password_button.disabled = false


func _on_registration_accepted(username: String, message: String) -> void:
	pending_username = username
	login_identifier_field.text = username
	profile_username_field.text = username
	_show_verification()
	_set_status(message)


func _on_registration_failed(message: String) -> void:
	_set_status(message)


func _on_confirmation_succeeded() -> void:
	if not pending_username.is_empty():
		login_identifier_field.text = pending_username
		profile_username_field.text = pending_username
	_show_login()
	_set_status("Email verified. You can now sign in.")


func _on_confirmation_failed(message: String) -> void:
	_set_status(message)


func _on_resend_succeeded(message: String) -> void:
	_set_status(message)


func _on_resend_failed(message: String) -> void:
	_set_status(message)


func _request_start_error(error: int) -> String:
	if error == ERR_BUSY:
		return "A Cognito request is already in progress. Please wait."
	return "Could not start the Cognito request. Try again."


func _on_save_pressed() -> void:
	var access_token := _get_access_token_for_cloud()
	if access_token.is_empty():
		return

	var username := profile_username_field.text.strip_edges()
	if username.is_empty():
		_set_status("Username cannot be empty.")
		return

	var level := _profile_integer(level_field, "Level")
	var coins := _profile_integer(coins_field, "Coins")
	var high_score := _profile_integer(high_score_field, "High Score")
	var games_played := _profile_integer(games_played_field, "Games Played")
	if level < 0 or coins < 0 or high_score < 0 or games_played < 0:
		return

	var save_data := {
		"schema_version": 1,
		"username": username,
		"level": level,
		"coins": coins,
		"high_score": high_score,
		"games_played": games_played,
	}
	var request_error: int = $CloudSaveService.call("save_player_data", access_token, save_data)
	if request_error != OK:
		_set_status(_cloud_request_start_error(request_error))


func _on_load_pressed() -> void:
	var access_token := _get_access_token_for_cloud()
	if access_token.is_empty():
		return

	var request_error: int = $CloudSaveService.call("load_player_data", access_token)
	if request_error != OK:
		_set_status(_cloud_request_start_error(request_error))


func _on_logout_pressed() -> void:
	$CognitoAuth.call("logout")
	login_password_field.clear()
	_show_login()
	_set_status("You have been signed out.")


func _get_access_token_for_cloud() -> String:
	var access_token := str($CognitoAuth.call("get_valid_access_token"))
	if access_token.is_empty():
		$CognitoAuth.call("logout")
		_show_login()
		_set_status("Your session has expired. Please log in again.")
	return access_token


func _profile_integer(field: LineEdit, label: String) -> int:
	var value := field.text.strip_edges()
	if not value.is_valid_int():
		_set_status("%s must be a whole number." % label)
		return -1
	var parsed_value := value.to_int()
	if parsed_value < 0 or parsed_value > 2147483647:
		_set_status("%s must be between 0 and 2147483647." % label)
		return -1
	return parsed_value


func _on_cloud_operation_started(_operation: String) -> void:
	save_button.disabled = true
	load_button.disabled = true
	logout_button.disabled = true


func _on_cloud_operation_finished(_operation: String) -> void:
	save_button.disabled = false
	load_button.disabled = false
	logout_button.disabled = false


func _on_cloud_progress_updated(message: String) -> void:
	profile_status.text = message


func _on_cloud_operation_succeeded(
	operation: String,
	message: String,
	save_data: Dictionary
) -> void:
	if operation == "load":
		if save_data.has("username"):
			profile_username_field.text = save_data["username"]
		level_field.text = str(save_data["level"])
		coins_field.text = str(save_data["coins"])
		high_score_field.text = str(save_data["high_score"])
		games_played_field.text = str(save_data["games_played"])
	profile_status.text = message


func _on_cloud_operation_failed(message: String, requires_login: bool) -> void:
	if requires_login:
		$CognitoAuth.call("logout")
		_show_login()
		_set_status(message)
		return
	profile_status.text = message


func _cloud_request_start_error(error: int) -> String:
	if error == ERR_BUSY:
		return "A cloud save operation is already in progress. Please wait."
	if error == ERR_UNAUTHORIZED:
		return "Your authentication has expired. Please log in again."
	if error == ERR_INVALID_DATA:
		return "The player profile contains invalid save data."
	return "Could not start the cloud save operation. Try again."


func _set_status(message: String) -> void:
	if is_instance_valid(active_status_label):
		active_status_label.text = message


func _back_to_lobby() -> void:
	var error := get_tree().change_scene_to_file("res://Main.tscn")
	if error != OK:
		push_error("Could not return to the lobby (error %d)." % error)
