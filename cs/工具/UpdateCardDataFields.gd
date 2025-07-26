@tool
extends EditorScript

# 此脚本用于批量更新CardData.tres文件中的字段名，使其符合v1.6规范
# 在Godot编辑器中，选择"脚本 > 运行"来执行此脚本

func _run():
	print("开始更新CardData.tres文件字段名...")
	
	var cards_dir = "res://assets/data/cards/"
	var dir = DirAccess.open(cards_dir)
	
	if not dir:
		print("错误：无法打开目录 " + cards_dir)
		return
	
	var updated_count = 0
	var error_count = 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var file_path = cards_dir + file_name
			if _update_card_file(file_path):
				updated_count += 1
				print("已更新: " + file_name)
			else:
				error_count += 1
				print("更新失败: " + file_name)
		
		file_name = dir.get_next()
	
	print("更新完成！")
	print("成功更新: %d 个文件" % updated_count)
	print("更新失败: %d 个文件" % error_count)

func _update_card_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("错误：无法读取文件 " + file_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# 执行字段名替换
	content = content.replace("card_id = ", "id = ")
	content = content.replace("card_suit = ", "suit = ")
	content = content.replace("card_name = ", "name = ")
	content = content.replace("wax_seal_types = ", "wax_seals = ")
	
	# 写回文件
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("错误：无法写入文件 " + file_path)
		return false
	
	file.store_string(content)
	file.close()
	
	return true
