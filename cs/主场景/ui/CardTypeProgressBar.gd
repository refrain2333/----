class_name CardTypeProgressBar
extends Control

# 牌型名称
@export var card_type: String = "straight"  # 顺子
@export var card_type_display_name: String = "顺子"

# 颜色
@export var fill_color: Color = Color(0.2, 0.7, 0.3)  # 绿色
@export var background_color: Color = Color(0.2, 0.2, 0.2)  # 深灰色

# 引用
@onready var progress_bar = $ProgressBar
@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
@onready var xp_label = $XPLabel

# 游戏管理器引用
var game_manager = null

func _ready():
	# 设置标签
	name_label.text = card_type_display_name
	
	# 获取GameManager引用
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		# 连接信号
		if game_manager.has_signal("card_type_xp_changed"):
			game_manager.card_type_xp_changed.connect(_on_card_type_xp_changed)
			
		# 初始化
		_update_display()
	else:
		push_error("CardTypeProgressBar: 无法获取GameManager引用")
		
	# 设置进度条颜色
	var style_box = progress_bar.get("theme_override_styles/fill")
	if style_box:
		style_box.bg_color = fill_color

# 更新显示
func _update_display():
	if not game_manager:
		return
		
	var type_level = game_manager.get_card_type_level(card_type)
	var current_xp = game_manager.get_card_type_xp(card_type)
	var next_level_xp = game_manager.get_xp_for_next_level(card_type)
	
	# 更新等级标签
	level_label.text = "Lv." + str(type_level)
	
	# 更新经验标签
	if type_level < game_manager.max_card_type_level:
		xp_label.text = str(current_xp) + " / " + str(next_level_xp)
		
		# 更新进度条
		progress_bar.max_value = next_level_xp
		progress_bar.value = current_xp
	else:
		# 已达最高等级
		xp_label.text = "最高等级"
		progress_bar.max_value = 1
		progress_bar.value = 1

# 当牌型经验变化时
func _on_card_type_xp_changed(changed_type, _new_xp, _new_level):
	if changed_type == card_type:
		_update_display() 