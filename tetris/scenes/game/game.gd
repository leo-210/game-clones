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
	
	# If it can move
	if move.y != 0:
		is_colliding = check_down_collisions(current_coords + move, current_rotation)
	elif move.x != 0:
		is_colliding = check_side_collisions(current_coords + move, current_rotation, move.sign().x)
	
	if !is_colliding:
		clear_piece()
		current_coords += move
		draw_piece()
	
	# If after moving, it is colliding or not
	is_colliding = false
	if move.y != 0:
		is_colliding = check_down_collisions(current_coords + move, current_rotation)
	return is_colliding

# Pass 1 as argument to rotate clockwise, -1 to rotate counterclockwise
func rotate_piece(rotation_: int) -> bool:
	var next_rotation := (current_rotation + rotation_) % 4
	var next_coords := Vector2i.ZERO
	var can_rotate: bool = true
	if check_down_collisions(current_coords, next_rotation) or \
			check_side_collisions(current_coords, next_rotation, 1) or \
			check_side_collisions(current_coords, next_rotation, -1):
		
		if !check_down_collisions(current_coords + Vector2i.LEFT, next_rotation) and \
				!check_side_collisions(current_coords + Vector2i.LEFT, next_rotation, -1):
			next_coords = Vector2i.LEFT
		elif !check_down_collisions(current_coords + Vector2i.RIGHT, next_rotation) and \
				!check_side_collisions(current_coords + Vector2i.RIGHT, next_rotation, 1):
			next_coords = Vector2i.RIGHT
		# Try to move twice to the side
		elif !check_down_collisions(current_coords + Vector2i.LEFT * 2, next_rotation) and \
				!check_side_collisions(current_coords + Vector2i.LEFT * 2, next_rotation, -1):
			next_coords = Vector2i.LEFT * 2
		elif !check_down_collisions(current_coords + Vector2i.RIGHT * 2, next_rotation) and \
				!check_side_collisions(current_coords + Vector2i.RIGHT * 2, next_rotation, 1):
			next_coords = Vector2i.RIGHT * 2
		else: 
			can_rotate = false
	
	if can_rotate:
		clear_piece()
		current_coords += next_coords
		current_rotation = next_rotation
		draw_piece()
	
	return check_down_collisions(current_coords + Vector2i.DOWN, current_rotation)

func check_down_collisions(next_coords: Vector2i, next_rotation: int) -> bool:
	var is_colliding = false 
	
	for i in range(len(current_piece["rotations"][next_rotation])):
		if current_piece["rotations"][next_rotation][i] == 1:
			if next_coords.y + i/4 > TOP_LINE_Y + 19 or \
					grid.get_cell_atlas_coords(
							1, 
							next_coords + Vector2i(i % 4, i / 4), 
					).y == 0:  # If there is a block here
				is_colliding = true
				break
	
	return is_colliding

# Make direction=1 for right, direction=-1 for left
func check_side_collisions(next_coords: Vector2i, next_rotation: int, direction: int) -> bool:
	var is_colliding = false 
	
	for i in range(len(current_piece["rotations"][next_rotation])):
		if current_piece["rotations"][next_rotation][i] == 1:
			if next_coords.x + i%4 < 1 or \
					next_coords.x + i%4 > LINE_LENGTH:
				is_colliding = true
				break
			
			if grid.get_cell_atlas_coords(1, next_coords + Vector2i(i % 4, i / 4)).y == 0:
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

func draw_piece(layer: int = 2) -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:
			grid.set_cell(
					layer, 
					current_coords + Vector2i(i % 4, i / 4), 
					1, 
					Vector2i(current_piece["color"], 0)
			)

func clear_piece() -> void:
	for i in range(len(current_piece["rotations"][current_rotation])):
		if current_piece["rotations"][current_rotation][i] == 1:  # So it doesn't delete other blocks
			grid.set_cell(2, current_coords + Vector2i(i % 4, i / 4),)  # Empty cell


func next_piece() -> void:
	colliding = false
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


func new_bag() -> Array[int]:
	var bag: Array[int] = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]
	bag.shuffle()
	
	return bag


func _on_gravity_timeout() -> void:
	if !soft_dropping:
		colliding = move_piece(Vector2i.DOWN)


func _on_soft_drop_timeout() -> void:
	colliding = move_piece(Vector2i.DOWN)


func _on_letting_piece_go_timer_timeout() -> void:
	# If still colliding
	if check_down_collisions(current_coords + Vector2i.DOWN, current_rotation):
		next_piece()
