class_name Scenery
extends Node3D
## 3D jungle around the board: the board is an old stone platform floating over
## a deep misty rainforest. Giant mossy trunks frame it, round tree crowns fill
## the valley below with drifting mist between them, a few far waterfalls, warm
## sun shafts, fireflies, and vines hanging from the platform's edges.
## Purely decorative; rebuilt for every level.

const LEAF_DARK := [Color("173f22"), Color("1d4d27"), Color("22572b"), Color("16402f")]
const LEAF_LIT := [Color("2f6e27"), Color("3a7a2a"), Color("44852c"), Color("4f8c2c")]
const BARK := Color("4b3a2a")
const BARK_MOSS := Color("4f6a33")
const VINE := Color("3f6e2a")

var _rng := RandomNumberGenerator.new()
var _leaf_mesh: Mesh
var _trunk_mesh: Mesh


## Low-poly look: rebuild a primitive with one normal per face (flat shading).
static func _faceted(prim: PrimitiveMesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(prim, 0)
	st.deindex()
	st.generate_normals(true)   # flip=false keeps outward normals; per-face after deindex
	return st.commit()


func _ensure_meshes() -> void:
	if _leaf_mesh != null:
		return
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 1.7
	sph.radial_segments = 7
	sph.rings = 4
	_leaf_mesh = _faceted(sph)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 7
	cyl.rings = 1
	_trunk_mesh = _faceted(cyl)
var _mist_nodes: Array = []
var _t := 0.0


## center: middle of the board; reach: half its larger side. level: for vines.
func build(center: Vector3, reach: float, level: LevelData = null) -> void:
	for child in get_children():
		child.queue_free()
	_mist_nodes.clear()
	_rng.seed = 2026
	_ensure_meshes()
	_ground(center)
	_canopy(center, reach)
	_giant_trees(center, reach)
	_waterfalls(center, reach)
	_brick_ruins(center, reach)
	_mist(center, reach)
	_sun_rays(center, reach)
	_fireflies(center, reach)
	if level != null:
		_vines_under(level)
	# scenery never shades the board (giant crowns sit above it)
	for child in get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_t += delta
	for i in _mist_nodes.size():   # mist drifts slowly
		var m: Node3D = _mist_nodes[i]
		m.position.x += sin(_t * 0.05 + i) * delta * 0.25


func _ground(center: Vector3) -> void:
	var g := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(600, 600)
	g.mesh = plane
	g.material_override = MeshUtil.mat(Color("143a1c"), 1.0)
	g.position = Vector3(center.x, -22.0, center.z)
	add_child(g)


## Valley full of round tree crowns: clusters of blobs, dark below, sunlit on top.
func _canopy(center: Vector3, reach: float) -> void:
	var core_mat := StandardMaterial3D.new()
	core_mat.vertex_color_use_as_albedo = true
	core_mat.roughness = 1.0
	var trees := int(clampf((reach + 60.0) * (reach + 60.0) * 0.06, 260.0, 520.0))
	var per_core := 2
	var per_leaf := 7
	var cores := MultiMesh.new()
	cores.transform_format = MultiMesh.TRANSFORM_3D
	cores.use_colors = true
	cores.mesh = _leaf_mesh
	cores.instance_count = trees * per_core
	var leaves := MultiMesh.new()
	leaves.transform_format = MultiMesh.TRANSFORM_3D
	leaves.use_colors = true
	leaves.mesh = Foliage.clump_mesh()
	leaves.instance_count = trees * per_leaf
	var radius := reach + 60.0
	for t in trees:
		var ang := _rng.randf() * TAU
		var dist := sqrt(_rng.randf()) * radius
		var base := center + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		base.y = -19.0 + sin(base.x * 0.09) * 3.0 + cos(base.z * 0.07) * 3.0 + _rng.randf_range(-2.0, 2.0)
		var size := _rng.randf_range(2.6, 4.4)
		for k in per_core:                    # dark inside so the crown never looks hollow
			var off := Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.5, 0.2), _rng.randf_range(-0.6, 0.6)) * size
			var cs := size * 0.75
			cores.set_instance_transform(t * per_core + k, Transform3D(Basis().scaled(Vector3(cs, cs * 0.8, cs)), base + off))
			cores.set_instance_color(t * per_core + k, LEAF_DARK[_rng.randi() % 4])
		for k in per_leaf:                    # leaf cards on the outside
			var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 0.9), _rng.randf_range(-1, 1)) * size * 0.85
			var ls := size * _rng.randf_range(0.7, 1.0)
			var b := Basis().rotated(Vector3.UP, _rng.randf() * TAU).rotated(Vector3.RIGHT, _rng.randf_range(-0.3, 0.3)).scaled(Vector3(ls, ls, ls))
			leaves.set_instance_transform(t * per_leaf + k, Transform3D(b, base + off))
			var lit: bool = off.y > size * 0.2
			var tint := Color(0.95, 0.95, 0.8) if lit else Color(0.62, 0.7, 0.66)
			leaves.set_instance_color(t * per_leaf + k, tint * _rng.randf_range(0.85, 1.05))
	for pair in [[cores, core_mat], [leaves, Foliage.leaf_material()]]:
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = pair[0]
		mmi.material_override = pair[1]
		add_child(mmi)


