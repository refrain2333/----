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
		print("Sidebar.set_score: 更新分数显示为 %d" % value)

# 设置倍率
func set_multiplier(value: int):
	if multiplier_value:
		multiplier_value.text = "x" + str(value)

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
