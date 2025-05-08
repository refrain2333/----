extends Node2D

# 游戏核心数据常量
const INITIAL_FOCUS: int = 5      # 初始集中力值
const INITIAL_ESSENCE: int = 3    # 初始精华值
const INITIAL_MANA: int = 0       # 初始学识魔力值
const INITIAL_LORE_POINTS: int = 4  # 初始学识点值
const MIN_RUNE_COST: int = 1      # 最小符文费用
const MAX_RUNE_COST: int = 8      # 最大符文费用

# 游戏状态变量 - 仅用于UI展示
var current_mana: int = INITIAL_MANA  # 当前学识魔力（原分数）
var target_mana: int = 300            # 目标学识魔力（原目标分数）
var focus_count: int = INITIAL_FOCUS  # 剩余集中力（原出牌次数）
var essence_count: int = INITIAL_ESSENCE  # 剩余精华（原弃牌次数）
var lore_points: int = INITIAL_LORE_POINTS  # 学识点（原金币）
var rune_cost: int = MIN_RUNE_COST    # 符文费用（原赌注）
var max_cost: int = MAX_RUNE_COST     # 最大符文费用（原最大赌注）
var total_runes: int = 52             # 符文库总数
var remaining_runes: int = 52         # 符文库剩余数量
var base_score: int = 50              # 当前出牌基础分数
var score_multiplier: int = 1         # 当前出牌倍数
var discovery_cards = []              # 魔法发现卡牌
var artifacts = []                    # 传奇法器
var max_discoveries: int = 3          # 最大魔法发现数量
var max_artifacts: int = 6            # 最大传奇法器数量

# 游戏状态文本
var current_status: String = "请选择要施放的奥术符文"

# 资源预加载 - 暂时注释，等待实际文件创建
# var rune_scene = preload("res://cs/符文系统/Rune.tscn")
# var rune_manager_script = preload("res://cs/符文系统/RuneManager.gd")

# 符文管理器 - 暂时注释
# var rune_manager

# 当前的手牌 - 暂时保留数组定义
var current_hand = []
# 已施放的符文 - 暂时保留数组定义
var cast_runes = []
# 当前回合数
var current_turn: int = 1

# 当节点加入场景树时调用
func _ready():
	# 初始化游戏状态 - 暂时只进行UI更新
	update_ui()
	
	# 显示拖放提示
	show_drop_hint(true)
	
	# 初始化魔法发现和传奇法器
	initialize_discoveries()
	initialize_artifacts()
	
	# 测试添加一些卡片
	# 添加两张魔法发现卡片
	add_discovery_card({"name": "火球术", "element": "fire"})
	add_discovery_card({"name": "冰霜新星", "element": "water"})
	
	# 添加三个传奇法器
	add_artifact({"name": "魔力水晶", "effect": "增幅"})
	add_artifact({"name": "时间沙漏", "effect": "复制"})
	add_artifact({"name": "元素指环", "effect": "变换"})
	
	# 暂时注释掉实际游戏逻辑
	"""
	# 初始化符文管理器
	rune_manager = rune_manager_script.new()
	add_child(rune_manager)
	
	# 初始化随机数生成器
	randomize()
	
	# 重置并洗牌
	rune_manager.reset_and_shuffle()
	
	# 发起始手牌
	deal_initial_hand()
	"""
	
# 更新界面上的所有文本标签
func update_ui():
	# 安全地更新学识魔力显示
	var mana_label = $UIContainer/SidePanel/VBoxContainer/ManaPanel/ManaLabel
	if is_instance_valid(mana_label):
		mana_label.text = str(current_mana)
	
	var target_value = $UIContainer/SidePanel/VBoxContainer/TargetPanel/ScoreContainer/TargetValue
	if is_instance_valid(target_value):
		target_value.text = str(target_mana)
	
	var focus_value = $UIContainer/SidePanel/VBoxContainer/ResourcePanel/MainResourcesContainer/ActionResourcesGrid/FocusValue
	if is_instance_valid(focus_value):
		focus_value.text = str(focus_count)
	
	var essence_value = $UIContainer/SidePanel/VBoxContainer/ResourcePanel/MainResourcesContainer/ActionResourcesGrid/EssenceValue
	if is_instance_valid(essence_value):
		essence_value.text = str(essence_count)
	
	var lore_value = $UIContainer/SidePanel/VBoxContainer/ResourcePanel/MainResourcesContainer/OtherResourcesGrid/LoreValue
	if is_instance_valid(lore_value):
		lore_value.text = str(lore_points)
	
	# 这个节点路径已被移除，因此注释掉这部分代码
	# var cost_value = $UIContainer/SidePanel/VBoxContainer/ResourcePanel/MainResourcesContainer/CostContainer/CostInfo/CostValue
	# if is_instance_valid(cost_value):
	#    cost_value.text = str(rune_cost) + " / " + str(max_cost)
	
	# 更新符文库计数器
	var count_value_label = $UIContainer/RuneLibraryPanel/RuneLibraryContainer/CountContainer/CountValueLabel
	if is_instance_valid(count_value_label):
		count_value_label.text = str(remaining_runes) + " / " + str(total_runes)
	
	# 更新魔法发现计数器
	update_discovery_count()
	
	# 更新传奇法器计数器
	update_artifact_count()
	
	# 更新学年和学期信息
	var year_value = $UIContainer/SidePanel/VBoxContainer/GameProgressPanel/ProgressContainer/ProgressTable/YearValue
	if is_instance_valid(year_value):
		year_value.text = "第" + str(current_turn) + "学年"
	
	var term_value = $UIContainer/SidePanel/VBoxContainer/GameProgressPanel/ProgressContainer/ProgressTable/TermValue
	if is_instance_valid(term_value):
		term_value.text = str(current_turn) + "/4"
	
	# 更新分数面板
	update_score_panel()

