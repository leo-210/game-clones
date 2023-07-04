extends Node2D


@onready var grid: TileMap = $Grid
@onready var gravity_timer: Timer = $GravityTimer
@onready var soft_drop_timer: Timer = $SoftDropTimer
@onready var letting_piece_go_timer: Timer = $LettingPieceGoTimer

const TOP_LINE_Y := 4
const LINE_LENGTH := 10

var current_bag: Array[int]
var current_coords: Vector2i # The coords are at top left corner or the piece
var current_piece: Dictionary
var current_rotation: int

var soft_dropping := false
var colliding := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_piece()


func _process(_delta: float) -> void:
	# Move to the sides
	if Input.is_action_just_pressed("left"):
		colliding = move_piece(Vector2(-1, 0))
	if Input.is_action_just_pressed("right"):
		colliding = move_piece(Vector2(1, 0))
	
	# Rotation
	if Input.is_action_just_pressed("turn_left"):
		rotate_piece(-1)
	if Input.is_action_just_pressed("turn_right"):
		rotate_piece(1)
	
	print(colliding)
	
	# Soft drop
	if Input.is_action_just_pressed("soft_drop"):
		if colliding:
			letting_piece_go_timer.stop()
			_on_letting_piece_go_timer_timeout()
		else:
			soft_dropping = true
			soft_drop_timer.start()
	if Input.is_action_just_released("soft_drop"):
		soft_dropping = false
		soft_drop_timer.stop()
	
	if colliding and letting_piece_go_timer.is_stopped():
		letting_piece_go_timer.start()

func _physics_process(_delta: float) -> void:
	pass


func move_piece(move: Vector2i) -> bool:
	var is_colliding: bool = false
	
	if move.y != 0:
		is_colliding = check_down_collisions(current_coords + move, current_rotation)
	
	if !is_colliding:
		clear_piece()
		current_coords += move
		draw_piece()
	
	if move.y != 0:
		return check_down_collisions(current_coords + move, current_rotation)
	return false

# Pass 1 as argument to rotate clockwise, -1 to rotate counterclockwise
func rotate_piece(rotation_: int) -> void:
	var next_rotation = (current_rotation + rotation_) % 4
	for i in range(len(current_piece["rotations"][next_rotation])):
		if current_piece["rotations"][next_rotation][i] == 1:
			if grid.get_cell_atlas_coords(
					1, 
					current_coords + Vector2i(i % 4, i / 4), 
			).y == 0:  # If there is a block here
				pass
	
	clear_piece()
	current_rotation = next_rotation
	draw_piece()

func check_down_collisions(next_coords: Vector2i, next_rotation: int) -> bool:
	var is_colliding = false 
	
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1 and \
				(len(current_piece["rotations"][current_rotation]) <= i+4 or  # So that only the lowest blocks check for collisions
				current_piece["rotations"][current_rotation][i + 4] == 0):
			if next_coords.y + i/4 > TOP_LINE_Y + 19 or \
					grid.get_cell_atlas_coords(
							1, 
							next_coords + Vector2i(i % 4, i / 4), 
					).y == 0:  # If there is a block here
				is_colliding = true
				break
	
	return is_colliding


func spawn_piece() -> void:
	if len(current_bag) == 0:
		current_bag = new_bag()
	
	current_piece = Blocks.blocks[current_bag.pop_back()]
	current_coords = Vector2i(4, 1)
	current_rotation = 0
	
	draw_piece()

func draw_piece() -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:
			grid.set_cell(
					1, 
					current_coords + Vector2i(i % 4, i / 4), 
					1, 
					Vector2i(current_piece["color"], 0)
			)

func clear_piece() -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:  # So it doesn't delete other blocks
			grid.set_cell(1, current_coords + Vector2i(i % 4, i / 4),)  # Empty cell


func next_piece() -> void:
	colliding = false
	spawn_piece()
	clear_lines()

func clear_lines() -> void:
	var removed_lines: int = 0
	var lowest_line: int = 0  # The top line is 0 and the bottom one is 19.
	
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
			removed_lines += 1
			# We go from top to bottom, so this will always be the lowest line :
			# we don't need to use the max() function.
			lowest_line = current_coords.y + line
	
	# Moving all cells down
	if removed_lines > 0:
		for line in range(lowest_line):
			for i in range(LINE_LENGTH):
				var cell := grid.get_cell_atlas_coords(
						1, 
						Vector2i(i + 1, TOP_LINE_Y + lowest_line - line)
				)
				grid.set_cell(
						1, 
						Vector2i(
								i + 1, 
								TOP_LINE_Y + lowest_line - line + removed_lines
						), 
						1, 
						cell
				)
		# In case it moves the current piece
		draw_piece()


func new_bag() -> Array[int]:
	var bag: Array[int] = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 0, 0]
	bag.shuffle()
	
	return bag


func _on_gravity_timeout() -> void:
	if !soft_dropping:
		colliding = move_piece(Vector2i(0, 1))


func _on_soft_drop_timeout() -> void:
	colliding = move_piece(Vector2i(0, 1))


func _on_letting_piece_go_timer_timeout() -> void:
	# If still colliding
	if colliding:
		next_piece()
