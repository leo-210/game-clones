extends Control


@onready var spin_box: SpinBox = $LevelSelection/VBoxContainer/MarginContainer2/VBoxContainer/SpinBox
@onready var check_box: CheckBox = $LevelSelection/VBoxContainer/MarginContainer2/VBoxContainer/CheckBox
@onready var game_container: CenterContainer = $GameContainer
@onready var level_selection: CenterContainer = $LevelSelection
@onready var button_panel: MarginContainer = $GameContainer/VBoxContainer/ButtonPanel


func _ready() -> void:
	game_container.hide()
	level_selection.show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_start_game_pressed() -> void:
	level_selection.hide()
	game_container.show()
	
	if check_box.button_pressed:
		button_panel.show()
	else:
		button_panel.hide()
	
	EventBus.init_game.emit(int(spin_box.value))