# 更新分数面板显示
func update_score_panel():
	var base_score_value = $UIContainer/SidePanel/VBoxContainer/ScorePanel/ScoreContainer/BaseScoreBox/ScoreValue
	if is_instance_valid(base_score_value):
		base_score_value.text = str(base_score)
	
	var multiplier_value = $UIContainer/SidePanel/VBoxContainer/ScorePanel/ScoreContainer/MultiplierBox/MultiplierValue
	if is_instance_valid(multiplier_value):
		multiplier_value.text = "x" + str(score_multiplier)

# 设置基础分数和倍数
func set_score_values(new_base: int, new_mult: int):
	base_score = new_base
	score_multiplier = new_mult
	update_score_panel()
	
	# 计算总分并显示在状态栏
	var total = base_score * score_multiplier
	set_status("奥术共鸣生效！基础分数 " + str(base_score) + " × 倍数 " + str(score_multiplier) + " = " + str(total) + " 点学识魔力")

# 设置状态文本
func set_status(text: String):
	current_status = text
	
	# StatusPanel已移除，将状态消息打印到控制台
	print("游戏状态: " + current_status)

# 显示或隐藏拖放提示
func show_drop_hint(is_visible: bool):
	# 因为已经移除了CenterHint节点，所以此函数不再需要实际操作
	# 保留函数以避免其他部分代码调用时出错
	pass

# 重置游戏状态到初始值
func reset_game_state():
	# 重置所有状态变量为初始值
	current_mana = INITIAL_MANA
	focus_count = INITIAL_FOCUS
	essence_count = INITIAL_ESSENCE
	lore_points = INITIAL_LORE_POINTS
	rune_cost = MIN_RUNE_COST
	remaining_runes = total_runes
	
	# 更新UI显示
	update_ui()
	set_status("游戏已重置，请开始新的奥术旅程")

# 按钮回调函数 - 仅保留UI排序相关功能
func sort_cards_by_value():
	# 实际排序功能暂时移除，仅更新状态文本
	set_status("符文已按能量强度排序")

# 按钮回调函数 - 仅保留UI排序相关功能
func sort_cards_by_suit():
	# 实际排序功能暂时移除，仅更新状态文本
	set_status("符文已按元素类型排序")

# 新增功能 - 处理减少符文费用按钮
func _on_minus_button_pressed():
	if rune_cost > MIN_RUNE_COST:
		rune_cost -= 1
		update_ui()
		set_status("符文费用减少至 " + str(rune_cost))

# 新增功能 - 处理增加符文费用按钮
func _on_plus_button_pressed():
	if rune_cost < max_cost:
		rune_cost += 1
		update_ui()
		set_status("符文费用增加至 " + str(rune_cost))

# 新增功能 - 处理施放符文按钮
func _on_play_button_pressed():
	if focus_count > 0:
		focus_count -= 1
		update_ui()
		set_status("施放了一个符文，消耗1点集中力")
	else:
		set_status("集中力已耗尽，请使用精华恢复功能")

# 新增功能 - 处理施放精华按钮
func _on_discard_button_pressed():
	if essence_count > 0:
		essence_count -= 1
		focus_count = INITIAL_FOCUS  # 重置集中力
		update_ui()
		set_status("已消耗精华，恢复集中力")
	else:
		set_status("精华已耗尽")

# 接收卡牌放置在出牌区的信号
# 这个函数会被卡牌实例调用，检查是否可以放置在出牌区
func check_card_in_play_area(card_instance) -> bool:
	# 现在使用按钮出牌，不再需要检测拖放位置
	# 保留函数以兼容旧代码
	# 直接返回false，表示卡牌应该回到原位
	return false

