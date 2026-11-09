extends Control

@onready var login_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/LoginContainer
@onready var register_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/RegisterContainer
@onready var verification_container: VBoxContainer = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer
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
@onready var verification_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationStatus
@onready var verify_email_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerifyEmailButton
@onready var resend_code_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationActions/ResendCodeButton
@onready var verification_back_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/VerificationContainer/VerificationCenter/VerificationForm/VerificationActions/VerificationBackToLoginButton

@onready var save_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileActions/SaveToAwsButton
@onready var load_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ProfileActions/LoadFromAwsButton
@onready var logout_button: Button = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/LogOutButton
@onready var profile_status: Label = $ProjectScroll/ProjectMargin/ProjectContent/GameProfileContainer/ServerStatusSection/ServerStatusMessage

var active_status_label: Label


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
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	logout_button.pressed.connect(_on_logout_pressed)

	_show_login()


func _show_login() -> void:
	login_container.show()
	register_container.hide()
	verification_container.hide()
	game_profile_container.hide()
	active_status_label = login_status


func _show_register() -> void:
	login_container.hide()
	register_container.show()
	verification_container.hide()
	game_profile_container.hide()
	active_status_label = register_status


func _show_verification() -> void:
	login_container.hide()
	register_container.hide()
	verification_container.show()
	game_profile_container.hide()
	active_status_label = verification_status
	_set_status("Email verification is not implemented yet.")


func _show_game_profile() -> void:
	login_container.hide()
	register_container.hide()
	verification_container.hide()
	game_profile_container.show()
	active_status_label = profile_status


func _on_login_pressed() -> void:
	_set_status("Authentication is not implemented yet.")


func _on_forgot_password_pressed() -> void:
	_set_status("Password reset is not implemented yet.")


func _on_create_account_pressed() -> void:
	if register_username_field.text.strip_edges().is_empty() \
			or register_email_field.text.strip_edges().is_empty() \
			or register_password_field.text.is_empty() \
			or confirm_password_field.text.is_empty():
		_set_status("Complete all fields to create an account.")
		return

	if not _is_valid_email(register_email_field.text.strip_edges()):
		_set_status("Enter a valid email address.")
		return

	if register_password_field.text != confirm_password_field.text:
		_set_status("Passwords do not match.")
		return

	_set_status("Registration is not implemented yet.")


func _is_valid_email(email: String) -> bool:
	var email_parts := email.split("@", false)
	if email_parts.size() != 2 or email.contains(" ") or email.contains("\t"):
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
	_set_status("Email verification is not implemented yet.")


func _on_resend_code_pressed() -> void:
	_set_status("Resending a verification code is not implemented yet.")


func _on_save_pressed() -> void:
	_set_status("AWS saving is not implemented yet.")


func _on_load_pressed() -> void:
	_set_status("AWS loading is not implemented yet.")


func _on_logout_pressed() -> void:
	_show_login()
	_set_status("Sign out is not implemented yet.")


func _set_status(message: String) -> void:
	if is_instance_valid(active_status_label):
		active_status_label.text = message


func _back_to_lobby() -> void:
	var error := get_tree().change_scene_to_file("res://Main.tscn")
	if error != OK:
		push_error("Could not return to the lobby (error %d)." % error)
