class_name DiscoveryManager
extends Node

var main_game  # 引用主场景
var artifact_container: HBoxContainer
var discovery_container: HBoxContainer

func _init(game_scene):
	main_game = game_scene

func setup(disc_container: HBoxContainer, art_container: HBoxContainer):
	discovery_container = disc_container
	artifact_container = art_container

# 初始化魔法发现卡牌
func initialize_discoveries():
	# 检查魔法发现容器是否存在
	if not is_instance_valid(discovery_container):
		print("错误：找不到魔法发现容器")
		return
		
	# 设置容器的属性，为后续动态添加卡片做准备
	# 例如可以预设一些自定义属性
	discovery_container.set_meta("max_cards", GameManager.max_discoveries)  # 最多可添加3张卡片
	discovery_container.set_meta("card_size", Vector2(135, 180))  # 卡片标准尺寸
	
	# 更新计数器显示
	update_discovery_count()
	
	main_game.ui_manager.set_status("魔法发现就绪，等待奇迹出现")

# 初始化传奇法器区域
func initialize_artifacts():
	# 检查传奇法器容器是否存在
	if not is_instance_valid(artifact_container):
		print("错误：找不到传奇法器容器")
		return
		
	# 设置容器的属性，为后续动态添加法器做准备
	artifact_container.set_meta("max_artifacts", GameManager.max_artifacts)  # 最多可添加6个法器
	artifact_container.set_meta("artifact_size", Vector2(135, 180))  # 法器标准尺寸
	
	# 更新计数器显示
	update_artifact_count()
	
	main_game.ui_manager.set_status("传奇法器区已准备，等待奥术收集")

# 更新魔法发现计数
func update_discovery_count():
	var count_label = main_game.get_node("UIContainer/TopDock/MagicDiscoveryPanel/DiscoveryCountLabel")
	if is_instance_valid(count_label):
		count_label.text = str(GameManager.discovery_cards.size()) + " / " + str(GameManager.max_discoveries)

# 更新传奇法器计数
func update_artifact_count():
	var count_label = main_game.get_node("UIContainer/TopDock/ArtifactPanel/ArtifactCountLabel")
	if is_instance_valid(count_label):
		count_label.text = str(GameManager.artifacts.size()) + " / " + str(GameManager.max_artifacts)

# 添加新的魔法发现卡牌
func add_discovery_card(card_data):
	if not is_instance_valid(discovery_container):
		print("错误：找不到魔法发现容器")
		return
		
	# 使用GameManager添加魔法发现
	if not GameManager.add_discovery(card_data):
		print("警告：已达到最大魔法发现数量")
		return
	
	# 临时使用ColorRect作为占位符
	var temp_card = ColorRect.new()
	temp_card.custom_minimum_size = Vector2(135, 180)
	temp_card.color = Color(0.156863, 0.223529, 0.423529, 0.5)
	discovery_container.add_child(temp_card)
	
	main_game.ui_manager.set_status("发现了新的魔法！")
	
# 添加新的传奇法器
func add_artifact(artifact_data):
	if not is_instance_valid(artifact_container):
		print("错误：找不到传奇法器容器")
		return
		
	# 使用GameManager添加传奇法器
	if not GameManager.add_artifact(artifact_data):
		print("警告：已达到最大传奇法器数量")
		return
	
	# 临时使用ColorRect作为占位符
	var temp_artifact = ColorRect.new()
	temp_artifact.custom_minimum_size = Vector2(135, 180)
	temp_artifact.color = Color(0.156863, 0.223529, 0.423529, 0.5)
	artifact_container.add_child(temp_artifact)
	
	main_game.ui_manager.set_status("获得了一件传奇法器！")

# 移除魔法发现卡牌
func remove_discovery_card(index):
	if index < 0 or index >= GameManager.discovery_cards.size():
		print("错误：无效的魔法发现索引")
		return
		
	# 获取对应的显示节点
	if discovery_container.get_child_count() > index:
		var card = discovery_container.get_child(index)
		if is_instance_valid(card):
			card.queue_free()
	
	# 从GameManager中移除数据
	GameManager.discovery_cards.remove_at(index)
	update_discovery_count()
	
# 移除传奇法器
func remove_artifact(index):
	if index < 0 or index >= GameManager.artifacts.size():
		print("错误：无效的传奇法器索引")
		return
		
	# 获取对应的显示节点
	if artifact_container.get_child_count() > index:
		var artifact = artifact_container.get_child(index)
		if is_instance_valid(artifact):
			artifact.queue_free()
	
	# 从GameManager中移除数据
	GameManager.artifacts.remove_at(index)
	update_artifact_count()

# 添加测试用的魔法发现卡牌
func add_test_discoveries():
	add_discovery_card({"name": "火球术", "element": "fire"})
	add_discovery_card({"name": "冰霜新星", "element": "water"})
	
# 添加测试用的传奇法器
func add_test_artifacts():
	add_artifact({"name": "魔力水晶", "effect": "增幅"})
	add_artifact({"name": "时间沙漏", "effect": "复制"})
	add_artifact({"name": "元素指环", "effect": "变换"}) 