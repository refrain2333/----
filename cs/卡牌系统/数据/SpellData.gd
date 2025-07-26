class_name SpellData
extends Resource

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 法术基本属性（符合v1.6规范）
@export var id: String = ""               # 例如 "SPELL_FLASH_OF_INSIGHT"
@export var name: String = ""             # 例如 "灵光一闪"
@export var description: String = ""      # 用于UI显示的描述文本
@export var rarity: int = GlobalEnums.Rarity.COMMON # 稀有度
@export var cost: int = 0                 # 购买费用

# 效果属性（符合v1.6规范）
@export var effect_type: String = ""      # 例如 "DOUBLE_SCORE"
@export var effect_value = null           # 效果参数

# 法术特有属性（符合v1.6规范）
@export var spell_type: int = GlobalEnums.SpellType.INSTANT_USE # 法术类型
@export var charges: int = 1              # 当前使用次数/充能

# 获取法术描述文本
func get_description() -> String:
	var type_text = ""
	match spell_type:
		GlobalEnums.SpellType.INSTANT_USE:
			type_text = "[瞬发]"
		GlobalEnums.SpellType.ACTIVE_SKILL:
			type_text = "[技能]"

	return type_text + " " + description

# 获取法术信息
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

	var type_text = ""
	match spell_type:
		GlobalEnums.SpellType.INSTANT_USE:
			type_text = "瞬发"
		GlobalEnums.SpellType.ACTIVE_SKILL:
			type_text = "技能"

	var info = name + " (" + rarity_text + ", " + type_text + ", 价格:" + str(cost) + ")"

	if spell_type == GlobalEnums.SpellType.ACTIVE_SKILL:
		info += ", 充能:" + str(charges)

	return info

# 使用法术，消耗一次充能
func use() -> bool:
	if charges <= 0:
		return false

	charges -= 1
	return true

# 增加充能
func add_charge(amount: int = 1) -> void:
	charges += amount

# 克隆法术数据
func clone() -> SpellData:
	var new_spell = SpellData.new()
	new_spell.id = id
	new_spell.name = name
	new_spell.description = description
	new_spell.rarity = rarity
	new_spell.cost = cost
	new_spell.effect_type = effect_type
	new_spell.effect_value = effect_value
	new_spell.spell_type = spell_type
	new_spell.charges = charges
	return new_spell
