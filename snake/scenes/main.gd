extends Control


enum {
	RIGHT,
	DOWN,
	LEFT,
	UP
}
enum LAYERS {
	SNAKE,
	APPLE
}

const DIR_TO_VECTOR: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.UP,
]
# In seconds
const MINIMUM_DRAG_DELAY: float = 0.05

# In cells per second
@export_range(0, 30) var SPEED: float = 7.0

@onready var grid: TileMap = $SubViewportContainer/SubViewport/Grid
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var game_over_delay: Timer = $GameOverDelay
@onready var color_rect: ColorRect = $ColorRect
@onready var center_container: CenterContainer = $CenterContainer
@onready var length: Label = $CenterContainer/VBoxContainer/Length

var head: Vector2i
var body: Array[int]
var apples: Array[Vector2i]

var timer: float = 0.0
var current_direction: int = -1
var direction_queue: Array[int]

var available_positions: Array[Vector2i]

var game_started: bool = false
var game_over: bool = false

var drag_started_time: int
var drag_starting_pos: Vector2

var viewport_size: Vector2


func _ready() -> void:
	sub_viewport.size_2d_override = get_viewport_rect().size.normalized() * 17
	
	viewport_size = sub_viewport.size_2d_override
	
	for i in range(viewport_size.x):
		for j in range(viewport_size.y):
			available_positions.append(Vector2i(i, j))
	
	head = Vector2i(viewport_size / 2)
	body = []
	
	draw_snake()
	draw_apple()


func _process(_delta: float) -> void:
	var new_direction: int = -1
	
	if Input.is_action_just_pressed("right"):
		new_direction = RIGHT
	if Input.is_action_just_pressed("left"):
		new_direction = LEFT
	if Input.is_action_just_pressed("up"):
		new_direction = UP
	if Input.is_action_just_pressed("down"):
		new_direction = DOWN
	
	if new_direction != -1:
		if new_direction % 2 == current_direction % 2:
			if !direction_queue.is_empty():
				direction_queue.append(new_direction)
		else:
			direction_queue = [new_direction]
	
	if !game_started and new_direction != -1:
		timer += 1
		game_started = true


func _physics_process(_delta: float) -> void:
	if !game_started:
		return
	if game_over:
		return
	
	timer += SPEED / 60
	while timer >= 1:
		timer -= 1
		
		if !direction_queue.is_empty():
			current_direction = direction_queue.pop_front()
		
		head += DIR_TO_VECTOR[current_direction]
		body.append(current_direction)
		
		# If there's an apple
		var new_apple := false
		for apple in apples: 
			if apple == head:
				apples.erase(apple)
				clear_cell(LAYERS.APPLE, apple)
				
				new_apple = true
				
				break
		if !new_apple:
			body.pop_front()
		
		clear_snake()
		draw_snake_body()
		
		# If colliding (we check after we drew the new snake body, but not head)
		if head.x < 0 or head.x > viewport_size.x - 1 or \
				head.y < 0 or head.y > viewport_size.y - 1 or \
				grid.get_cell_atlas_coords(LAYERS.SNAKE, head).x == 0:
			if !game_over:
				game_over_delay.start()
				game_over = true
				
				length.text = "Final length : " + str(len(body))
				
				color_rect.show()
				center_container.show()
		
		draw_snake_head()
		
		if new_apple:
			draw_apple()


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if game_over and game_over_delay.is_stopped():
			get_tree().reload_current_scene()
	
	if !event is InputEventMouse:
		return
	
	if event.is_pressed():
		drag_started_time = Time.get_ticks_msec()
		drag_starting_pos = event.position
	
	var drag_delay: int = Time.get_ticks_msec() - drag_started_time
	if drag_delay < MINIMUM_DRAG_DELAY:
		return
	
	if event.is_released():
		drag_started_time = Time.get_ticks_msec()
	
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	
	var drag_motion: Vector2 = event.position - drag_starting_pos
	
	var new_direction: int = -1
	
	if abs(drag_motion.x) >= abs(drag_motion.y):
		if drag_motion.x > 0:
			new_direction = RIGHT
		else:
			new_direction = LEFT
	else:
		if drag_motion.y > 0:
			new_direction = DOWN
		else:
			new_direction = UP
	
	if new_direction != -1:
		if new_direction % 2 == current_direction % 2:
			if !direction_queue.is_empty():
				direction_queue.append(new_direction)
		else:
			direction_queue = [new_direction]
	
	if !game_started and new_direction != -1:
		timer += 1
		game_started = true


func draw_snake() -> void:
	clear_snake()
	draw_snake_head()
	draw_snake_head()

func draw_snake_body() -> void:
	var offset := Vector2i.ZERO
	for i in range(len(body)):
		var part = body[len(body) - i - 1]
		
		offset += DIR_TO_VECTOR[(part + 2) % 4]
		available_positions.erase(offset + head)
		set_cell(LAYERS.SNAKE, head + offset)

func draw_snake_head() -> void:
	set_cell(LAYERS.SNAKE, head)
	available_positions.erase(head)

func clear_snake() -> void:
	for cell in grid.get_used_cells(0):
		clear_cell(LAYERS.SNAKE, cell)
		available_positions.append(cell)


func draw_apple() -> void:
	if len(available_positions) == 0:
		return
	
	available_positions.shuffle()
	
	var coords: Vector2i = available_positions.pop_back()
	apples.append(coords)
	
	set_cell(LAYERS.APPLE, coords)


func set_cell(layer: LAYERS, coords: Vector2i) -> void:
	grid.set_cell(layer, coords, 0, Vector2i(layer, 0))


func clear_cell(layer: LAYERS, coords: Vector2i) -> void:
	grid.set_cell(layer, coords)
