extends Label


var level := 1
var line_left := 0
var training_mode := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.line_clear.connect(_on_line_clear)
	EventBus.level_up.connect(_on_level_up)
	EventBus.init_game.connect(_on_game_init)


func _on_line_clear(line_left_: int) -> void:
	line_left = line_left_
	if training_mode:
		text = "Level " + str(level)
	else:
		text = "Level " + str(level) + " :\n" + str(line_left) + " lines left"

func _on_level_up(new_level: int) -> void:
	level = new_level
	if training_mode:
		text = "Level "
	else:
		text = "Level " + str(level) + " :\n" + str(line_left) + " lines left"

func _on_game_init(new_level: int, training_mode_: bool) -> void:
	level = new_level
	line_left = 10 * level 
	if training_mode_:
		training_mode = true
	
	_on_level_up(level)
