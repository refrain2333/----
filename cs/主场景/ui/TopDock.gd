class_name TopDock
extends Control

# 节点引用
@onready var artifact_container = $ArtifactPanel/ArtifactContainer
@onready var discovery_container = $MagicDiscoveryPanel/DiscoveryContainer
@onready var discovery_area = $DiscoveryArea

func _ready():
	# 注册到UIRegistry
	if Engine.has_singleton("UIRegistry"):
		UIRegistry.register_ui_component("top_dock", self)

# 更新UI
func update_ui():
	# 更新计数器
	update_artifact_count(0, 6)
	update_discovery_count(0, 3)

# 获取法器容器
func get_artifact_container():
	return artifact_container

# 获取发现容器
func get_discovery_container():
	return discovery_container

# 显示发现区域
func show_discovery():
	if discovery_area:
		discovery_area.visible = true

# 隐藏发现区域
func hide_discovery():
	if discovery_area:
		discovery_area.visible = false

# 更新法器计数
func update_artifact_count(current: int, max_count: int):
	var count_label = $ArtifactPanel/ArtifactCountLabel
	if count_label:
		count_label.text = str(current) + " / " + str(max_count)

# 更新发现计数
func update_discovery_count(current: int, max_count: int):
	var count_label = $MagicDiscoveryPanel/DiscoveryCountLabel
	if count_label:
		count_label.text = str(current) + " / " + str(max_count) 
