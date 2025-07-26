class_name EffectOrchestrator
extends Node

# 信号
signal effect_finished(effect_name)  # 特效播放完成
signal effect_queue_empty           # 特效队列清空
signal effect_triggered(effect_type, effect_value, source) # 效果触发信号
signal effect_orchestrated(effect_result)

# 预加载类型
const EventManagerType = preload("res://cs/Global/EventManager.gd")
const GlobalEnumsType = preload("res://cs/Global/GlobalEnums.gd")

# 特效类型
enum EffectType {
	PARTICLE,  # 粒子效果
	SHADER,    # 着色器效果
	SOUND,     # 音效
	ANIMATION  # 动画
}

# 接口常量 - Diamond设计模式关键 - 定义效果触发接口
const EFFECT_HANDLER_INTERFACE = {
	"handle_effect": true,  # 方法名及是否必须实现
	"can_handle": false     # 可选实现
}

# 效果处理器注册表 (type_id -> handler)
var effect_handlers = {}

# 特效队列
var effect_queue = []
var is_playing = false
var main_game  # 引用主场景

# 特效层引用
var effect_layer: CanvasLayer

# 预加载的特效资源
var particle_effects = {}
var shader_effects = {}
var sound_effects = {}
var animation_effects = {}

# 配置
var max_concurrent_effects: int = 3  # 最大并发特效数量
var active_effects: int = 0          # 当前活跃特效数量

# 导入全局枚举
const GlobalEnums = preload("res://cs/Global/GlobalEnums.gd")

# 引用其他管理器
var card_manager: Node  # CardManager类型
var card_effect_controller: Node  # CardEffectController类型
var game_manager: Node  # GameManager类型
var event_manager: Node  # EventManager类型

func _init(scene = null):
	main_game = scene
	print("EffectOrchestrator: 初始化")

# 完整初始化
func initialize(card_mgr = null, game_mgr = null, event_mgr = null):
	# 获取特效层
	effect_layer = main_game.get_effect_layer()
	
	# 如果特效层不存在，则创建一个
	if not effect_layer:
		effect_layer = CanvasLayer.new()
		effect_layer.name = "EffectLayer"
		effect_layer.layer = 5  # 设置为较高的层级，确保特效显示在最上层
		main_game.add_child(effect_layer)
	
	# 预加载常用特效
	_preload_effects()
	
	# 存储管理器引用
	card_manager = card_mgr
	game_manager = game_mgr
	event_manager = event_mgr
	
	print("特效系统初始化完成")

# 注册效果处理器 - Diamond模式核心 - 高层组件不依赖于底层实现
func register_effect_handler(effect_type_id: String, handler):
	# 验证处理器接口
	if not _validate_handler_interface(handler):
		push_error("EffectOrchestrator: 处理器必须实现handle_effect方法")
		return false
		
	effect_handlers[effect_type_id] = handler
	print("EffectOrchestrator: 注册了效果处理器 - " + effect_type_id)
	return true
	
# 验证处理器是否实现了必要接口
func _validate_handler_interface(handler) -> bool:
	if not handler.has_method("handle_effect"):
		return false
	return true

# 主要效果触发函数 - 通过接口调用，而非直接实现
func trigger_effect_logic(effect_type_id: String, effect_value, source = null, params: Dictionary = {}):
	print("EffectOrchestrator: 触发效果 - " + effect_type_id)
	
	# 构建效果数据
	var effect_data = {
		"type": effect_type_id,
		"value": effect_value,
		"source": source,
		"params": params
	}
	
	# Diamond模式关键：通过抽象接口调用具体处理器
	var result = null
	if effect_handlers.has(effect_type_id):
		# 首先检查处理器是否可以处理该效果
		var handler = effect_handlers[effect_type_id]
		
		if handler.has_method("can_handle") and not handler.can_handle(effect_data):
			print("EffectOrchestrator: 处理器无法处理此效果")
			return null
			
		# 通过处理器处理效果
		result = handler.handle_effect(effect_value, source, params)
	else:
		# 默认处理器
		result = _default_effect_handler(effect_data)
		
	# 发送效果触发信号
	emit_signal("effect_triggered", effect_type_id, effect_value, source)
	
	# 如果效果请求链式触发其他效果
	if result and result is Dictionary and result.has("chain_effect"):
		var chain = result.chain_effect
		trigger_effect_logic(chain.type, chain.value, chain.source, chain.params if chain.has("params") else {})
	
	return result

