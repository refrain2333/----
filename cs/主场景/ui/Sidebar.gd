class_name Sidebar
extends Panel

# 节点引用
@onready var mana_label = $VBoxContainer/ManaPanel/ManaLabel
@onready var focus_value = $VBoxContainer/ResourcePanel/MainResourcesContainer/ActionResourcesGrid/FocusValue
@onready var essence_value = $VBoxContainer/ResourcePanel/MainResourcesContainer/ActionResourcesGrid/EssenceValue
@onready var lore_value = $VBoxContainer/ResourcePanel/MainResourcesContainer/OtherResourcesGrid/LoreValue
@onready var score_value = $VBoxContainer/ScorePanel/ScoreContainer/BaseScoreBox/ScoreValue
@onready var multiplier_value = $VBoxContainer/ScorePanel/ScoreContainer/MultiplierBox/MultiplierValue
@onready var target_value = $VBoxContainer/TargetPanel/ScoreContainer/TargetValue
@onready var reward_value = $VBoxContainer/TargetPanel/RewardContainer/RewardValue
@onready var year_value = $VBoxContainer/GameProgressPanel/ProgressContainer/ProgressTable/YearValue
@onready var term_value = $VBoxContainer/GameProgressPanel/ProgressContainer/ProgressTable/TermValue

# 信号
signal settings_button_pressed

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("sidebar", self)
	
	# 初始化UI
	update_ui()

# 更新UI
func update_ui():
	# 设置默认值
	set_mana(0)
	set_focus(5)
	set_essence(3)
	set_lore(4)
	set_score(50)
	set_multiplier(1)
	set_target(300)
	set_reward(10)
	set_year(1)
	set_term(1, 4)

# 设置魔力值
func set_mana(value: int):
	if mana_label:
		mana_label.text = str(value)
		print("Sidebar.set_mana: 更新学识魔力显示为 %d" % value)

# 设置集中力
func set_focus(value: int):
	if focus_value:
		focus_value.text = str(value)

# 设置精华
func set_essence(value: int):
	if essence_value:
		essence_value.text = str(value)

# 设置学识点
func set_lore(value: int):
	if lore_value:
		lore_value.text = str(value)

# 设置分数
func set_score(value: int):
	if score_value:
		score_value.text = str(value)
		print("Sidebar.set_score: 更新当次得分显示为 %d" % value)
		
		# 添加动画效果（使用固定字体大小）
		var default_size = 16  # 默认字体大小
		var tween = create_tween()
		tween.tween_property(score_value, "theme_override_font_sizes/font_size", default_size * 1.2, 0.1)
		tween.tween_property(score_value, "theme_override_font_sizes/font_size", default_size, 0.2)

# 设置倍率
func set_multiplier(value: int):
	if multiplier_value:
		multiplier_value.text = "x" + str(value)
		print("Sidebar.set_multiplier: 更新倍率显示为 x%d" % value)
		
		# 添加动画效果（使用固定字体大小）
		var default_size = 16  # 默认字体大小
		var tween = create_tween()
		tween.tween_property(multiplier_value, "theme_override_font_sizes/font_size", default_size * 1.2, 0.1)
		tween.tween_property(multiplier_value, "theme_override_font_sizes/font_size", default_size, 0.2)

# 设置目标分数
func set_target(value: int):
	if target_value:
		target_value.text = str(value)

# 设置奖励
func set_reward(value: int):
	if reward_value:
		reward_value.text = str(value)

# 设置学年
func set_year(value: int):
	if year_value:
		year_value.text = "第" + str(value) + "学年"

# 设置学期
func set_term(current: int, total: int):
	if term_value:
		term_value.text = str(current) + "/" + str(total)

# 设置按钮点击处理
func _on_settings_button_pressed():
	emit_signal("settings_button_pressed") 

# 设置组合类型名称
func set_combo_name(combo_name: String):
	# 如果要在UI中显示组合类型，可以添加一个新的Label节点来显示
	# 这里我们先通过print输出
	print("Sidebar.set_combo_name: 当前牌型组合名称: %s" % combo_name)
	
	# 创建一个临时悬浮提示
	var temp_label = Label.new()
	temp_label.text = combo_name
	temp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	temp_label.add_theme_font_size_override("font_size", 22)
	
	# 设置位置在分数面板上方
	var score_panel = $VBoxContainer/ScorePanel
	if score_panel:
		temp_label.position = Vector2(score_panel.position.x + score_panel.size.x/2 - 100, 
									 score_panel.position.y - 40)
	else:
		temp_label.position = Vector2(100, 100)
	
	# 添加到场景并设置自动销毁
	add_child(temp_label)
	
	# 创建淡出动画
	var tween = create_tween()
	tween.tween_property(temp_label, "modulate", Color(1, 1, 1, 0), 2.0)
	
	# 动画完成后移除
	await tween.finished
	temp_label.queue_free() 
