extends Control


@onready var spin_box: SpinBox = $StartScreen/VBoxContainer/GameConfig/MarginContainer2/VBoxContainer/SpinBox
@onready var check_box: CheckBox = $StartScreen/VBoxContainer/GameConfig/MarginContainer2/VBoxContainer/CheckBox
@onready var game_container: CenterContainer = $GameContainer
@onready var start_screen: CenterContainer = $StartScreen
@onready var button_panel: MarginContainer = $GameContainer/VBoxContainer/ButtonPanel
@onready var highscores: VBoxContainer = $StartScreen/VBoxContainer/MarginContainer/Highscores

@onready var highscores_label: Label = $StartScreen/VBoxContainer/HighscoresLabel
@onready var margin_container: MarginContainer = $StartScreen/VBoxContainer/MarginContainer

var config := ConfigFile.new()


func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	
	var err := config.load("user://config.cfg")
	
	if err != OK:
		print("hmm")
		config.set_value("game_config", "starting_level", 1)
		config.set_value("game_config", "button_controls", false)
		
		config.set_value("scores", "highscore_history", [])
		
		config.save("user://config.cfg")
	
	spin_box.value = config.get_value("game_config", "starting_level")
	print(config.get_value("game_config", "starting_level"))
	check_box.button_pressed = config.get_value("game_config", "button_controls", false)
	
	var highscore_history: Array = config.get_value("scores", "highscore_history", [])
	
	if len(highscore_history) == 0:
		highscores_label.hide()
		margin_container.hide()
	else:
		for i in range(min(len(highscore_history), 5)):
			var label: Label = highscores.get_child(i)
			
			label.show()
			label.text = highscore_history[i]["date"] + " - " + str(highscore_history[i]["score"])
	
	game_container.hide()
	start_screen.show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_start_game_pressed() -> void:
	start_screen.hide()
	game_container.show()
	
	if check_box.button_pressed:
		button_panel.show()
	else:
		button_panel.hide()
	
	config.set_value("game_config", "starting_level", int(spin_box.value))
	config.set_value("game_config", "button_controls", check_box.button_pressed)
	config.save("user://config.cfg")
	
	EventBus.init_game.emit(int(spin_box.value))


func _on_game_over(score: int) -> void:
	var date := Time.get_datetime_dict_from_system()
	var highscore_history: Array = config.get_value("scores", "highscore_history", [])
	
	highscore_history.append({
		"date": str(date["day"]) + "/" + str(date["month"]),
		"score": score
	})
	
	highscore_history.sort_custom(func (a, b) -> bool: return a["score"] > b["score"])
	
	config.set_value("game_config", "highscore_history", highscore_history)
	config.save("user://config.cfg")