# 默认效果处理器 - 处理未注册的效果类型
func _default_effect_handler(effect_data: Dictionary):
	var effect_type = effect_data.type
	var effect_value = effect_data.value
	
	print("EffectOrchestrator: 使用默认处理器处理 - " + effect_type)
	
	# 基于类型进行分发
	match effect_type:
		"DRAW_CARDS":
			if card_manager and card_manager.has_method("draw"):
				card_manager.draw(effect_value)
				return {"success": true, "cards_drawn": effect_value}
				
		"ADD_LORE":
			if game_manager and game_manager.has_method("add_lore"):
				game_manager.add_lore(effect_value)
				return {"success": true, "lore_added": effect_value}
				
		"INCREASE_CARD_TYPE_LEVEL":
			if game_manager and game_manager.has_method("modify_card_type_level"):
				game_manager.modify_card_type_level(effect_value.type_name, effect_value.amount)
				return {"success": true}
				
		"ADD_TURN_BUFF":
			if event_manager and event_manager.has_method("add_turn_buff"):
				event_manager.add_turn_buff(effect_value)
				return {"success": true}
				
		# 其他默认处理...
	
	# 未能处理
	print("EffectOrchestrator: 无法处理未知效果类型 - " + effect_type)
	return {"success": false, "error": "未知效果类型"}

# 触发法器效果
func trigger_artifact_effect(artifact_data, params: Dictionary = {}):
	if not artifact_data:
		return null
		
	return trigger_effect_logic(
		artifact_data.effect_type_id,
		artifact_data.effect_value_param,
		artifact_data,
		params
	)

# 触发法术效果
func trigger_spell_effect(spell_data, params: Dictionary = {}):
	if not spell_data:
		return null
		
	return trigger_effect_logic(
		spell_data.effect_type_id,
		spell_data.effect_value_param,
		spell_data,
		params
	)

# 触发守护灵效果
func trigger_joker_effect(joker_data, trigger_context: Dictionary = {}):
	if not joker_data:
		return null
		
	# 检查触发条件
	if joker_data.has_method("should_trigger") and not joker_data.should_trigger(trigger_context):
		return null
		
	return trigger_effect_logic(
		joker_data.effect_type_id,
		joker_data.effect_value_param,
		joker_data,
		trigger_context
	)

# 视觉效果方法

# 创建卡牌放置特效
func create_card_drop_effect(position: Vector2):
	# 创建简单粒子特效
	var particles = _create_simple_particles()
	effect_layer.add_child(particles)
	
	# 设置位置和发射器
	particles.global_position = position
	particles.emitting = true
	
	# 自动销毁
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): particles.queue_free())
	
	return particles

# 创建得分特效
func create_score_effect(position: Vector2, score: int):
	# 创建得分标签
	var label = Label.new()
	label.text = "+" + str(score)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.position = position
	label.z_index = 100
	effect_layer.add_child(label)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", position.y - 100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): label.queue_free())
	
	return label

# 创建抽牌特效
func create_draw_effect(position: Vector2, target_position: Vector2):
	# 创建路径指示器
	var line = Line2D.new()
	line.width = 3
	line.default_color = Color(0.5, 0.8, 1.0, 0.8)
	line.add_point(position)
	line.add_point(target_position)
	effect_layer.add_child(line)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): line.queue_free())
	
	return line

