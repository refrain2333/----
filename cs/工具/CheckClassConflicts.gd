@tool
extends EditorScript

# 此脚本用于检查项目中的类名冲突
# 在Godot编辑器中，选择"脚本 > 运行"来执行此脚本

func _run():
	print("开始检查类名冲突...")
	
	# 收集所有脚本文件
	var scripts = []
	var dir = DirAccess.open("res://")
	if dir:
		_collect_scripts(dir, scripts)
	
	# 检查类名冲突
	var class_map = {}  # 类名 -> 文件路径列表
	
	for script_path in scripts:
		var file = FileAccess.open(script_path, FileAccess.READ)
		if not file:
			continue
			
		var content = file.get_as_text()
		file.close()
		
		# 查找class_name定义
		var class_name_regex = RegEx.new()
		class_name_regex.compile("class_name\\s+([A-Za-z0-9_]+)")
		var result = class_name_regex.search(content)
		
		if result:
			var class_name_value = result.get_string(1)
			if not class_map.has(class_name_value):
				class_map[class_name_value] = []
			class_map[class_name_value].append(script_path)
	
	# 输出冲突
	var has_conflicts = false
	for class_name_value in class_map:
		if class_map[class_name_value].size() > 1:
			has_conflicts = true
			print("发现类名冲突: " + class_name_value)
			print("  冲突文件:")
			for path in class_map[class_name_value]:
				print("  - " + path)
	
	if not has_conflicts:
		print("没有发现类名冲突！")
	else:
		print("警告：存在类名冲突，请解决这些冲突以避免编译错误。")
		print("解决方法：")
		print("1. 重命名其中一个类")
		print("2. 移除重复的类定义")
		print("3. 合并功能到一个类中")

# 递归收集脚本文件
func _collect_scripts(dir: DirAccess, scripts: Array):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			var sub_dir = DirAccess.open(full_path)
			if sub_dir:
				_collect_scripts(sub_dir, scripts)
		elif file_name.ends_with(".gd"):
			scripts.append(full_path)
			
		file_name = dir.get_next() 