## Huge mossy trunks with layered crowns around the board.
func _giant_trees(center: Vector3, reach: float) -> void:
	var bark := MeshUtil.mat(BARK, 1.0)
	var moss := MeshUtil.mat(BARK_MOSS, 1.0)
	var n := 9
	for i in n:
		var ang := TAU * i / n + _rng.randf_range(-0.2, 0.2)
		var dist := reach + _rng.randf_range(16.0, 28.0)
		var base := center + Vector3(cos(ang) * dist, -30.0, sin(ang) * dist)
		var h := _rng.randf_range(30.0, 36.0)
		var r := _rng.randf_range(1.6, 2.4)
		var trunk := MeshInstance3D.new()
		trunk.mesh = _trunk_mesh
		trunk.scale = Vector3(r, h, r)
		trunk.material_override = bark
		trunk.position = base + Vector3(0, h / 2.0, 0)
		add_child(trunk)
		var sleeve := MeshInstance3D.new()      # moss sleeve on the lower trunk
		sleeve.mesh = _trunk_mesh
		sleeve.scale = Vector3(r * 1.05, h * 0.5, r * 1.05)
		sleeve.material_override = moss
		sleeve.position = base + Vector3(0.12, h * 0.55, 0.12)
		add_child(sleeve)
		var top := base + Vector3(0, h, 0)
		for k in 4:                              # branches reaching out from the top
			var a := TAU * k / 4.0 + _rng.randf_range(-0.4, 0.4)
			var out := Vector3(cos(a), 0.0, sin(a))
			var blen := _rng.randf_range(5.0, 8.0)
			var br := MeshInstance3D.new()
			br.mesh = _trunk_mesh
			var tilt := Basis(out.cross(Vector3.UP).normalized(), deg_to_rad(-55))
			br.basis = tilt * Basis().scaled(Vector3(r * 0.35, blen, r * 0.35))
			br.position = top + Vector3(0, -3.0, 0) + (tilt * Vector3(0, blen * 0.5, 0))
			br.material_override = bark
			add_child(br)
			var tip := top + Vector3(0, -3.0, 0) + (tilt * Vector3(0, blen, 0))
			for jj in 3:                         # leaf clumps along each branch
				var leaf := MeshInstance3D.new()
				leaf.mesh = Foliage.clump_mesh()
				var ls := _rng.randf_range(2.6, 3.6)
				leaf.scale = Vector3(ls, ls, ls)
				leaf.rotation.y = _rng.randf() * TAU
				leaf.material_override = Foliage.leaf_material()
				leaf.position = tip.lerp(top, jj * 0.3) + Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.0, 2.0), _rng.randf_range(-1, 1))
				add_child(leaf)
		for v in 2:                              # vines hanging from the crown
			var vine := MeshInstance3D.new()
			var vc := CylinderMesh.new()
			vc.top_radius = 0.07
			vc.bottom_radius = 0.05
			vc.height = _rng.randf_range(10.0, 18.0)
			vc.radial_segments = 5
			vine.mesh = vc
			vine.material_override = MeshUtil.mat(VINE, 1.0)
			vine.position = base + Vector3(_rng.randf_range(-4, 4), h - 4.0 - vc.height / 2.0, _rng.randf_range(-4, 4))
			add_child(vine)


## A few thin waterfalls far away, falling into the mist.
func _waterfalls(center: Vector3, reach: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.92, 0.97, 1.0, 0.55)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	for i in 4:
		var w := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(_rng.randf_range(0.8, 1.6), 22.0)
		w.mesh = q
		w.material_override = mat
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := _rng.randf() * TAU
		var dist := reach + _rng.randf_range(35.0, 60.0)
		w.position = center + Vector3(cos(ang) * dist, -12.0, sin(ang) * dist)
		add_child(w)