# 创建对话气泡
func create_speech_bubble(position: Vector2, text: String, duration: float = 3.0):
	# 创建气泡容器
	var bubble = Control.new()
	bubble.position = position
	bubble.z_index = 100
	effect_layer.add_child(bubble)
	
	# 创建背景面板
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 80)
	bubble.add_child(panel)
	
	# 创建文本标签
	var label = Label.new()
	label.text = text
	label.position = Vector2(10, 10)
	label.custom_minimum_size = Vector2(180, 60)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): bubble.queue_free())
	
	return bubble

# 创建闪光效果
func create_flash_effect(node: Node2D, color: Color = Color(1,1,1), duration: float = 0.3):
	if not is_instance_valid(node):
		return null
	
	var original_modulate = node.modulate
	
	# 创建闪光动画
	var tween = create_tween()
	tween.tween_property(node, "modulate", color, duration/2)
	tween.tween_property(node, "modulate", original_modulate, duration/2)
	
	return tween

# 创建简单粒子效果
func _create_simple_particles() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 1.0
	particles.explosiveness = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 5.0
	particles.direction = Vector2(0, -1)
	particles.spread = 90
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_amount_min = 2
	particles.scale_amount_max = 5
	particles.color = Color(0.8, 0.8, 1.0)
	
	return particles

# 私有方法：预加载特效
func _preload_effects():
	# 暂时不载入具体的预制体，等待资源实际创建后再实现
	pass

# 私有方法：播放下一个特效
func _play_next_effect():
	# 如果队列为空或达到最大并发数，返回
	if effect_queue.size() == 0 or active_effects >= max_concurrent_effects:
		if effect_queue.size() == 0:
			emit_signal("effect_queue_empty")
		return
	
	# 获取下一个特效
	is_playing = true
	active_effects += 1
	var effect_data = effect_queue.pop_front()
	
	# 根据特效类型播放
	match effect_data.type:
		EffectType.PARTICLE:
			_play_particle_effect(effect_data)
		EffectType.SHADER:
			_play_shader_effect(effect_data)
		EffectType.SOUND:
			_play_sound_effect(effect_data)
		EffectType.ANIMATION:
			_play_animation_effect(effect_data)

# 私有方法：播放粒子特效
func _play_particle_effect(effect_data: Dictionary):
	var effect_name = effect_data.name
	var position = effect_data.position
	var params = effect_data.params
	
	# 创建粒子
	var particles = _create_simple_particles()
	effect_layer.add_child(particles)
	
	# 设置位置
	particles.global_position = position
	
	# 应用参数
	if params.has("amount"):
		particles.amount = params.amount
	if params.has("lifetime"):
		particles.lifetime = params.lifetime
	if params.has("explosiveness"):
		particles.explosiveness = params.explosiveness
	if params.has("color"):
		particles.color = params.color
	
	# 开始发射
	particles.emitting = true
	
	# 设置自动销毁
	var duration = params.get("duration", 2.0)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		particles.queue_free()
		active_effects -= 1
		emit_signal("effect_finished", effect_name)
		_play_next_effect()
	)

# 私有方法：播放着色器特效
func _play_shader_effect(effect_data: Dictionary):
	var effect_name = effect_data.name
	var position = effect_data.position
	var params = effect_data.params
	
	# 创建着色器容器
	var shader_container = ColorRect.new()
	shader_container.size = Vector2(200, 200)  # 默认大小
	shader_container.global_position = position - shader_container.size / 2
	effect_layer.add_child(shader_container)
	
	# 创建着色器材质
	var material = ShaderMaterial.new()
	# 这里需要实际的shader代码，暂时使用默认
	shader_container.material = material
	
	# 应用参数
	if params.has("size"):
		shader_container.size = params.size
		shader_container.global_position = position - shader_container.size / 2
	
	# 设置自动销毁
	var duration = params.get("duration", 1.0)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		shader_container.queue_free()
		active_effects -= 1
		emit_signal("effect_finished", effect_name)
		_play_next_effect()
	)

