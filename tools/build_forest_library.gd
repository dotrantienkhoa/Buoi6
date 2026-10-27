@tool
extends EditorScript

## Dựng assets/meshes/forest_library.tscn từ 32 file .glb trong assets/grid_map/forest.
## Đây là bản script của việc kéo từng model vào scene rồi Mesh | Create Collision Shape.
##
## Cách chạy: mở file này trong Script Editor rồi bấm **File | Run** (Ctrl + Shift + X).
## Kết quả in ra bảng **Output** ở dưới.

const SOURCE_DIR := "res://assets/grid_map/forest"
const OUTPUT := "res://assets/meshes/forest_library.tscn"

## Các model xếp thành hàng cho dễ nhìn trong editor. Vị trí này KHÔNG được bake vào thư viện
## (xuất với Apply MeshInstance Transforms tắt), nên xếp đâu cũng được.
const SHELF_SPACING := 3.0
const SHELF_COLUMNS := 8


func _run() -> void:
	var dir := DirAccess.open(SOURCE_DIR)
	if dir == null:
		push_error("Không mở được %s" % SOURCE_DIR)
		return
	var files := dir.get_files()
	files.sort()

	var root := Node3D.new()
	root.name = "ForestLibrary"
	var index := 0
	for file: String in files:
		if not file.ends_with(".glb"):
			continue
		var item_name := file.get_basename()
		var mesh := _load_mesh(SOURCE_DIR + "/" + file)
		if mesh == null:
			push_warning("%s: không tìm thấy MeshInstance3D" % file)
			continue

		var instance := MeshInstance3D.new()
		instance.name = item_name
		instance.mesh = mesh
		instance.position = Vector3((index % SHELF_COLUMNS) * SHELF_SPACING, 0.0,
			(index / SHELF_COLUMNS) * SHELF_SPACING)
		root.add_child(instance)
		instance.owner = root

		var body := StaticBody3D.new()
		body.name = "StaticBody3D"
		instance.add_child(body)
		body.owner = root

		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shaped := _shape_for(item_name, mesh)
		collision.shape = shaped[0]
		collision.transform = shaped[1]
		body.add_child(collision)
		collision.owner = root

		print("  %-24s %s" % [item_name, shaped[2]])
		index += 1

	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, OUTPUT)
	if error != OK:
		push_error("Lưu %s thất bại: %d" % [OUTPUT, error])
		return
	print("Đã dựng %s với %d item" % [OUTPUT, index])
	root.free()
	# Bắt FileSystem quét lại để file vừa ghi hiện ra ngay trong dock, khỏi phải mở lại project.
	EditorInterface.get_resource_filesystem().scan()


## Trả về [shape, transform, tên để in ra] cho một item.
##
## Hiện tại mọi model đều dùng trimesh — đúng như Mesh | Create Collision Shape | Trimesh
## mà bạn bấm bằng tay. Chạy thử rồi quay lại đây: có một loại model không dùng trimesh được.
## Xem mục "Chạy thử: Cáo kẹt ở chân thang" trong tài liệu.
func _shape_for(item_name: String, mesh: Mesh) -> Array:
	return [mesh.create_trimesh_shape(), Transform3D.IDENTITY, "trimesh"]


func _load_mesh(path: String) -> Mesh:
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var root := scene.instantiate()
	var found := _find_mesh(root)
	var mesh: Mesh = found.mesh if found != null else null
	root.free()
	return mesh


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result := _find_mesh(child)
		if result != null:
			return result
	return null