# 处理卡牌被打出
func handle_card_played(card_instance):
	# 安全检查
	if not is_instance_valid(card_instance):
		print("错误：无效的卡牌实例")
		return
	
	# 使用安全方法获取卡牌名称
	var card_name = "未知符文"
	if card_instance.has_method("get_card_name"):
		card_name = card_instance.get_card_name()
	
	print("打出卡牌: ", card_name)
	
	# 将卡牌从手牌中移除
	current_hand.erase(card_instance)
	
	# 将卡牌添加到已打出的牌中
	cast_runes.append(card_instance)
	
	# 调整已打出卡牌的位置
	arrange_played_cards()
	
	# 减少剩余出牌次数
	reduce_plays_left()
	
	# 评估牌型和分数
	if cast_runes.size() >= 1:
		evaluate_played_cards()

# 排列已打出的卡牌
func arrange_played_cards():
	# 使用视口中心作为放牌区域中心
	var center_x = get_viewport_rect().size.x / 2.0
	var center_y = get_viewport_rect().size.y / 2.0 - 50  # 略微上移以避开手牌区域
	
	# 计算卡牌的间距和起始位置
	var card_spacing = 120
	var start_x = center_x - (cast_runes.size() - 1) * card_spacing / 2.0
	
	# 排列卡牌
	for i in range(cast_runes.size()):
		var card = cast_runes[i]
		
		# 安全检查
		if not is_instance_valid(card):
			print("警告：跳过无效的卡牌实例")
			continue
		
		# 计算目标位置
		var target_pos = Vector2(start_x + i * card_spacing, center_y)
		
		# 创建一个补间动画使卡牌平滑移动
		var tween = create_tween()
		tween.tween_property(card, "global_position", target_pos, 0.3)
		
		# 更新卡牌的原始位置（这样如果玩家再次拖动卡牌，它会返回到这个位置）
		if card.has_method("set_original_position") or card.get("original_position") != null:
			card.original_position = target_pos

# 以下是游戏核心逻辑函数，目前部分功能与UI操作重叠
# 后续实现完整卡牌系统时将整合这些函数

# 减少剩余出牌次数
func reduce_plays_left():
	# 注意：此函数与_on_play_button_pressed重复，保留以便兼容其他代码
	focus_count -= 1
	if focus_count < 0:
		focus_count = 0  # 确保不会变为负数
	update_ui()
	# 检查是否无法出牌
	if focus_count <= 0:
		handle_no_plays_left()

# 处理出牌次数用尽
func handle_no_plays_left():
	if essence_count > 0:
		set_status("集中力已耗尽，请使用\"精华\"获取新手牌")
	else:
		handle_game_over()

# 处理游戏结束
func handle_game_over():
	if current_mana >= target_mana:
		set_status("游戏成功完成！最终学识魔力：" + str(current_mana))
	else:
		set_status("游戏失败！未达到目标学识魔力" + str(target_mana))

# 添加分数
func add_score(value: int):
	current_mana += value
	update_ui()
	# 检查是否达到目标分数
	check_level_completion()

# 检查关卡完成
func check_level_completion():
	if current_mana >= target_mana:
		set_status("恭喜！达到目标学识魔力" + str(target_mana) + "，学业试炼完成！")

# 评估已打出的牌并计算分数
func evaluate_played_cards():
	# 这里会有具体的牌型判断逻辑
	# 暂时使用模拟数据
	var score = rune_cost * 50  # 简单示例：分数 = 费用 x 50
	var multiplier = 1  # 默认倍数为1
	
	# 模拟不同牌型的倍数
	if cast_runes.size() >= 3:
		multiplier = 2  # 假设3张牌有特殊组合，倍数为2
	if cast_runes.size() >= 5:
		multiplier = 3  # 假设5张牌有特殊组合，倍数为3
	
	# 设置并更新分数面板
	set_score_values(score, multiplier)
	
	# 添加总分
	var total_score = score * multiplier
	add_score(total_score)
	
	# 清空已打出的牌
	clear_played_cards()

# 清空已打出的牌
func clear_played_cards():
	# 移除所有已打出的卡牌实例
	for card in cast_runes:
		if is_instance_valid(card):
			card.queue_free()
	
	# 清空数组
	cast_runes.clear()

# 卡牌拖放相关功能和完整的卡牌系统将在后续实现

# 新增功能 - 处理设置按钮点击
func _on_settings_button_pressed():
	set_status("设置菜单即将开放...")
	# 在此添加打开设置菜单的代码
	# 例如: $SettingsMenu.show()
	pass

# 初始化魔法发现卡牌
func initialize_discoveries():
	# 检查魔法发现容器是否存在
	var discovery_container = $UIContainer/MagicDiscoveryPanel/DiscoveryContainer
	if not is_instance_valid(discovery_container):
		print("错误：找不到魔法发现容器")
		return
		
	# 设置容器的属性，为后续动态添加卡片做准备
	# 例如可以预设一些自定义属性
	discovery_container.set_meta("max_cards", max_discoveries)  # 最多可添加3张卡片
	discovery_container.set_meta("card_size", Vector2(135, 180))  # 卡片标准尺寸
	
	# 更新计数器显示
	update_discovery_count()
	
	set_status("魔法发现就绪，等待奇迹出现")

