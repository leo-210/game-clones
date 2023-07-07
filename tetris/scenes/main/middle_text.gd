extends CenterContainer


@onready var level_up: PanelContainer = $VBoxContainer/LevelUp
@onready var combo: PanelContainer = $VBoxContainer/Combo
@onready var combo_label: Label = $VBoxContainer/Combo/Label
@onready var tetris: PanelContainer = $VBoxContainer/Tetris
@onready var back_to_back: Label = $VBoxContainer/Tetris/VBoxContainer/BackToBack
@onready var perfect_clear: PanelContainer = $VBoxContainer/PerfectClear
@onready var v_box_container: VBoxContainer = $VBoxContainer

@onready var tetris_tween: Tween
@onready var level_up_tween: Tween
@onready var combo_tween: Tween
@onready var perfect_clear_tween: Tween


func _ready() -> void:
	v_box_container.show()
	
	EventBus.level_up.connect(_on_level_up)
	EventBus.combo.connect(_on_combo)
	EventBus.tetris.connect(_on_tetris)
	EventBus.perfect_clear.connect(_on_perfect_clear)


func _on_tetris(back_to_back_: bool) -> void:
	v_box_container.move_child(tetris, 0)
	
	if back_to_back_:
		back_to_back.show()
	else:
		back_to_back.hide()
	
	tetris.show()
	tetris.modulate = Color.WHITE
	
	if tetris_tween:
		tetris_tween.kill()
	tetris_tween = create_tween()
	
	tetris_tween.tween_property(tetris, "modulate", Color.WHITE, 0.5)
	tetris_tween.tween_property(tetris, "modulate", Color.TRANSPARENT, 0.5)
	tetris_tween.tween_callback(func () -> void: tetris.hide())


func _on_level_up(_level) -> void:
	v_box_container.move_child(level_up, 0)
	
	level_up.show()
	level_up.modulate = Color.WHITE
	
	if level_up_tween:
		level_up_tween.kill()
	level_up_tween = create_tween()
	
	level_up_tween.tween_property(level_up, "modulate", Color.WHITE, 0.5)
	level_up_tween.tween_property(level_up, "modulate", Color.TRANSPARENT, 0.5)
	level_up_tween.tween_callback(func () -> void: level_up.hide())


func _on_combo(combo_: int) -> void:
	combo_label.text = "x" + str(combo_) + " Combo"
	v_box_container.move_child(level_up, 0)
	
	combo.show()
	combo.modulate = Color.WHITE
	
	if combo_tween:
		combo_tween.kill()
	combo_tween = create_tween()
	
	combo_tween.tween_property(combo, "modulate", Color.WHITE, 0.5)
	combo_tween.tween_property(combo, "modulate", Color.TRANSPARENT, 0.5)
	combo_tween.tween_callback(func () -> void: combo.hide())


func _on_perfect_clear() -> void:
	v_box_container.move_child(perfect_clear, 0)
	
	perfect_clear.show()
	perfect_clear.modulate = Color.WHITE
	
	if perfect_clear_tween:
		perfect_clear_tween.kill()
	perfect_clear_tween = create_tween()
	
	perfect_clear_tween.tween_property(perfect_clear, "modulate", Color.WHITE, 0.5)
	perfect_clear_tween.tween_property(perfect_clear, "modulate", Color.TRANSPARENT, 0.5)
	perfect_clear_tween.tween_callback(func () -> void: perfect_clear.hide())
