class_name ArtifactItem
extends Control

# 导入ResourcePaths
const ResourcePaths = preload("res://cs/卡牌系统/视图/ResourcePaths.gd")

# 信号
signal artifact_clicked(artifact_item)
signal item_clicked(item_view)

# 法器数据
var artifact_data: ArtifactData = null
var item_data = null

# 节点引用
@onready var background: TextureRect = $Background
@onready var name_label: Label = $NameLabel
@onready var description_label: Label = $DescriptionLabel
@onready var rarity_indicator: ColorRect = $RarityIndicator

# 默认纹理
var default_texture: Texture2D

func _ready():
	# 加载默认纹理
	_load_default_texture()
	
	# 连接信号
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
		
	mouse_filter = Control.MOUSE_FILTER_STOP

# 鼠标输入处理
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("item_clicked", self)
		emit_signal("artifact_clicked", self)

# 加载默认纹理
func _load_default_texture():
	var icon_path = "res://assets/images/artifactItem/学徒笔记.png"
	if ResourceLoader.exists(icon_path):
		default_texture = load(icon_path)
	else:
		var alt_path = "res://assets/images/background/icon.png"
		if ResourceLoader.exists(alt_path):
			default_texture = load(alt_path)

# 设置法器数据并更新视图
func setup(data: ArtifactData):
	artifact_data = data
	item_data = data
	update_view()

# 更新视图显示
func update_view():
	if not artifact_data:
		return
	
	# 设置名称
	if name_label:
		name_label.text = artifact_data.item_name
	
	# 设置描述
	if description_label:
		description_label.text = artifact_data.get_description()
	
	# 设置稀有度指示器
	if rarity_indicator:
		rarity_indicator.color = get_rarity_color(artifact_data.rarity_type)
	
	# 设置背景纹理
	_update_texture()

# 更新纹理
func _update_texture():
	if not background:
		return
		
	var texture = null
	
	# 尝试加载特定法器图片
	if artifact_data and artifact_data.item_id:
		var texture_path = "res://assets/images/artifactItem/" + artifact_data.item_id.to_lower() + ".png"
		if ResourceLoader.exists(texture_path):
			texture = load(texture_path)
	
	# 使用默认纹理
	if not texture and default_texture:
		texture = default_texture
		
	if texture:
		background.texture = texture

# 获取法器数据
func get_artifact_data() -> ArtifactData:
	return artifact_data

# 设置选中状态
func set_selected(selected: bool):
	if selected:
		modulate = Color(1.2, 1.2, 1.2)  # 亮起
	else:
		modulate = Color(1, 1, 1)  # 正常

# 获取稀有度对应的颜色
func get_rarity_color(rarity: int) -> Color:
	match rarity:
		GlobalEnums.Rarity.COMMON:
			return Color(0.5, 0.5, 0.5)  # 灰色
		GlobalEnums.Rarity.RARE:
			return Color(0, 0.5, 1)      # 蓝色
		GlobalEnums.Rarity.EPIC:
			return Color(0.7, 0, 1)      # 紫色
		GlobalEnums.Rarity.LEGENDARY:
			return Color(1, 0.6, 0)      # 金色
		_:
			return Color(1, 1, 1)        # 白色 
