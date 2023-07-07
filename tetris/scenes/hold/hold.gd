extends Node2D


@onready var tile_map: TileMap = $TileMap


func _ready() -> void:
	EventBus.hold_piece.connect(_on_hold_piece)


func _on_hold_piece(piece: Dictionary) -> void:
	for cell in tile_map.get_used_cells(0):
		tile_map.set_cell(0, cell)
	
	var rotation_ := 0
	if piece in [
			Blocks.blocks[Blocks.NAMES.J], 
			Blocks.blocks[Blocks.NAMES.L], 
			Blocks.blocks[Blocks.NAMES.Z], 
			Blocks.blocks[Blocks.NAMES.S],
			Blocks.blocks[Blocks.NAMES.T]
	]:
		rotation_ = 2
	for i in range(len(piece["rotations"][rotation_])):
		if piece["rotations"][rotation_][i] == 1:
			tile_map.set_cell(0, Vector2i(i % 4 + 1, i / 4 + 1), 0, Vector2i(piece["color"], 0))
