class_name Foliage
extends RefCounted
## Procedural textures and meshes for leaves, grass and old stone, so the jungle
## has real leaf shapes instead of plain blobs. Everything is generated once in
## code (no image files) and cached.

const LEAF_GREENS := [Color("2f6b2a"), Color("3d7d2e"), Color("4b8b31"), Color("5a9a36"), Color("27592a"), Color("6aa53c")]
const GRASS_GREENS := [Color("4f8a2c"), Color("5f9a34"), Color("6faa3a"), Color("3f7428")]

static var _leaf_tex: ImageTexture
static var _grass_tex: ImageTexture
static var _stone_tex: NoiseTexture2D
static var _clump: ArrayMesh
static var _tuft: ArrayMesh


## A bunch of pointed leaves with midribs on a transparent 128x128 image.
static func leaf_texture() -> ImageTexture:
	if _leaf_tex != null:
		return _leaf_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 50.0
		var cx := 64.0 + cos(ang) * r
		var cy := 64.0 + sin(ang) * r
		var dir := rng.randf() * TAU
		var length := rng.randf_range(9.0, 16.0)
		var width := length * rng.randf_range(0.32, 0.45)
		var col: Color = LEAF_GREENS[rng.randi() % LEAF_GREENS.size()].lightened(rng.randf_range(-0.05, 0.12))
		var ca := cos(dir)
		var sa := sin(dir)
		for y in range(int(cy - length) - 1, int(cy + length) + 2):
			for x in range(int(cx - length) - 1, int(cx + length) + 2):
				if x < 0 or y < 0 or x >= n or y >= n:
					continue
				var dx := x - cx
				var dy := y - cy
				var u := (dx * ca + dy * sa) / length          # along the leaf, -1..1
				var v := (-dx * sa + dy * ca) / width          # across the leaf
				if absf(u) > 1.0:
					continue
				var half := 1.0 - u * u                        # pointed at both ends
				if absf(v) > half:
					continue
				var shade := col.darkened(0.25) if absf(v) < 0.12 else col.lightened(0.1 * (1.0 - absf(v)))
				img.set_pixel(x, y, shade)
	img.generate_mipmaps()
	_leaf_tex = ImageTexture.create_from_image(img)
	return _leaf_tex


## Tall thin grass blades on a transparent 64x64 image (bottom = ground).
static func grass_texture() -> ImageTexture:
	if _grass_tex != null:
		return _grass_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 26:
		var x0 := rng.randf_range(6, 58)
		var h := rng.randf_range(24, 60)
		var lean := rng.randf_range(-10, 10)
		var col: Color = GRASS_GREENS[rng.randi() % GRASS_GREENS.size()]
		for k in int(h):
			var t := k / h
			var w := lerpf(2.2, 0.3, t)
			var cx := x0 + lean * t * t
			var y := n - 1 - k
			for x in range(int(cx - w), int(cx + w) + 1):
				if x >= 0 and x < n:
					img.set_pixel(x, y, col.lightened(t * 0.25))
	img.generate_mipmaps()
	_grass_tex = ImageTexture.create_from_image(img)
	return _grass_tex


## Mottled old stone (cream with grey-green stains), seamless.
static func stone_texture() -> NoiseTexture2D:
	if _stone_tex != null:
		return _stone_tex
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	noise.seed = 3
	var ramp := Gradient.new()
	ramp.set_color(0, Color("a7a893"))
	ramp.add_point(0.4, Color("d3cdbd"))
	ramp.add_point(0.7, Color("e6e0d2"))
	ramp.set_color(ramp.get_point_count() - 1, Color("efeae0"))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = noise
	t.color_ramp = ramp
	_stone_tex = t
	return _stone_tex


static func stone_material(tint: Color = Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = stone_texture()
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.35, 0.35, 0.35)
	m.roughness = 0.85
	return m


static func leaf_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = leaf_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


static func grass_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = grass_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


## Leaf clump: 3 crossed vertical cards + 1 flat card, 2x2 units, centred.
static func clump_mesh() -> ArrayMesh:
	if _clump != null:
		return _clump
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := PI * k / 3.0
		var right := Vector3(cos(a), 0, sin(a))
		_card(st, right, Vector3.UP, 1.0)
	_card(st, Vector3.RIGHT, Vector3.BACK, 1.0)          # flat, seen from above
	_clump = st.commit()
	return _clump


## Grass tuft: 2 crossed cards standing on y = 0, 1 unit tall.
static func tuft_mesh() -> ArrayMesh:
	if _tuft != null:
		return _tuft
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 2:
		var a := PI * k / 2.0 + 0.4
		var right := Vector3(cos(a), 0, sin(a)) * 0.5
		var up := Vector3.UP
		var corners := [-right, right, right + up, -right + up]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[i])
			st.add_vertex(corners[i])
	_tuft = st.commit()
	return _tuft


static func _card(st: SurfaceTool, right: Vector3, up: Vector3, half: float) -> void:
	var corners := [(-right - up) * half, (right - up) * half, (right + up) * half, (-right + up) * half]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.UP)     # foliage lit from above, no dark back faces
		st.set_color(Color.WHITE)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])