# 私有方法：播放音效
func _play_sound_effect(effect_data: Dictionary):
	var effect_name = effect_data.name
	var params = effect_data.params
	
	# 创建音频播放器
	var audio_player = AudioStreamPlayer.new()
	effect_layer.add_child(audio_player)
	
	# 应用参数
	if params.has("stream"):
		audio_player.stream = params.stream
	if params.has("volume_db"):
		audio_player.volume_db = params.volume_db
	if params.has("pitch_scale"):
		audio_player.pitch_scale = params.pitch_scale
	
	# 播放
	audio_player.play()
	
	# 设置自动销毁
	audio_player.finished.connect(func():
		audio_player.queue_free()
		active_effects -= 1
		emit_signal("effect_finished", effect_name)
		_play_next_effect()
	)

# 私有方法：播放动画特效
func _play_animation_effect(effect_data: Dictionary):
	var effect_name = effect_data.name
	var position = effect_data.position
	var params = effect_data.params
	
	# 创建动画容器
	var animation_container = Node2D.new()
	animation_container.global_position = position
	effect_layer.add_child(animation_container)
	
	# 创建精灵
	var sprite = Sprite2D.new()
	animation_container.add_child(sprite)
	
	# 应用参数
	if params.has("texture"):
		sprite.texture = params.texture
	if params.has("frames"):
		sprite.hframes = params.frames
	if params.has("scale"):
		sprite.scale = params.scale
	
	# 创建动画播放器
	var anim_player = AnimationPlayer.new()
	animation_container.add_child(anim_player)
	
	# 创建简单动画
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, ".:frame")
	animation.length = params.get("duration", 1.0)
	
	if params.has("frames"):
		var frames = params.frames
		for i in range(frames):
			animation.track_insert_key(track_index, i * animation.length / frames, i)
	
	# 添加动画
	anim_player.add_animation("play", animation)
	
	# 播放
	anim_player.play("play")
	
	# 设置自动销毁
	anim_player.animation_finished.connect(func(_anim_name):
		animation_container.queue_free()
		active_effects -= 1
		emit_signal("effect_finished", effect_name)
		_play_next_effect()
	)

# 创建得分特效
func show_score(score: int):
	print("显示分数: " + str(score))
	
	# 获取视口中心位置
	var viewport_rect = get_viewport().get_visible_rect()
	var center_position = Vector2(viewport_rect.size.x / 2, viewport_rect.size.y / 2)
	
	# 创建得分标签
	var label = Label.new()
	label.text = "+" + str(score)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.position = center_position - Vector2(50, 50)  # 调整位置使其居中
	label.z_index = 100
	effect_layer.add_child(label)
	
	# 创建动画
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		label.queue_free()
		# 发出特效队列为空的信号
		emit_signal("effect_queue_empty")
	)
	
	return label

# 初始化
func setup(cm, cec, gm = null, em = null):
	card_manager = cm
	card_effect_controller = cec
	game_manager = gm
	event_manager = em
	
	print("EffectOrchestrator: 初始化完成")
	
	# 连接信号
	if card_manager:
		if not card_manager.card_played.is_connected(Callable(self, "_on_card_played")):
			card_manager.card_played.connect(Callable(self, "_on_card_played"))
		if not card_manager.cards_played.is_connected(Callable(self, "_on_cards_played")):
			card_manager.cards_played.connect(Callable(self, "_on_cards_played"))
	
	if card_effect_controller and card_effect_controller.has_signal("effect_triggered"):
		if not card_effect_controller.effect_triggered.is_connected(Callable(self, "_on_effect_triggered")):
			card_effect_controller.effect_triggered.connect(Callable(self, "_on_effect_triggered"))

