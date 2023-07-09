extends Node2D


@onready var grid: TileMap = $Grid
@onready var lock_delay: Timer = $LockDelay
@onready var lock_controls: Timer = $LockControls

const TOP_LINE_Y := 2
const LINE_LENGTH := 10

const LINES_PER_LEVEL := 10
const SOFT_DROP_SPEED := 1

var current_bag: Array[int]
var current_coords: Vector2i # The coords are at top left corner of the piece
var current_piece: Dictionary
var current_rotation: int
var held_piece: Dictionary = {}

var level := 1.0
var score := 0
var speed: float
var lines_left: int
var combo := -1
var last_clear_difficult := false

var soft_dropping := false
var colliding := false
var can_hold := true

var controls_locked := false
var game_over := false
var game_initialized := false

var timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.init_game.connect(_on_game_init)


func _process(_delta: float) -> void:
	if !game_initialized:
		return
	
	# Move to the sides
	if Input.is_action_just_pressed("left"):
		move_piece(Vector2i.LEFT)
	if Input.is_action_just_pressed("right"):
		move_piece(Vector2i.RIGHT)
	
	# Rotation
	if Input.is_action_just_pressed("turn_left"):
		colliding = rotate_piece(-1)
	if Input.is_action_just_pressed("turn_right"):
		colliding = rotate_piece(1)
	
	# Soft drop
	if Input.is_action_just_pressed("soft_drop"):
		if colliding:
			lock_delay.stop()
			_on_letting_piece_go_timer_timeout()
		else:
			soft_dropping = true
	if Input.is_action_just_released("soft_drop"):
		soft_dropping = false
	
	# Hard drop
	if Input.is_action_just_pressed("hard_drop") and !controls_locked:
		hard_drop()
	
	# Hold
	if Input.is_action_just_pressed("hold") and can_hold:
		can_hold = false
		EventBus.hold_piece.emit(current_piece)
		clear_piece()
		
		if held_piece.is_empty():
			held_piece = current_piece
			spawn_piece()
		else:
			var p := current_piece
			spawn_piece(held_piece)
			held_piece = p

	
	if colliding and lock_delay.is_stopped():
		lock_delay.start()

func _physics_process(_delta: float) -> void:
	if !game_initialized:
		return
	
	if soft_dropping:
		timer += SOFT_DROP_SPEED
	else:
		timer += 1 / (60 * speed)

	while timer >= 1:
		timer -= 1
		colliding = move_piece(Vector2i.DOWN)
		if soft_dropping:
			score_up(1)


func move_piece(move: Vector2i) -> bool:
	if game_over:
		return false
	
	var is_colliding := check_collisions(current_coords + move, current_rotation)
	
	if !is_colliding:
		clear_piece()
		current_coords += move
		draw_piece()
	
	# If after moving, it has a piece under it or not
	is_colliding = check_collisions(current_coords + Vector2i.DOWN, current_rotation)
	return is_colliding

# Pass 1 as argument to rotate clockwise, -1 to rotate counterclockwise
func rotate_piece(rotation_: int) -> bool:
	var next_rotation := (current_rotation + rotation_) % 4
	var next_coords := Vector2i.ZERO
	var can_rotate: bool = false
	
	match current_piece:
		Blocks.blocks[Blocks.NAMES.I]:
			for i in range(len(RotationOffsets.i_offsets[0])):
				var offset: Vector2i = (RotationOffsets.i_offsets[current_rotation][i] -
						RotationOffsets.i_offsets[next_rotation][i])
				if !check_collisions(current_coords + offset, next_rotation):
					can_rotate = true
					next_coords = offset
					break
		Blocks.blocks[Blocks.NAMES.O]:
			if !check_collisions(current_coords, next_rotation):
				can_rotate = true
		_:
			for i in range(len(RotationOffsets.offsets[0])):
				var offset: Vector2i = (RotationOffsets.offsets[current_rotation][i] -
						RotationOffsets.offsets[next_rotation][i])
				if !check_collisions(current_coords + offset, next_rotation):
					can_rotate = true
					next_coords = offset
					break
	
	if can_rotate:
		clear_piece()
		current_coords += next_coords
		current_rotation = next_rotation
		draw_piece()
	
	return check_collisions(current_coords + Vector2i.DOWN, current_rotation)

func check_collisions(next_coords: Vector2i, next_rotation: int) -> bool:
	var is_colliding = false 
	
	for i in range(len(current_piece["rotations"][next_rotation])):
		if current_piece["rotations"][next_rotation][i] == 1:
			if next_coords.y + i/4 > TOP_LINE_Y + 19 or \
					next_coords.x + i%4 < 1 or \
					next_coords.x + i%4 > LINE_LENGTH:
				is_colliding = true
				break
			if grid.get_cell_atlas_coords(1, next_coords + Vector2i(i % 4, i / 4)).y == 0:
				is_colliding = true
				break
	
	return is_colliding


func spawn_piece(new_piece: Dictionary = {}) -> void:
	if game_over:
		return
	
	if new_piece.is_empty():
		if len(current_bag) <= 7:
			var bag := new_bag()
			bag.append_array(current_bag)
			current_bag = bag
		current_piece = Blocks.blocks[current_bag.pop_back()]
	else:
		current_piece = new_piece
	current_coords = Vector2i(4, 1)
	current_rotation = 0
	
	if check_collisions(current_coords, current_rotation):
		EventBus.game_over.emit(score)
		return
	
	draw_piece()
	EventBus.next_piece.emit(current_bag)

