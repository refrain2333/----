class_name HandDockConfig
extends Resource

## HandDock配置资源
## 将所有配置参数集中管理

# 卡牌尺寸配置
@export_group("卡牌尺寸")
@export var card_width: float = 120.0
@export var card_height: float = 180.0
@export var card_spacing: float = 135.0
@export var container_center_x: float = 492.5

# 动画配置
@export_group("动画设置")
@export var selection_offset_y: float = -35.0
@export var animation_duration: float = 0.2
@export var hover_offset_y: float = -20.0
@export var scale_selected: float = 1.05
@export var scale_normal: float = 1.0

# 位置配置 - 1到8张卡牌的固定位置
@export_group("位置布局")
@export var fixed_positions: Dictionary = {
	1: [492.5],
	2: [425.0, 560.0],
	3: [357.5, 492.5, 627.5],
	4: [290.0, 425.0, 560.0, 695.0],
	5: [222.5, 357.5, 492.5, 627.5, 762.5],
	6: [155.0, 290.0, 425.0, 560.0, 695.0, 830.0],
	7: [87.5, 222.5, 357.5, 492.5, 627.5, 762.5, 897.5],
	8: [20.0, 155.0, 290.0, 425.0, 560.0, 695.0, 830.0, 965.0]
}

# 调试配置
@export_group("调试设置")
@export var debug_mode: bool = false
@export var enable_position_validation: bool = false
@export var enable_position_monitoring: bool = false
@export var log_level: int = 1  # LogLevel.INFO

# 性能配置
@export_group("性能优化")
@export var batch_operation_delay: float = 0.1
@export var rearrange_delay: float = 0.05
@export var max_hand_size: int = 8

# 交互配置
@export_group("交互设置")
@export var enable_hover_effects: bool = true
@export var enable_selection_animation: bool = true
@export var mouse_filter_mode: Control.MouseFilter = Control.MOUSE_FILTER_PASS

## 获取指定卡牌数量的位置数组
func get_positions_for_count(count: int) -> Array:
	if fixed_positions.has(count):
		return fixed_positions[count].duplicate()
	else:
		LogManager.error("HandDockConfig", "不支持%d张卡牌的布局" % count)
		return []

## 验证配置有效性
func validate_config() -> bool:
	var is_valid = true
	
	# 检查基本参数
	if card_width <= 0 or card_height <= 0:
		LogManager.error("HandDockConfig", "卡牌尺寸必须大于0")
		is_valid = false
	
	if card_spacing <= 0:
		LogManager.error("HandDockConfig", "卡牌间距必须大于0")
		is_valid = false
	
	# 检查位置配置
	for i in range(1, max_hand_size + 1):
		if not fixed_positions.has(i):
			LogManager.error("HandDockConfig", "缺少%d张卡牌的位置配置" % i)
			is_valid = false
		elif fixed_positions[i].size() != i:
			LogManager.error("HandDockConfig", "%d张卡牌的位置数量不匹配" % i)
			is_valid = false
	
	if is_valid:
		LogManager.info("HandDockConfig", "配置验证通过")
	
	return is_valid

## 获取默认配置
static func get_default_config():
	var config = load("res://cs/卡牌系统/配置/HandDockConfig.gd").new()
	# 所有默认值已在@export中定义
	return config
