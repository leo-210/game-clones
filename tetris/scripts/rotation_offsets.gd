extends Node


# Offsets are from :
# https://tetris.wiki/Super_Rotation_System#How_Guideline_SRS_Really_Works
const offsets = [
	[Vector2i(0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0)],
	[Vector2i(0, 0), Vector2i(+1, 0), Vector2i(+1,-1), Vector2i( 0,+2), Vector2i(+1,+2)],
	[Vector2i(0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0)],
	[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1,-1), Vector2i( 0,+2), Vector2i(-1,+2)]
]

const o_offsets =[
	Vector2i(0, 0),
	Vector2i(0, -1),
	Vector2i(-1, -1),
	Vector2i(-1, 0)
]

const i_offsets = [
	[Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0), Vector2i( 0, 0)],
	[Vector2i( 0, 0), Vector2i(+2, 0), Vector2i(-1, 0), Vector2i(+2,+1), Vector2i(-1,+2)],
	[Vector2i( 0, 0), Vector2i(+3, 0), Vector2i(-3, 0), Vector2i(+3,-1), Vector2i(-3,+1)],
	[Vector2i( 0, 0), Vector2i(+1, 0), Vector2i(+2, 0), Vector2i(+1,-2), Vector2i(-2,+1)]
]