# 初始化传奇法器区域
func initialize_artifacts():
	# 检查传奇法器容器是否存在
	var artifact_container = $UIContainer/ArtifactPanel/ArtifactContainer
	if not is_instance_valid(artifact_container):
		print("错误：找不到传奇法器容器")
		return
		
	# 设置容器的属性，为后续动态添加法器做准备
	artifact_container.set_meta("max_artifacts", max_artifacts)  # 最多可添加6个法器
	artifact_container.set_meta("artifact_size", Vector2(135, 180))  # 法器标准尺寸
	
	# 更新计数器显示
	update_artifact_count()
	
	set_status("传奇法器区已准备，等待奥术收集")

# 更新魔法发现计数
func update_discovery_count():
	var count_label = $UIContainer/MagicDiscoveryPanel/DiscoveryCountLabel
	if is_instance_valid(count_label):
		count_label.text = str(discovery_cards.size()) + " / " + str(max_discoveries)

# 更新传奇法器计数
func update_artifact_count():
	var count_label = $UIContainer/ArtifactPanel/ArtifactCountLabel
	if is_instance_valid(count_label):
		count_label.text = str(artifacts.size()) + " / " + str(max_artifacts)

# 添加新的魔法发现卡牌
func add_discovery_card(card_data):
	var discovery_container = $UIContainer/MagicDiscoveryPanel/DiscoveryContainer
	if not is_instance_valid(discovery_container):
		print("错误：找不到魔法发现容器")
		return
		
	# 检查是否超过最大数量
	if discovery_cards.size() >= max_discoveries:
		print("警告：已达到最大魔法发现数量")
		return
		
	# 从卡片场景创建一个新的卡片实例
	# 这里仅作为示例，实际代码需要等卡片场景创建后再实现
	"""
	var card_scene = load("res://cs/符文系统/DiscoveryCard.tscn")
	var card_instance = card_scene.instantiate()
	
	# 设置卡片数据
	card_instance.setup(card_data)
	
	# 添加到容器
	discovery_container.add_child(card_instance)
	"""
	
	# 临时使用ColorRect作为占位符
	var temp_card = ColorRect.new()
	temp_card.custom_minimum_size = Vector2(135, 180)
	temp_card.color = Color(0.156863, 0.223529, 0.423529, 0.5)
	discovery_container.add_child(temp_card)
	
	# 添加到卡片数组并更新计数
	discovery_cards.append(temp_card)
	update_discovery_count()
	
	set_status("发现了新的魔法！")
	
# 添加新的传奇法器
func add_artifact(artifact_data):
	var artifact_container = $UIContainer/ArtifactPanel/ArtifactContainer
	if not is_instance_valid(artifact_container):
		print("错误：找不到传奇法器容器")
		return
		
	# 检查是否超过最大数量
	if artifacts.size() >= max_artifacts:
		print("警告：已达到最大传奇法器数量")
		return
		
	# 从法器场景创建一个新的法器实例
	# 这里仅作为示例，实际代码需要等法器场景创建后再实现
	"""
	var artifact_scene = load("res://cs/符文系统/Artifact.tscn")
	var artifact_instance = artifact_scene.instantiate()
	
	# 设置法器数据
	artifact_instance.setup(artifact_data)
	
	# 添加到容器
	artifact_container.add_child(artifact_instance)
	"""
	
	# 临时使用ColorRect作为占位符
	var temp_artifact = ColorRect.new()
	temp_artifact.custom_minimum_size = Vector2(135, 180)
	temp_artifact.color = Color(0.156863, 0.223529, 0.423529, 0.5)
	artifact_container.add_child(temp_artifact)
	
	# 添加到法器数组并更新计数
	artifacts.append(temp_artifact)
	update_artifact_count()
	
	set_status("获得了一件传奇法器！")

# 移除魔法发现卡牌
func remove_discovery_card(index):
	if index < 0 or index >= discovery_cards.size():
		print("错误：无效的魔法发现索引")
		return
		
	var card = discovery_cards[index]
	if is_instance_valid(card):
		card.queue_free()
		
	discovery_cards.remove_at(index)
	update_discovery_count()
	
# 移除传奇法器
func remove_artifact(index):
	if index < 0 or index >= artifacts.size():
		print("错误：无效的传奇法器索引")
		return
		
	var artifact = artifacts[index]
	if is_instance_valid(artifact):
		artifact.queue_free()
		
	artifacts.remove_at(index)
	update_artifact_count()
