extends Control

const PROJECT_SCENES := [
	"res://scenes/S3Presigned.tscn",
	"res://scenes/ApiLambdaS3.tscn",
	"res://scenes/ApiLambdaDynamoDB.tscn",
]


func _ready() -> void:
	$LobbyScroll/LobbyMargin/LobbyCenter/LobbyContent/Project1Button.pressed.connect(
		_open_scene.bind(PROJECT_SCENES[0])
	)
	$LobbyScroll/LobbyMargin/LobbyCenter/LobbyContent/Project2Button.pressed.connect(
		_open_scene.bind(PROJECT_SCENES[1])
	)
	$LobbyScroll/LobbyMargin/LobbyCenter/LobbyContent/Project3Button.pressed.connect(
		_open_scene.bind(PROJECT_SCENES[2])
	)


func _open_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not open scene %s (error %d)." % [scene_path, error])
