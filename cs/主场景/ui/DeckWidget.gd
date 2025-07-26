class_name DeckWidget
extends Control

# 预加载DeckViewDialog类
const DeckViewDialogScript = preload("res://cs/主场景/ui/DeckViewDialog_Simple.gd")

# 信号
signal deck_clicked

# 节点引用
@onready var count_label = $RuneLibraryContainer/CountContainer/CountLabel
@onready var rune_back_texture = $RuneLibraryContainer/RuneBackTexture
@onready var deck_button: Button = $DeckButton

# 牌库卡牌数量
var deck_size = 0
var total_deck_size = 52

# 卡牌数据
var all_cards_data = []  # 所有牌
var current_deck_data = []  # 当前牌库中的牌
var played_cards_data = []  # 已打出的牌

# 卡牌管理器引用
var card_manager = null

# 状态
var current_dialog: Window = null

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("deck_widget", self)
	
	# 初始化UI
	update_ui()
	
	# 连接信号
	deck_button.pressed.connect(_on_deck_button_pressed)
	
	# 测试代码 - 加载所有卡牌数据
	_load_test_cards()

# 设置牌库数据
func setup(all_cards, current_deck, played_cards):
	all_cards_data = all_cards
	current_deck_data = current_deck
	played_cards_data = played_cards

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

# 更新牌库信息
func update_deck_info(remaining: int, total: int):
	deck_size = remaining
	total_deck_size = total
	update_deck_count(remaining)

# 点击牌库按钮
func _on_deck_button_pressed():
	# 避免重复创建对话框
	if current_dialog != null and is_instance_valid(current_dialog):
		current_dialog.grab_focus()
		return
	
	# 创建并显示牌库对话框
	var dialog = DeckViewDialogScript.new()
	dialog.set_data(all_cards_data, current_deck_data, played_cards_data)
	
	# 连接关闭信号
	dialog.close_requested.connect(func(): current_dialog = null)
	
	# 添加到场景并显示
	add_child(dialog)
	dialog.position = Vector2(get_viewport_rect().size) / 2 - Vector2(dialog.size) / 2
	current_dialog = dialog

# 测试函数 - 加载所有卡牌数据
func _load_test_cards():
	# 清空数据
	all_cards_data = []
	current_deck_data = []
	played_cards_data = []
	
	# 加载所有卡牌
	var suits = ["S", "H", "D", "C"]  # 黑桃、红心、方片、梅花
	var values = range(1, 14)  # 1-13
	
	for suit in suits:
		for value in values:
			var card_path = "res://assets/data/cards/" + suit + str(value) + ".tres"
			var card_data = load(card_path)
			if card_data:
				all_cards_data.append(card_data)
				current_deck_data.append(card_data)
	
	# 随机选择一些卡牌作为已打出的卡牌
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var num_played = rng.randi_range(5, 10)
	for i in range(num_played):
		var random_index = rng.randi_range(0, current_deck_data.size() - 1)
		if random_index < current_deck_data.size():
			played_cards_data.append(current_deck_data[random_index])
			current_deck_data.remove_at(random_index)
	
	# 更新UI
	update_deck_info(current_deck_data.size(), all_cards_data.size())
