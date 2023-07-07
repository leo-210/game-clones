extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.score_up.connect(_on_score_up)


func _on_score_up(score: int) -> void:
	text = "Score :\n" + str(score)
