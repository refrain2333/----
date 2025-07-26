class_name ResourcePaths
extends RefCounted

# 静态路径常量
const IMAGE_BASE_PATH = "res://assets/images/"
const DATA_BASE_PATH = "res://assets/data/"

# 卡牌图像路径（扑克牌）
const CARD_IMAGES_PATH = IMAGE_BASE_PATH + "pokers/"

# 强化效果资源路径
const WAX_SEAL_PATH = IMAGE_BASE_PATH + "card_reinforcements/wax_seal_"
const FRAME_PATH = IMAGE_BASE_PATH + "card_reinforcements/frame_"
const SHADER_PATH = IMAGE_BASE_PATH + "card_reinforcements/"

# 物品类型图像路径
const ARTIFACT_IMAGES_PATH = IMAGE_BASE_PATH + "artifactItem/"
const JOKER_IMAGES_PATH = IMAGE_BASE_PATH + "jokers/"
const SPELL_IMAGES_PATH = IMAGE_BASE_PATH + "spells/"

# 数据资源路径
const CARD_DATA_PATH = DATA_BASE_PATH + "cards/"
const JOKER_DATA_PATH = DATA_BASE_PATH + "jokers/"
const ARTIFACT_DATA_PATH = DATA_BASE_PATH + "artifacts/"
const SPELL_DATA_PATH = DATA_BASE_PATH + "spells/"

# 获取卡牌图像路径
static func get_card_image_path(card_id: String) -> String:
	# 将卡牌ID转换为图像索引
	var suit = card_id[0]  # 第一个字符是花色
	var value = card_id.substr(1)  # 剩余部分是点数
	
	# 计算图像索引 (1-52)
	var suit_offset = {
		"S": 0,    # 黑桃 (Spades)
		"H": 13,   # 红桃 (Hearts)
		"D": 26,   # 方片 (Diamonds)
		"C": 39    # 梅花 (Clubs)
	}
	
	var index = suit_offset.get(suit, 0) + int(value)
	return CARD_IMAGES_PATH + str(index) + ".jpg"

# 获取蜡封图像路径
static func get_wax_seal_path(wax_type: String) -> String:
	return WAX_SEAL_PATH + wax_type.to_lower() + ".png"

# 获取牌框图像路径
static func get_frame_path(frame_type: String) -> String:
	return FRAME_PATH + frame_type.to_lower() + ".png"

# 获取材质着色器路径
static func get_material_shader_path(material_type: String) -> String:
	return SHADER_PATH + material_type.to_lower() + "_material.gdshader"

# 获取守护灵图像路径
static func get_joker_image_path(joker_id: String) -> String:
	var key = joker_id.to_lower().replace("joker_", "")
	return JOKER_IMAGES_PATH + key + ".png"

# 获取法器图像路径
static func get_artifact_image_path(artifact_id: String) -> String:
	var key = artifact_id.to_lower().replace("artifact_", "")
	return ARTIFACT_IMAGES_PATH + key + ".png"

# 获取法术图像路径
static func get_spell_image_path(spell_id: String) -> String:
	var key = spell_id.to_lower().replace("spell_", "")
	return SPELL_IMAGES_PATH + key + ".png" 