class_name BlockSkin
extends RefCounted
## Voxel "fire monkey" look for the block: orange body, flame-patterned cap,
## pixel face on the front (+z), yellow/blue marks on the sides, white base.
## Pixel art is drawn from the string grids below (one char = one pixel).

const PALETTE := {
	"W": Color("f6efe6"), "R": Color("e8432e"), "Y": Color("ffd23f"),
	"B": Color("2d4a9a"), "O": Color("f08a2c"), "D": Color("c8331f"),
}
const BODY := Color("ee7a2a")
const CAP := Color("f2873a")
const BASE := Color("f4ece2")

## Front face below the cap (12 x 16).
const FACE := [
	"....YYYY....",
	".....YY.....",
	"WW...YY...WW",
	"WWW..YY..WWW",
	"WWWW.YY.WWWW",
	"RRWWWYYWWWRR",
	"RRRWWWWWWRRR",
	"YYRRWWWWRRYY",
	"YBBRRWWRRBBY",
	"YYBRRRRRRBYY",
	"WYYRRRRRRYYW",
	"WWWWRRRRWWWW",
	"WWWWWRRWWWWW",
	".WWWWWWWWWW.",
	"..WWWWWWWW..",
	"............",
]
## Left / right faces below the cap (12 x 16).
const SIDE := [
	"............",
	"............",
	"...YY.......",
	"...YY.......",
	"............",
	"......YY....",
	"......YY....",
	"............",
	"............",
	"BB..........",
	"BB..........",
	"BB......BB..",
	"........BB..",
	"........BB..",
	"............",
	"............",
]
## Top of the cap (12 x 12): flame pattern.
const CAP_TOP := [
	"......RRR...",
	".....RRYYR..",
	"...RRRYYYRR.",
	"..RRYYYRRR..",
	".RRYYRRR....",
	"RRYYRR......",
	"RYYRR...RR..",
	"RYRR...RYYR.",
	"RRR...RYYRR.",
	"RR...RYYR...",
	"R...RYYR....",
	"...RRRR.....",
]
## Sides of the cap (12 x 5): red rim with yellow drips.
const CAP_SIDE := [
	"............",
	"..R....RR...",
	"RRYRRRRYYRRR",
	"RYYYRRYYRRYR",
	"DDDDDDDDDDDD",
]
## Small cube front (12 x 8): just the eyes and mask.
const CUBE_FACE := [
	"WW.......WWW",
	"RRWW..WWWRRR",
	"YYRRWWWWRRYY",
	"YBBRRWWRRBBY",
	"YYBRRRRRRBYY",
	"WYYRRRRRRYYW",
	"WWWWRRRRWWWW",
	".WWWWWWWWWW.",
]


static func _texture(rows: Array) -> ImageTexture:
	var h := rows.size()
	var w: int = rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var ch: String = rows[y][x]
			if PALETTE.has(ch):
				img.set_pixel(x, y, PALETTE[ch])
	return ImageTexture.create_from_image(img)


static func _decal_mat(rows: Array) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _texture(rows)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.roughness = 0.6
	return m


## A flat pixel-art quad lying on a face. `normal` is the face direction.
static func _decal(parent: Node3D, rows: Array, size: Vector2, center: Vector3, normal: Vector3) -> void:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = _decal_mat(rows)
	var basis: Basis
	if normal == Vector3.UP:
		basis = Basis(Vector3.RIGHT, -PI / 2)
	else:
		basis = Basis(Vector3.UP, atan2(normal.x, normal.z))
	mi.transform = Transform3D(basis, center + normal * 0.004)
	parent.add_child(mi)


static func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, radius: float = 0.03) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshUtil.rounded_box(size, radius)
	mi.material_override = MeshUtil.mat(color, 0.6)
	mi.position = at
	parent.add_child(mi)
	return mi


## Decorate the 1x2x1 block (local y from -0.98 to +0.98).
static func dress_block(body: MeshInstance3D) -> void:
	body.material_override = MeshUtil.mat(BODY, 0.6)
	# cap: slightly wider slab on top
	_box(body, Vector3(1.04, 0.42, 1.04), Vector3(0, 0.79, 0), CAP)
	_decal(body, CAP_TOP, Vector2(1.04, 1.04), Vector3(0, 1.0, 0), Vector3.UP)
	for n in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
		_decal(body, CAP_SIDE, Vector2(1.04, 0.42), Vector3(0, 0.79, 0) + n * 0.52, n)
	# base: white slab at the bottom
	_box(body, Vector3(1.04, 0.16, 1.04), Vector3(0, -0.9, 0), BASE)
	# face and side marks between cap and base
	_decal(body, FACE, Vector2(0.96, 1.28), Vector3(0, -0.06, 0.48), Vector3.BACK)
	_decal(body, SIDE, Vector2(0.96, 1.28), Vector3(-0.48, -0.06, 0), Vector3.LEFT)
	_decal(body, SIDE, Vector2(0.96, 1.28), Vector3(0.48, -0.06, 0), Vector3.RIGHT)


## Decorate a 1x1x1 cube (local y from -0.48 to +0.48).
static func dress_cube(cube: MeshInstance3D) -> void:
	cube.material_override = MeshUtil.mat(BODY, 0.6)
	_box(cube, Vector3(1.04, 0.26, 1.04), Vector3(0, 0.37, 0), CAP)
	_decal(cube, CAP_TOP, Vector2(1.04, 1.04), Vector3(0, 0.5, 0), Vector3.UP)
	_box(cube, Vector3(1.04, 0.1, 1.04), Vector3(0, -0.43, 0), BASE)
	_decal(cube, CUBE_FACE, Vector2(0.96, 0.64), Vector3(0, -0.04, 0.48), Vector3.BACK)
