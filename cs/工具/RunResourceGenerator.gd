@tool
extends EditorScript

# 这个脚本可以在编辑器中通过"工具 > 编辑器脚本..."菜单运行

func _run():
	print("开始生成卡牌强化资源...")
	
	# 获取增强资源生成器的实例并运行它
	var resource_generator = Node.new()
	resource_generator.set_script(load("res://cs/工具/ReinforcementResourceGenerator.gd"))
	resource_generator.name = "ResourceGenerator"
	
	# 手动调用生成方法
	resource_generator.generate_all_resources()
	
	print("强化资源生成完成!")
	
	# 清理
	resource_generator.free() 
