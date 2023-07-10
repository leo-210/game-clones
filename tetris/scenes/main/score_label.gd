extends Label


var game_over := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.score_up.connect(_on_score_up)
	EventBus.game_over.connect(func (_score: int) -> void: game_over = true)


func _on_score_up(score: int) -> void:
	if game_over:
		return
	text = "Score :\n" + str(score)
