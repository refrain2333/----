# HandDock.gd 代码优化指导文件

## 🎯 优化目标与要求

基于具体需求，本次优化重点解决以下问题：

### 1. 调试代码处理
- **位置验证函数**: 仅在DEBUG模式下启用
- **调试日志**: 移除分散的日志函数，建立统一日志系统
- **监控系统**: 移除生产环境不需要的位置监控

### 2. 配置管理
- **位置管理常量**: 提取到独立配置文件
- **布局参数**: 集中管理，便于调整

### 3. 选择逻辑优化
- **统一选择管理**: 消除重复代码
- **清晰的状态管理**: 避免逻辑混乱

### 4. 核心逻辑重构 - 卡牌替换机制
- **智能补牌**: 优先补充最左边位置
- **位置保持**: 仅替换，不重新排序
- **空隙处理**: 动态调整布局（4张→3张）

## 📋 具体优化方案

### 阶段1: 建立统一日志系统

#### 创建日志管理器
```gdscript
# 新文件: cs/Global/LogManager.gd
class_name LogManager
extends RefCounted

enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3
}

static var instance: LogManager
static var debug_mode: bool = false
static var current_level: LogLevel = LogLevel.INFO

static func get_instance() -> LogManager:
    if not instance:
        instance = LogManager.new()
    return instance

static func log(component: String, message: String, level: LogLevel = LogLevel.INFO):
    if level < current_level:
        return
        
    var level_text = ["DEBUG", "INFO", "WARN", "ERROR"][level]
    var timestamp = Time.get_datetime_string_from_system()
    print("[%s] %s[%s]: %s" % [timestamp, component, level_text, message])

static func debug(component: String, message: String):
    if debug_mode:
        log(component, message, LogLevel.DEBUG)

static func info(component: String, message: String):
    log(component, message, LogLevel.INFO)

static func warning(component: String, message: String):
    log(component, message, LogLevel.WARNING)

static func error(component: String, message: String):
    log(component, message, LogLevel.ERROR)
```

#### HandDock中的日志使用
```gdscript
# 替换所有日志函数
# 移除: _log(), _log_verbose(), _log_position(), _log_error()

# 新的使用方式:
LogManager.info("HandDock", "初始化完成")
LogManager.debug("HandDock", "设置card_container的mouse_filter=PASS")
LogManager.error("HandDock", "找不到PlayButton")
```

### 阶段2: 提取配置到独立文件

#### 创建配置资源
```gdscript
# 新文件: cs/卡牌系统/配置/HandDockConfig.gd
class_name HandDockConfig
extends Resource

# 卡牌尺寸配置
@export var card_width: float = 120.0
@export var card_height: float = 180.0
@export var card_spacing: float = 135.0
@export var container_center_x: float = 492.5

# 动画配置
@export var selection_offset_y: float = -35.0
@export var animation_duration: float = 0.2
@export var hover_offset_y: float = -20.0

# 位置配置
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
@export var debug_mode: bool = false
@export var enable_position_validation: bool = false
@export var enable_position_monitoring: bool = false
```

#### 在HandDock中使用配置
```gdscript
# HandDock.gd 中添加
@export var config: HandDockConfig

func _ready():
    if not config:
        config = preload("res://cs/卡牌系统/配置/hand_dock_config.tres")
    
    LogManager.debug_mode = config.debug_mode
    # 其他初始化...
```

### 阶段3: 统一选择管理逻辑

#### 新的选择管理器
```gdscript
# HandDock.gd 中添加选择管理类
class SelectionManager:
    var selected_cards: Array = []
    var hand_dock: HandDock
    
    func _init(dock: HandDock):
        hand_dock = dock
    
    func update_selection(card_instance, is_selected: bool) -> bool:
        var index = selected_cards.find(card_instance)
        var changed = false
        
        if is_selected and index == -1:
            selected_cards.append(card_instance)
            changed = true
            LogManager.debug("HandDock", "卡牌已添加到选中列表: %s" % card_instance.name)
        elif not is_selected and index != -1:
            selected_cards.remove_at(index)
            changed = true
            LogManager.debug("HandDock", "卡牌已从选中列表移除: %s" % card_instance.name)
        
        if changed:
            hand_dock.emit_signal("card_selection_changed", selected_cards)
            hand_dock.update_ui()
        
        return changed
    
    func clear_selection():
        for card in selected_cards:
            if card.has_method("set_selected"):
                card.set_selected(false)
        selected_cards.clear()
        hand_dock.emit_signal("card_selection_changed", selected_cards)
        LogManager.info("HandDock", "已清空所有选择状态")
    
    func get_selected_cards() -> Array:
        return selected_cards.duplicate()
    
    func has_selection() -> bool:
        return selected_cards.size() > 0
```