func draw_piece(layer: int = 2) -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:
			grid.set_cell(
					layer, 
					current_coords + Vector2i(i % 4, i / 4), 
					1, 
					Vector2i(current_piece["color"], 0)
			)
	
	# Draw piece ghost
	if layer == 2:
		var k := 1
		while !check_collisions(current_coords + Vector2i.DOWN * k, current_rotation):
			k += 1
		
		k -= 1
		if k > 0:
			for i in range(len(current_piece["rotations"][current_rotation])):
				if current_piece["rotations"][current_rotation][i] == 1:
					grid.set_cell(
							3, 
							current_coords + Vector2i.DOWN * k + Vector2i(i % 4, i / 4), 
							1, 
							Vector2i(current_piece["color"], 1)
					)

func clear_piece() -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:  # So it doesn't delete other blocks
			grid.set_cell(2, current_coords + Vector2i(i % 4, i / 4))
	
	# Clear piece ghost
	var k := 1
	while !check_collisions(current_coords + Vector2i.DOWN * k, current_rotation):
		k += 1
	
	k -= 1
	if k > 0:
		for i in range(len(current_piece["rotations"][current_rotation])):
			if current_piece["rotations"][current_rotation][i] == 1:  # So it doesn't delete other blocks
				grid.set_cell(3, current_coords + Vector2i.DOWN * k + Vector2i(i % 4, i / 4))


func next_piece() -> void:
	colliding = false
	can_hold = true
	
	controls_locked = true
	lock_controls.start()
	
	clear_piece()
	draw_piece(1)
	clear_lines()
	spawn_piece()

func clear_lines() -> void:
	var removed_lines: Array[int] = []
	
	# We only check the 4 lines after current_coords because these are the 
	# only ones that may be full.
	for line in range(4):
		var hole_in_line := false
		
		for i in range(LINE_LENGTH):
			if grid.get_cell_atlas_coords(
					1, 
					Vector2i(i + 1, line + current_coords.y)
			).y != 0:  # If there are no blocks there
				hole_in_line = true
				break
		
		if !hole_in_line:
			for i in range(LINE_LENGTH):
				grid.set_cell(1, Vector2i(i + 1, line + current_coords.y))  # Empty cell
			removed_lines.append(current_coords.y + line)
	
	# Moving all cells down
	for removed_line in removed_lines:
		for line in range(removed_line):
			for i in range(LINE_LENGTH):
				var cell := grid.get_cell_atlas_coords(
						1, 
						Vector2i(i + 1, removed_line - line - 1)
				)
				grid.set_cell(
						1, 
						Vector2i(
								i + 1, 
								removed_line - line
						), 
						1, 
						cell
				)
	
	var back_to_back := false
	var perfect_clear := false
	
	if grid.get_used_cells(1).is_empty():
		perfect_clear = true
		EventBus.perfect_clear.emit()
	
	match len(removed_lines):
		1:
			if perfect_clear:
				score_up(800 * level)
			else:
				score_up(100 * level)
		2:
			if perfect_clear:
				score_up(1200 * level)
			else:
				score_up(300 * level)
		3:
			if perfect_clear:
				score_up(1800 * level)
			else:
				score_up(500 * level)
		4:
			if last_clear_difficult:
				if perfect_clear:
					score_up(3200 * level)
				else:
					score_up(800 * level * 1.5)
				back_to_back = true
			else:
				if perfect_clear:
					score_up(2000 * level)
				else:
					score_up(800 * level)
			last_clear_difficult = true
			EventBus.tetris.emit(back_to_back)
	
	if len(removed_lines) == 0:
		combo = -1
	if len(removed_lines) > 0:
		combo += 1
		if combo >= 1:
			EventBus.combo.emit(combo)
			score_up(50 * combo * level)
	
	if len(removed_lines) < 4:
		last_clear_difficult = false
	
	lines_left -= len(removed_lines)
	if lines_left <= 0:
		level_up()
	
	EventBus.line_clear.emit(lines_left)

func level_up() -> void:
	level += 1
	lines_left += LINES_PER_LEVEL
	if level < 20:
		speed = pow(0.8 - ((level-1) * 0.007), level-1)  # Tetris Worlds formula
	EventBus.level_up.emit(level)

func score_up(score_increment: int) -> void:
	score += score_increment
	EventBus.score_up.emit(score)

func hard_drop() -> void:
	var k := 1
	while !check_collisions(current_coords + Vector2i.DOWN * k, current_rotation):
		k += 1
	
	k -= 1
	clear_piece()
	current_coords += Vector2i.DOWN * k
	next_piece()
	
	score_up(2 * k)


func _on_game_over(score: int) -> void:
	controls_locked = true
	game_over = true
	lock_controls.stop()


func _on_game_init(level_: int) -> void:
	level = level_
	lines_left = LINES_PER_LEVEL * level
	speed = pow(0.8 - ((level-1) * 0.007), level-1)
	game_initialized = true
	spawn_piece()


func new_bag() -> Array[int]:
	var bag: Array[int] = [0, 1, 2, 3, 4, 5, 6]
	bag.shuffle()
	
	return bag


func _on_letting_piece_go_timer_timeout() -> void:
	# If still colliding
	if check_collisions(current_coords + Vector2i.DOWN, current_rotation):
		next_piece()


func _on_lock_controls_timeout() -> void:
	controls_locked = false
