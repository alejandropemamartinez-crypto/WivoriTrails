extends RefCounted

# Replace the save only after the temporary file is complete. Keep the last
# valid save as a backup and accept the existing v1 files during migration.
static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = parser.data
	if not data is Dictionary:
		return {}
	var version: Variant = data.get("version")
	if not version is float and not version is int:
		return {}
	if int(version) not in [1, 2]:
		return {}
	return data

static func load_data(path: String) -> Dictionary:
	for candidate in [path, path + ".bak", path + ".tmp"]:
		var data := _read(candidate)
		if not data.is_empty():
			return data
	return {}

static func write_data(path: String, data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or _read(temporary).is_empty():
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if not _read(path).is_empty():
		var backup_temporary := absolute + ".bak.tmp"
		if DirAccess.copy_absolute(absolute, backup_temporary) != OK:
			return false
		if DirAccess.rename_absolute(backup_temporary, absolute + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) == OK

static func number(data: Dictionary, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value: Variant = data.get(key, fallback)
	if (not value is int and not value is float) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), minimum, maximum)

static func position(value: Variant, fallback: Vector3) -> Vector3:
	if not value is Array or value.size() != 2:
		return fallback
	return Vector3(number({"x":value[0]}, "x", fallback.x, -23, 23), 0,
		number({"z":value[1]}, "z", fallback.z, -23, 23))
