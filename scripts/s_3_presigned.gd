extends Control

@onready var status_message: Label = $ProjectScroll/ProjectMargin/ProjectContent/ServerStatusSection/StatusMessage


func _ready() -> void:
	$ProjectScroll/ProjectMargin/ProjectContent/BackToLobbyButton.pressed.connect(_back_to_lobby)
	$ProjectScroll/ProjectMargin/ProjectContent/PlayerLoginSection/LoginActions/LogInButton.pressed.connect(
		_set_status.bind("Authentication is not implemented yet.")
	)
	$ProjectScroll/ProjectMargin/ProjectContent/PlayerLoginSection/LoginActions/RegisterButton.pressed.connect(
		_set_status.bind("Registration is not implemented yet.")
	)
	$ProjectScroll/ProjectMargin/ProjectContent/AwsActions/SaveToAwsButton.pressed.connect(
		_set_status.bind("AWS saving is not implemented yet.")
	)
	$ProjectScroll/ProjectMargin/ProjectContent/AwsActions/LoadFromAwsButton.pressed.connect(
		_set_status.bind("AWS loading is not implemented yet.")
	)


func _set_status(message: String) -> void:
	status_message.text = message


func _back_to_lobby() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/Main.tscn")
	if error != OK:
		push_error("Could not return to the lobby (error %d)." % error)
