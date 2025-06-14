class_name DeckWidget
extends Panel

# 节点引用
@onready var count_label = $RuneLibraryContainer/CountContainer/CountLabel
@onready var rune_back_texture = $RuneLibraryContainer/RuneBackTexture

# 牌库卡牌数量
var deck_size = 52
var total_deck_size = 52

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("deck_widget", self)
	
	# 初始化UI
	update_ui()

# 更新UI
func update_ui():
	update_deck_count(deck_size)

# 更新牌库数量
func update_deck_count(count: int):
	deck_size = count
	if count_label:
		count_label.text = str(count) + " / " + str(total_deck_size)

# 设置总牌库数量
func set_total_deck_size(total: int):
	total_deck_size = total
	update_deck_count(deck_size)

# 获取牌库纹理
func get_rune_back_texture():
	if rune_back_texture:
		return rune_back_texture.texture
	return null 

# 处理牌库大小变化
func update_deck_info(remaining: int, total: int):
	deck_size = remaining
	total_deck_size = total
	update_deck_count(remaining) 