### 阶段4: 核心逻辑重构 - 智能卡牌替换系统

#### 新的卡牌管理逻辑
```gdscript
# HandDock.gd 中的核心重构

# 卡牌位置映射 - 记录每个位置的卡牌
var position_to_card: Dictionary = {}  # position_index -> card_instance
var card_to_position: Dictionary = {}  # card_instance -> position_index

# 移除选中卡牌并智能补牌
func remove_selected_cards_and_refill():
    var selected = selection_manager.get_selected_cards()
    if selected.is_empty():
        return
    
    LogManager.info("HandDock", "开始移除%d张选中卡牌并补牌" % selected.size())
    
    # 1. 记录被移除卡牌的位置
    var removed_positions: Array = []
    for card in selected:
        if card_to_position.has(card):
            removed_positions.append(card_to_position[card])
            _remove_card_from_position(card)
    
    # 2. 清空选择状态
    selection_manager.clear_selection()
    
    # 3. 请求新卡牌补充
    var cards_needed = removed_positions.size()
    var new_cards = _request_new_cards(cards_needed)
    
    # 4. 智能填充位置
    _smart_fill_positions(removed_positions, new_cards)
    
    LogManager.info("HandDock", "卡牌移除和补充完成")

# 智能填充位置逻辑
func _smart_fill_positions(removed_positions: Array, new_cards: Array):
    removed_positions.sort()  # 从左到右排序
    
    # 如果新卡牌数量不足，需要调整布局
    if new_cards.size() < removed_positions.size():
        _handle_insufficient_cards(removed_positions, new_cards)
    else:
        _handle_direct_replacement(removed_positions, new_cards)

# 直接替换模式（卡牌数量足够）
func _handle_direct_replacement(positions: Array, new_cards: Array):
    for i in range(positions.size()):
        var position_index = positions[i]
        var new_card = new_cards[i]
        _place_card_at_position(new_card, position_index)

# 处理卡牌不足的情况
func _handle_insufficient_cards(removed_positions: Array, new_cards: Array):
    # 1. 优先填充最左边的位置
    var filled_positions: Array = []
    for i in range(new_cards.size()):
        var position_index = removed_positions[i]
        _place_card_at_position(new_cards[i], position_index)
        filled_positions.append(position_index)
    
    # 2. 处理空隙 - 重新计算布局
    var remaining_cards = _get_all_positioned_cards()
    var new_layout = _calculate_compact_layout(remaining_cards.size())
    _apply_layout_transition(remaining_cards, new_layout)

# 获取所有已定位的卡牌
func _get_all_positioned_cards() -> Array:
    var cards: Array = []
    var positions = position_to_card.keys()
    positions.sort()
    
    for pos in positions:
        if position_to_card.has(pos):
            cards.append(position_to_card[pos])
    
    return cards

# 计算紧凑布局
func _calculate_compact_layout(card_count: int) -> Array:
    if not config.fixed_positions.has(card_count):
        LogManager.error("HandDock", "不支持%d张卡牌的布局" % card_count)
        return []
    
    return config.fixed_positions[card_count]

# 应用布局过渡动画
func _apply_layout_transition(cards: Array, new_positions: Array):
    if cards.size() != new_positions.size():
        LogManager.error("HandDock", "卡牌数量与位置数量不匹配")
        return
    
    # 更新位置映射
    position_to_card.clear()
    card_to_position.clear()
    
    # 应用新位置
    for i in range(cards.size()):
        var card = cards[i]
        var new_x = new_positions[i]
        var new_pos = Vector2(new_x, 0)  # Y坐标根据选中状态确定
        
        # 平滑动画到新位置
        var tween = create_tween()
        tween.tween_property(card, "position", new_pos, config.animation_duration)
        
        # 更新映射
        position_to_card[i] = card
        card_to_position[card] = i
    
    LogManager.debug("HandDock", "布局过渡动画已启动")

# 在指定位置放置卡牌
func _place_card_at_position(card_instance, position_index: int):
    if not config.fixed_positions.has(get_current_hand_size()):
        LogManager.error("HandDock", "无法确定位置布局")
        return
    
    var positions = config.fixed_positions[get_current_hand_size()]
    if position_index >= positions.size():
        LogManager.error("HandDock", "位置索引超出范围: %d" % position_index)
        return
    
    var target_x = positions[position_index]
    var target_pos = Vector2(target_x, 0)
    
    # 添加到容器
    card_container.add_child(card_instance)
    card_instance.position = target_pos
    
    # 更新映射
    position_to_card[position_index] = card_instance
    card_to_position[card_instance] = position_index
    
    # 连接信号
    _connect_card_signals(card_instance)
    
    LogManager.debug("HandDock", "卡牌已放置在位置%d: %s" % [position_index, card_instance.name])

# 从位置移除卡牌
func _remove_card_from_position(card_instance):
    if card_to_position.has(card_instance):
        var position_index = card_to_position[card_instance]
        position_to_card.erase(position_index)
        card_to_position.erase(card_instance)
    
    if card_instance.is_inside_tree():
        card_instance.queue_free()

# 请求新卡牌（需要与CardManager集成）
func _request_new_cards(count: int) -> Array:
    # 这里需要与CardManager或TurnManager集成
    # 暂时返回空数组，实际实现时需要调用相应的抽牌方法
    LogManager.info("HandDock", "请求%d张新卡牌" % count)
    return []

# 获取当前手牌数量
func get_current_hand_size() -> int:
    return position_to_card.size()
```

