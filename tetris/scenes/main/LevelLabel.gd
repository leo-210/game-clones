extends Label


var level := 1
var line_left := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.line_clear.connect(_on_line_clear)
	EventBus.level_up.connect(_on_level_up)
	EventBus.init_game.connect(_on_level_up)


func _on_line_clear(line_left_: int) -> void:
	line_left = line_left_
	text = "Level " + str(level) + " :\n" + str(line_left) + " lines left"

func _on_level_up(new_level: int) -> void:
	level = new_level
	text = "Level " + str(level) + " :\n" + str(line_left) + " lines left"
