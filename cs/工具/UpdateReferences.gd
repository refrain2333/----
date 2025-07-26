@tool
extends EditorScript

# 此脚本用于更新项目中的引用路径
# 在Godot编辑器中，选择"脚本 > 运行"来执行此脚本

func _run():
	print("开始更新项目引用...")
	
	# 定义路径映射（旧路径 -> 新路径）
	var path_mappings = {
		"res://cs/主场景/abilities/ArtifactData.gd": "res://cs/卡牌系统/数据/ArtifactData.gd",
		"res://cs/主场景/abilities/JokerData.gd": "res://cs/卡牌系统/数据/JokerData.gd",
		"res://cs/主场景/abilities/SpellData.gd": "res://cs/卡牌系统/数据/SpellData.gd",
		"res://cs/主场景/card/CardEffectManager.gd": "res://cs/卡牌系统/控制/CardEffectManager.gd",
		"res://cs/主场景/card/CardManager.gd": "res://cs/卡牌系统/数据/管理器/CardManager.gd",
		"res://cs/主场景/discovery/DiscoveryManager.gd": "res://cs/卡牌系统/数据/管理器/DiscoveryManager.gd",
		"res://cs/主场景/joker/JokerManager.gd": "res://cs/卡牌系统/数据/管理器/JokerManager.gd"
	}
	
	# 遍历项目中的所有脚本和场景文件
	var dir = DirAccess.open("res://")
	if dir:
		_process_directory(dir, path_mappings)
	
	print("引用更新完成！")

# 递归处理目录
func _process_directory(dir: DirAccess, path_mappings: Dictionary):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			var sub_dir = DirAccess.open(full_path)
			if sub_dir:
				_process_directory(sub_dir, path_mappings)
		elif file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			_update_file_references(full_path, path_mappings)
			
		file_name = dir.get_next()

# 更新文件中的引用
func _update_file_references(file_path: String, path_mappings: Dictionary):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("无法打开文件: " + file_path)
		return
		
	var content = file.get_as_text()
	file.close()
	
	var modified = false
	
	# 检查并替换所有映射的路径
	for old_path in path_mappings:
		var new_path = path_mappings[old_path]
		
		if content.contains(old_path):
			content = content.replace(old_path, new_path)
			modified = true
			print("在 " + file_path + " 中更新了引用: " + old_path + " -> " + new_path)
	
	# 如果有修改，保存文件
	if modified:
		file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(content)
			file.close()
			print("已保存修改到: " + file_path)
		else:
			print("无法写入文件: " + file_path) 