@tool
extends EditorScript

# 此脚本用于删除已经移动到新位置的旧文件
# 在Godot编辑器中，选择"脚本 > 运行"来执行此脚本

func _run():
	print("开始清理旧文件...")
	
	# 定义要删除的旧文件列表
	var old_files = [
		"res://cs/主场景/abilities/ArtifactData.gd",
		"res://cs/主场景/abilities/JokerData.gd",
		"res://cs/主场景/abilities/SpellData.gd",
		"res://cs/主场景/card/CardEffectManager.gd",
		"res://cs/主场景/card/CardManager.gd",
		"res://cs/主场景/discovery/DiscoveryManager.gd",
		"res://cs/主场景/joker/JokerManager.gd"
	]
	
	# 删除旧文件
	for file_path in old_files:
		if FileAccess.file_exists(file_path):
			var dir = DirAccess.open("res://")
			if dir.remove_at(file_path) == OK:
				print("已删除: " + file_path)
			else:
				print("无法删除: " + file_path)
		else:
			print("文件不存在: " + file_path)
	
	print("清理完成！")
	
	# 提示用户重新打开项目
	print("\n重要提示：")
	print("为了确保所有更改生效，请保存所有文件并重新打开项目。") 