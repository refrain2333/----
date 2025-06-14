class_name EffectOrchestrator
extends Node

# 信号
signal effect_finished(effect_name)  # 特效播放完成
signal effect_queue_empty           # 特效队列清空

# 特效类型
enum EffectType {
	PARTICLE,  # 粒子效果
	SHADER,    # 着色器效果
	SOUND,     # 音效
	ANIMATION  # 动画
}

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

func _init(game_scene):
	main_game = game_scene

# 初始化特效系统
func initialize():
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
	
	print("特效系统初始化完成")

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

# 添加特效到队列
func queue_effect(effect_name: String, effect_type: EffectType, position: Vector2, params: Dictionary = {}):
	# 添加到队列
	effect_queue.append({
		"name": effect_name,
		"type": effect_type,
		"position": position,
		"params": params
	})
	
	# 如果当前没有播放特效，开始播放
	if not is_playing and active_effects < max_concurrent_effects:
		_play_next_effect()

# 私有方法：预加载特效
func _preload_effects():
	# 暂时不载入具体的预制体，等待资源实际创建后再实现
	pass

# 私有方法：创建简单粒子
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