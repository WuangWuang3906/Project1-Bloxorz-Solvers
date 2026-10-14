class_name MeshUtil
extends RefCounted
## Procedural meshes and materials shared by the board and the block.


## Box with rounded edges: a subdivided box whose vertices near the edges are
## pushed onto a sphere of `radius` around the inner box.
static func rounded_box(size: Vector3, radius: float) -> ArrayMesh:
	var box := BoxMesh.new()
	box.size = size
	box.subdivide_width = int(ceil(size.x / radius))
	box.subdivide_height = int(ceil(size.y / radius))
	box.subdivide_depth = int(ceil(size.z / radius))
	var arrays := box.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var inner := size * 0.5 - Vector3.ONE * radius
	for i in verts.size():
		var v := verts[i]
		var core := v.clamp(-inner, inner)
		var d := v - core
		if d.length() > 0.00001:
			var n := d.normalized()
			verts[i] = core + n * radius
			normals[i] = n
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func mat(color: Color, roughness: float = 0.5, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func glow(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := mat(color, 0.3)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
