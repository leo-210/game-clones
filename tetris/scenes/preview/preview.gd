extends Node2D


@onready var tile_map: TileMap = $TileMap

const PREVIEW_LENGTH := 4  # How many pieces on preview


func _ready() -> void:
	EventBus.next_piece.connect(_on_next_piece)


func _on_next_piece(bag: Array[int]) -> void:
	for cell in tile_map.get_used_cells(0):
		tile_map.set_cell(0, cell)
	
	for i in range(PREVIEW_LENGTH):
		var piece: Dictionary = Blocks.blocks[bag[len(bag) - i - 1]]
		
		var rotation_ := 0
		if piece in [
				Blocks.blocks[Blocks.NAMES.J], 
				Blocks.blocks[Blocks.NAMES.L], 
				Blocks.blocks[Blocks.NAMES.Z], 
				Blocks.blocks[Blocks.NAMES.S],
				Blocks.blocks[Blocks.NAMES.T]
		]:
			rotation_ = 2
		for j in range(len(piece["rotations"][rotation_])):
			if piece["rotations"][rotation_][j] == 1:
				tile_map.set_cell(0, Vector2i(j % 4 + 1, j / 4 + 1 + 3 * i), 0, Vector2i(piece["color"], 0))
