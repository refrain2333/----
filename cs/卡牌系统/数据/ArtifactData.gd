class_name ArtifactData
extends Resource

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 法器基本属性（符合v1.6规范）
@export var id: String = ""               # 例如 "ARTIFACT_MAGIC_CRYSTAL"
@export var name: String = ""             # 例如 "魔力水晶"
@export var description: String = ""      # 用于UI显示的描述文本
@export var rarity: int = GlobalEnums.Rarity.COMMON # 稀有度
@export var cost: int = 0                 # 购买费用

# 效果属性（符合v1.6规范）
@export var effect_type: String = ""      # 例如 "LORE_POINTS_PERCENT_BONUS"
@export var effect_value = null           # 效果参数，如 0.05 (5%) 或 1 (增加1点)

# 获取法器描述文本
func get_description() -> String:
	return description

# 获取法器信息（包含稀有度和价格）
func get_info() -> String:
	var rarity_text = ""

	match rarity:
		GlobalEnums.Rarity.COMMON:
			rarity_text = "普通"
		GlobalEnums.Rarity.RARE:
			rarity_text = "稀有"
		GlobalEnums.Rarity.EPIC:
			rarity_text = "史诗"
		GlobalEnums.Rarity.LEGENDARY:
			rarity_text = "传说"
		_:
			rarity_text = "未知"

	return name + " (" + rarity_text + ", 价格:" + str(cost) + ")"

# 克隆法器数据
func clone() -> ArtifactData:
	var new_artifact = ArtifactData.new()
	new_artifact.id = id
	new_artifact.name = name
	new_artifact.description = description
	new_artifact.rarity = rarity
	new_artifact.cost = cost
	new_artifact.effect_type = effect_type
	new_artifact.effect_value = effect_value
	return new_artifact