### 阶段5: 调试功能优化

#### 条件编译调试功能
```gdscript
# 位置验证函数 - 仅DEBUG模式
func _verify_positions():
    if not config.debug_mode or not config.enable_position_validation:
        return
    
    LogManager.debug("HandDock", "开始位置验证")
    # 原有验证逻辑...

# 移除的函数列表
# - _force_fix_positions() -> 完全移除
# - force_fix_card_positions() -> 完全移除  
# - _check_card_positions() -> 仅DEBUG模式保留
# - 位置监控系统 -> 仅DEBUG模式保留
```

## 🔄 集成其他组件的修改

### CardManager集成
```gdscript
# CardManager.gd 中添加
signal cards_requested(count: int)
signal cards_provided(cards: Array)

func provide_cards_for_hand(count: int) -> Array:
    var new_cards = draw(count)
    emit_signal("cards_provided", new_cards)
    return new_cards
```

### TurnManager集成
```gdscript
# TurnManager.gd 中修改出牌逻辑
func play_selected_cards() -> bool:
    # 原有逻辑...
    
    # 通知HandDock移除并补牌
    if hand_dock and hand_dock.has_method("remove_selected_cards_and_refill"):
        hand_dock.remove_selected_cards_and_refill()
    
    return true
```

## ✅ 实施检查清单

### 必须完成项
- [ ] 创建LogManager统一日志系统
- [ ] 创建HandDockConfig配置文件
- [ ] 实现SelectionManager选择管理
- [ ] 实现智能卡牌替换逻辑
- [ ] 移除所有调试函数（非DEBUG模式）
- [ ] 集成CardManager的抽牌接口

### 验证标准
- [ ] 选择卡牌后能正确移除
- [ ] 新卡牌优先补充最左位置
- [ ] 卡牌不足时正确调整布局
- [ ] 不进行不必要的重新排序
- [ ] DEBUG模式下调试功能正常
- [ ] 生产模式下无调试代码执行

**预期效果**: 代码量减少30%，逻辑更清晰，性能提升，维护性增强。
