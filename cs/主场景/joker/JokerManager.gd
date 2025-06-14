class_name JokerManager
extends Node

var main_game  # 引用主场景
var joker_container: HBoxContainer
var joker_card_scene = preload("res://cs/卡牌系统/视图/JokerCard.tscn")

func _init(game_scene):
	main_game = game_scene

func setup(container: HBoxContainer):
	joker_container = container

# 初始化小丑卡区域
func initialize_jokers():
	# 检查小丑卡容器是否存在
	if not is_instance_valid(joker_container):
		print("警告：小丑卡容器不存在，跳过初始化")
		return
	
	# 设置容器的属性
	joker_container.set_meta("max_jokers", GameManager.max_jokers)
	
	# 更新小丑卡计数
	update_joker_count()
	
	main_game.ui_manager.set_status("小丑卡区域已准备就绪")

# 更新小丑卡显示
func update_joker_display():
	# 检查小丑卡容器是否存在
	if not is_instance_valid(joker_container):
		print("警告：找不到小丑卡容器，无法更新小丑卡显示")
		return
		
	# 清空当前小丑卡区域
	for child in joker_container.get_children():
		child.queue_free()
	
	# 创建并放置小丑卡
	for i in range(GameManager.active_jokers.size()):
		var joker_data = GameManager.active_jokers[i]
		var joker_instance = joker_card_scene.instantiate()
		joker_container.add_child(joker_instance)
		
		# 设置小丑卡数据
		joker_instance.setup(joker_data)
		
		# 连接小丑卡信号
		joker_instance.joker_clicked.connect(_on_joker_clicked)
	
	# 更新计数
	update_joker_count()
	
	print("更新小丑卡显示，共%d张" % GameManager.active_jokers.size())

# 处理小丑卡点击
func _on_joker_clicked(joker_view):
	var joker_data = joker_view.get_joker_data()
	
	# 在此可以添加选择小丑卡的逻辑，类似于选择普通卡牌
	# 例如：
	# var index = selected_jokers.find(joker_view)
	# if index != -1:
	#     selected_jokers.remove_at(index)
	#     joker_view.set_selected(false)
	# else:
	#     selected_jokers.append(joker_view)
	#     joker_view.set_selected(true)
	
	# 显示小丑卡信息
	main_game.ui_manager.set_status("小丑卡: " + joker_data.name + " - " + joker_data.effect_description)

# 更新小丑卡计数
func update_joker_count():
	var count_label = main_game.get_node("UIContainer/JokerPanel/JokerCountLabel")
	if is_instance_valid(count_label):
		count_label.text = str(GameManager.active_jokers.size()) + " / " + str(GameManager.max_jokers)
	else:
		print("警告：找不到小丑卡计数标签")

# 添加小丑卡到界面
func add_joker(joker_data):
	if not is_instance_valid(joker_container):
		print("错误：找不到小丑卡容器")
		return
		
	# 使用GameManager添加小丑卡
	if not GameManager.add_joker(joker_data):
		print("警告：已达到最大小丑卡数量")
		return
	
	# 更新小丑卡显示
	update_joker_display()
	
	main_game.ui_manager.set_status("获得了一张小丑卡：" + joker_data.name)

# 提供小丑卡选择
func offer_joker_choice():
	var offered_jokers = GameManager.offer_jokers()
	if offered_jokers.size() == 0:
		main_game.ui_manager.set_status("没有可用的小丑卡")
		return
	
	main_game.ui_manager.set_status("选择一张小丑卡")
	
	# 这里可以添加显示小丑卡选择界面的代码
	# 为了示例，我们直接选择第一张
	if offered_jokers.size() > 0:
		add_joker(offered_jokers[0])

# 添加测试用的小丑卡
func add_test_jokers():
	var common_joker = JokerData.create_joker("common_joker")
	add_joker(common_joker)
	
	var greedy_joker = JokerData.create_joker("greedy_joker")
	add_joker(greedy_joker) 
