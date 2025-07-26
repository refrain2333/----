class_name SpellView
extends BaseItemView

# 导入必要的资源
const ResourcePaths = preload("res://cs/卡牌系统/视图/ResourcePaths.gd")
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 重写信号以保持命名一致性
signal spell_clicked(spell_view)
signal spell_used(spell_view)

# 法术数据 - 重写类型
var spell_data: SpellData = null:
	set(value):
		spell_data = value
		item_data = value # 同时设置基类的item_data

# 节点引用 - 仅保留基类中没有的节点
@onready var charge_label: Label = $ChargeLabel
@onready var use_button: Button = $UseButton

# 默认纹理
var default_texture: Texture2D

func _ready():
	super._ready()  # 调用基类的_ready方法
	
	# 获取基类节点引用
	background = $Background
	name_label = $NameLabel
	description_label = $DescriptionLabel
	rarity_indicator = $RarityIndicator
	
	# 加载默认纹理
	default_texture = load("res://icon.svg")
	
	# 连接使用按钮信号
	if use_button:
		use_button.pressed.connect(_on_use_button_pressed)

# 设置法术数据并更新视图 - 重写以保持接口一致
func setup(data: Resource):
	if data is SpellData:
		spell_data = data
	super.setup(data)  # 调用基类的setup
	
	# 修改信号连接
	if item_clicked.is_connected(_on_item_clicked):
		item_clicked.disconnect(_on_item_clicked)
	item_clicked.connect(_on_item_clicked)

# 更新视图显示 - 重写基类方法
func update_view():
	if not spell_data:
		return
	
	# 设置名称
	name_label.text = spell_data.item_name
	
	# 设置描述
	if description_label:
		description_label.text = spell_data.get_description()
	
	# 设置充能数量
	if charge_label and spell_data.spell_cast_type == GlobalEnums.SpellType.ACTIVE:
		charge_label.text = "充能: " + str(spell_data.current_charges)
		charge_label.visible = true
		
		# 如果有使用按钮，根据充能数量设置是否可用
		if use_button:
			use_button.visible = true
			use_button.disabled = spell_data.current_charges <= 0
	else:
		if charge_label:
			charge_label.visible = false
		if use_button:
			use_button.visible = false
	
	# 设置稀有度指示器
	if rarity_indicator:
		rarity_indicator.color = get_rarity_color(spell_data.rarity_type)
	
	# 尝试设置纹理，如果无法找到特定法术的图片则使用默认纹理
	var texture = default_texture
	
	if background and texture:
		background.texture = texture

# 获取法术数据
func get_spell_data() -> SpellData:
	return spell_data

# 使用按钮被点击
func _on_use_button_pressed():
	# 尝试使用法术
	if spell_data and spell_data.current_charges > 0:
		emit_signal("spell_used", self)

# 基类信号处理
func _on_item_clicked(view_instance):
	if view_instance == self:
		emit_signal("spell_clicked", self)

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常 