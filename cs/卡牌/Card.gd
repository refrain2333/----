extends Area2D

# 卡牌基本属性
var card_id: int
var card_type: int  # 0=方块，1=梅花，2=红桃，3=黑桃
var card_value: int  # 1-13 (A-K)

# 卡牌位置相关
var dragging: bool = false
var original_position: Vector2
var selected: bool = false

# 主游戏场景引用
var main_game

# 初始化卡牌
func init_card(id: int, type: int, value: int):
	card_id = id
	card_type = type
	card_value = value
	
	# 加载对应的卡牌图片
	var texture_path = "res://assets/images/pokers/%d.jpg" % id
	var texture = load(texture_path)
	if texture:
		$CardSprite.texture = texture

# 当节点进入场景树时调用
func _ready():
	# 保存初始位置
	original_position = position
	
	# 获取主游戏场景引用 - 在节点加入场景树后执行
	call_deferred("_get_main_game")

# 安全地获取主游戏场景引用
func _get_main_game():
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		main_game = get_tree().current_scene

# 处理输入事件（拖放等）
func _process(_delta):
	if dragging:
		# 卡牌跟随鼠标移动
		position = get_global_mouse_position()

# 当鼠标点击、拖拽卡牌时
func _on_input_event(_viewport, event, _shape_idx):
	# 检测鼠标点击
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 开始拖拽
			dragging = true
			$HighlightBorder.visible = true
			# 将卡牌提到顶层显示
			z_index = 10
		else:
			# 结束拖拽
			dragging = false
			$HighlightBorder.visible = false
			z_index = 0
			
			# 检查是否放在出牌区域
			var in_play_area = false
			if main_game and main_game.has_method("check_card_in_play_area"):
				in_play_area = main_game.check_card_in_play_area(self)
			
			if in_play_area:
				# 卡牌被打出
				if main_game and main_game.has_method("handle_card_played"):
					main_game.handle_card_played(self)
			else:
				# 放回原位
				reset_position()

# 当鼠标进入卡牌区域时
func _on_mouse_entered():
	if not dragging:
		# 悬停效果：卡牌向上移动一点
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y - 20, 0.2)
		$HighlightBorder.visible = true

# 当鼠标离开卡牌区域时
func _on_mouse_exited():
	if not dragging:
		# 恢复原位置
		reset_position()
		$HighlightBorder.visible = false

# 重置卡牌位置
func reset_position():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.2)

# 获取卡牌名称
func get_card_name() -> String:
	var type_names = ["方块", "梅花", "红桃", "黑桃"]
	var value_names = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	return type_names[card_type] + value_names[card_value - 1] 
