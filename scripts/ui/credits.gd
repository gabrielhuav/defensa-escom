class_name Credits
extends Control
## "Créditos": the team, the course and the engine. It opens from Inicio and
## from Ajustes; "Volver" and the Android back button return to the screen
## that opened it (back_scene). "Política de privacidad" opens the policy
## page in the browser (Google Play asks for a link inside the app).

const CREDITS_SCENE := "res://scenes/ui/credits.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings.tscn"
const PRIVACY_URL := "https://gabrielhuav.github.io/defensa-escom/privacidad/"

## Screen that opened the credits. The caller sets it before changing scene.
static var back_scene := MAIN_MENU_SCENE

@onready var back_button: Button = %BackButton
@onready var privacy_button: Button = %PrivacyButton


func _ready() -> void:
	AudioManager.play_music(AudioManager.MENU_MUSIC)  # it keeps playing if it already was
	back_button.pressed.connect(_go_back)
	privacy_button.pressed.connect(_open_privacy_policy)


func _open_privacy_policy() -> void:
	OS.shell_open(PRIVACY_URL)


func _go_back() -> void:
	SceneTransition.change_scene(back_scene)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_back()