## Soft white mist sheets drifting between the crowns.
func _mist(center: Vector3, reach: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.93, 0.96, 0.92, 0.32)
	mat.albedo_texture = _soft_texture()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 22:
		var m := MeshInstance3D.new()
		var q := PlaneMesh.new()
		var s := _rng.randf_range(14.0, 26.0)
		q.size = Vector2(s, s * 0.6)
		m.mesh = q
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := _rng.randf() * TAU
		var dist := _rng.randf_range(reach + 4.0, reach + 55.0)
		m.position = center + Vector3(cos(ang) * dist, _rng.randf_range(-15.0, -9.0), sin(ang) * dist)
		m.rotation.y = _rng.randf() * TAU
		add_child(m)
		_mist_nodes.append(m)


## Warm slanted light shafts.
func _sun_rays(center: Vector3, reach: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.88, 0.55, 0.035)
	for i in 5:
		var ray := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(_rng.randf_range(2.0, 4.5), 50.0, 0.2)
		ray.mesh = box
		ray.material_override = mat
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang := _rng.randf() * TAU
		var dist := reach + _rng.randf_range(3.0, 16.0)
		ray.position = center + Vector3(cos(ang) * dist, -6.0, sin(ang) * dist)
		ray.rotation = Vector3(deg_to_rad(30), deg_to_rad(-130), 0)
		add_child(ray)


## Vines and moss hanging from the platform's outer edge tiles.
func _vines_under(level: LevelData) -> void:
	var vine := MeshUtil.mat(VINE, 1.0)
	var moss := MeshUtil.mat(Color("5b8a35"), 1.0)
	for r in level.rows:
		for c in level.cols:
			var ch := level.tile(Vector2i(r, c))
			if ch == "-" or ch == "B":
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if level.tile(Vector2i(r, c) + d) == "-":
					edge = true
			if not edge or _rng.randf() > 0.45:
				continue
			for k in _rng.randi_range(1, 3):
				var v := MeshInstance3D.new()
				var vc := CylinderMesh.new()
				vc.top_radius = 0.035
				vc.bottom_radius = 0.025
				vc.height = _rng.randf_range(0.6, 2.6)
				vc.radial_segments = 5
				v.mesh = vc
				v.material_override = vine
				v.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				v.position = Vector3(c + _rng.randf_range(-0.4, 0.4), -0.34 - vc.height / 2.0, r + _rng.randf_range(-0.4, 0.4))
				add_child(v)
			var tuft := MeshInstance3D.new()       # moss clump under the tile
			var sph := SphereMesh.new()
			sph.radius = 0.3
			sph.height = 0.3
			tuft.mesh = sph
			tuft.material_override = moss
			tuft.position = Vector3(c, -0.38, r)
			add_child(tuft)
			if _rng.randf() < 0.5:                 # a little grass on the tile's outer rim
				var g := MeshInstance3D.new()
				g.mesh = Foliage.tuft_mesh()
				g.material_override = Foliage.grass_material()
				var gs := _rng.randf_range(0.22, 0.32)
				g.scale = Vector3(gs, gs, gs)
				var corner := Vector3(_rng.randf_range(-0.42, 0.42), 0, _rng.randf_range(-0.42, 0.42))
				if corner.length() < 0.3:
					corner = corner.normalized() * 0.42
				g.position = Vector3(c, 0.0, r) + corner
				add_child(g)