# 处理单张卡牌打出事件
func _on_card_played(card_data):
	print("EffectOrchestrator: 卡牌被打出 - " + card_data.card_name)
	
	# 基础效果处理
	var effect_result = {
		"card": card_data,
		"score": card_data.base_value,
		"effects": []
	}
	
	# 应用卡牌强化效果
	if card_effect_controller:
		# 处理卡牌效果
		var card_effects = card_effect_controller.process_card_effects(card_data)
		if card_effects:
			effect_result.effects.append_array(card_effects.effects)
			effect_result.score += card_effects.value_change
	
	# 应用游戏状态效果
	if game_manager:
		# 添加分数
		game_manager.add_assessment_score(effect_result.score)
	
	# 发送效果协调完成信号
	emit_signal("effect_orchestrated", effect_result)

# 处理多张卡牌被打出事件
func _on_cards_played(cards, base_score):
	print("EffectOrchestrator: 处理多张卡牌被打出 - %d张, 基础分数: %d" % [cards.size(), base_score])
	
	# 基础效果处理
	var effect_result = {
		"cards": cards,
		"base_score": base_score,
		"bonus_score": 0,
		"final_score": base_score,
		"effects": []
	}
	
	# 应用每张卡牌的个体效果
	if card_effect_controller:
		for card in cards:
			# 处理卡牌强化效果
			var card_effects = card_effect_controller.process_card_effects(card)
			if card_effects:
				effect_result.effects.append_array(card_effects.effects)
				effect_result.bonus_score += card_effects.value_change
	
	# 计算最终分数
	effect_result.final_score = base_score + effect_result.bonus_score
	
	# 应用游戏状态效果
	if game_manager:
		# 添加分数
		game_manager.add_assessment_score(effect_result.final_score)
	
	# 发送效果协调完成信号
	emit_signal("effect_orchestrated", effect_result)

# 处理效果触发事件
func _on_effect_triggered(card_data, effect_type, effect_params):
	print("EffectOrchestrator: 效果触发 - " + effect_type)
	
	# 应用效果到游戏状态
	match effect_type:
		"damage":
			if game_manager and game_manager.has_method("apply_damage_to_opponent"):
				game_manager.apply_damage_to_opponent(effect_params.value)
		
		"draw":
			if card_manager and card_manager.has_method("draw"):
				card_manager.draw(effect_params.count)
		
		"transform":
			if game_manager and game_manager.has_method("transform_random_card"):
				game_manager.transform_random_card()
		
		"score":
			if game_manager and game_manager.has_method("add_score"):
				game_manager.add_score(effect_params.value)
		
		"heal":
			if game_manager and game_manager.has_method("heal_player"):
				game_manager.heal_player(effect_params.value)
		
		"burn":
			if game_manager and game_manager.has_method("apply_burn_effect_to_opponent"):
				game_manager.apply_burn_effect_to_opponent(effect_params.turns)
		
		"earth":
			if game_manager and game_manager.has_method("apply_earth_effect"):
				game_manager.apply_earth_effect(effect_params.value)
		
		"enhance":
			if game_manager and game_manager.has_method("enhance_next_card"):
				game_manager.enhance_next_card()
		
		"element_boost":
			if game_manager and game_manager.has_method("set_element_effect_multiplier"):
				game_manager.set_element_effect_multiplier(effect_params.multiplier)
		
		"double":
			if game_manager and game_manager.has_method("activate_double_effect"):
				game_manager.activate_double_effect()
		
		"defense":
			if game_manager and game_manager.has_method("add_defense"):
				game_manager.add_defense(effect_params.value)
		
		"reflect":
			if game_manager and game_manager.has_method("set_damage_reflection"):
				game_manager.set_damage_reflection(effect_params.percent)
		
		# 更多效果处理...
		_:
			print("EffectOrchestrator: 未知效果类型 - " + effect_type)
	
	# 发送信号
	emit_signal("effect_orchestrated", {"effect_type": effect_type, "params": effect_params}) 