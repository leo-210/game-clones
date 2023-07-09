extends Control


@onready var spin_box: SpinBox = $CenterContainer/VBoxContainer/MarginContainer2/SpinBox
@onready var h_box_container: HBoxContainer = $HBoxContainer
@onready var center_container: CenterContainer = $CenterContainer


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()




func _on_start_game_pressed() -> void:
	center_container.hide()
	h_box_container.show()
	EventBus.init_game.emit(int(spin_box.value))