func _fireflies(center: Vector3, reach: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = 60
	p.lifetime = 7.0
	p.preprocess = 7.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(reach + 8.0, 3.0, reach + 8.0)
	pm.gravity = Vector3(0, 0.05, 0)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.4
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.5
	pm.turbulence_noise_scale = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.8, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color("bff0ff")
	m.albedo_texture = _soft_texture()
	m.emission_enabled = true
	m.emission = Color("7fd8ff")
	m.emission_energy_multiplier = 3.0
	quad.material = m
	p.draw_pass_1 = quad
	p.position = center + Vector3(0, -1.0, 0)
	p.visibility_aabb = AABB(Vector3(-reach - 12, -8, -reach - 12), Vector3(2 * reach + 24, 16, 2 * reach + 24))
	add_child(p)


## Soft round dot / puff texture (white centre fading to transparent).
static func _soft_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


## Small old stone buildings rising from the canopy around the board: an arch,
## a little pillared shrine, a stepped pyramid and a lone column. Neat masonry,
## moss caps and grass on top, so they read as architecture, not loose bricks.
func _brick_ruins(center: Vector3, reach: float) -> void:
	var stone := Foliage.stone_material(Color(0.86, 0.85, 0.8))
	var dark := Foliage.stone_material(Color(0.68, 0.68, 0.62))
	var kinds := ["arch", "shrine", "pyramid", "column", "shrine", "arch"]
	for i in kinds.size():
		var ang := TAU * i / kinds.size() + _rng.randf_range(-0.25, 0.25)
		var dist := reach + _rng.randf_range(9.0, 16.0)
		var root := Node3D.new()
		root.position = center + Vector3(cos(ang) * dist, -15.0, sin(ang) * dist)
		root.rotation.y = -ang + PI / 2.0          # face the board
		add_child(root)
		match kinds[i]:
			"arch":
				_arch(root, stone, dark)
			"shrine":
				_shrine(root, stone, dark)
			"pyramid":
				_pyramid(root, stone)
			_:
				_column(root, stone, dark)


func _block(root: Node3D, mat: Material, size: Vector3, at: Vector3) -> void:
	var b := MeshInstance3D.new()
	b.mesh = MeshUtil.rounded_box(size, 0.06)
	b.material_override = mat
	b.position = at + Vector3(0, size.y / 2.0, 0)
	root.add_child(b)


func _grass_on(root: Node3D, at: Vector3, spread: float, count: int) -> void:
	for k in count:
		var g := MeshInstance3D.new()
		g.mesh = Foliage.tuft_mesh()
		g.material_override = Foliage.grass_material()
		var gs := _rng.randf_range(0.5, 0.8)
		g.scale = Vector3(gs, gs, gs)
		g.position = at + Vector3(_rng.randf_range(-spread, spread), 0, _rng.randf_range(-spread, spread))
		root.add_child(g)


func _moss_cap(root: Node3D, at: Vector3, r: float) -> void:
	var m := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 0.7
	m.mesh = sph
	m.material_override = MeshUtil.mat(Color("4f7a35"), 1.0)
	m.position = at
	root.add_child(m)


func _arch(root: Node3D, stone: Material, dark: Material) -> void:
	for x in [-2.0, 2.0]:
		for y in 7:                                   # coursed pillar: alternating block widths
			var w := 1.3 if y % 2 == 0 else 1.15
			_block(root, stone, Vector3(w, 0.9, w), Vector3(x, y * 0.9, 0))
	_block(root, dark, Vector3(5.6, 0.8, 1.4), Vector3(0, 6.3, 0))   # lintel
	_block(root, stone, Vector3(1.0, 0.5, 1.0), Vector3(0, 7.1, 0))  # keystone
	_moss_cap(root, Vector3(-1.5, 7.1, 0), 0.8)
	_grass_on(root, Vector3(1.2, 7.1, 0), 0.6, 3)


func _shrine(root: Node3D, stone: Material, dark: Material) -> void:
	_block(root, dark, Vector3(5.0, 0.6, 5.0), Vector3(0, 0, 0))    # stepped base
	_block(root, stone, Vector3(4.2, 0.6, 4.2), Vector3(0, 0.6, 0))
	for x in [-1.6, 1.6]:
		for z in [-1.6, 1.6]:
			for y in 4:
				_block(root, stone, Vector3(0.7, 0.75, 0.7), Vector3(x, 1.2 + y * 0.75, z))
	_block(root, dark, Vector3(4.6, 0.6, 4.6), Vector3(0, 4.2, 0))  # roof slabs
	_block(root, stone, Vector3(3.2, 0.6, 3.2), Vector3(0, 4.8, 0))
	_block(root, dark, Vector3(1.6, 0.6, 1.6), Vector3(0, 5.4, 0))
	_moss_cap(root, Vector3(1.4, 4.8, 1.0), 0.9)
	_grass_on(root, Vector3(0, 5.4, 0), 1.4, 4)


func _pyramid(root: Node3D, stone: Material) -> void:
	for t in 5:
		var w := 7.0 - t * 1.4
		_block(root, stone, Vector3(w, 0.9, w), Vector3(0, t * 0.9, 0))
		_grass_on(root, Vector3(0, (t + 1) * 0.9, w * 0.42), w * 0.35, 2)
	_moss_cap(root, Vector3(0, 4.5, 0), 0.7)


func _column(root: Node3D, stone: Material, dark: Material) -> void:
	_block(root, dark, Vector3(2.0, 0.6, 2.0), Vector3(0, 0, 0))
	for y in 8:
		var c := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.62
		cyl.bottom_radius = 0.66
		cyl.height = 0.8
		cyl.radial_segments = 12
		c.mesh = cyl
		c.material_override = stone
		c.position = Vector3(0, 0.6 + y * 0.82 + 0.4, 0)
		root.add_child(c)
	_block(root, dark, Vector3(1.8, 0.5, 1.8), Vector3(0, 7.2, 0))  # capital
	_moss_cap(root, Vector3(0.3, 7.7, 0), 0.7)
	_grass_on(root, Vector3(0, 7.7, 0), 0.6, 2)
