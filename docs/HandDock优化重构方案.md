# HandDock.gd 优化重构方案

## 🎯 重构目标
- **代码量减少**: 从1260行减少到700-800行 (减少40%)
- **性能提升**: 减少不必要的重排和验证
- **可维护性**: 清晰的职责分离和模块化设计
- **代码质量**: 移除调试代码，统一编码规范

## 📋 重构计划

### 阶段1: 清理调试代码 (优先级: 🔴 高)

#### 需要移除的函数 (约200行)
```gdscript
# 位置验证和调试函数
- _verify_x_positions()           # 58行 - 位置验证
- _check_card_positions()         # 56行 - 位置检测  
- _force_fix_positions()          # 6行 - 强制修复
- force_fix_card_positions()      # 71行 - 强制修复所有
- _force_reset_all_positions()    # 22行 - 强制重置

# 监控系统
- _setup_position_monitor()       # 16行 - 设置监控
- position_monitor_timer相关      # 约30行 - 定时监控
- set_monitor_interval()          # 4行 - 设置间隔
- set_position_monitoring()       # 8行 - 开关监控
- toggle_position_debug()         # 3行 - 切换调试

# 调试输入处理
- _input(event)                   # 19行 - 全局输入捕获
- _process(_delta)                # 10行 - 键盘快捷键
- debug_button_press()            # 10行 - 调试按钮
```

#### 简化日志系统
```gdscript
# 当前 (4个函数)
func _log(message: String, level: String = "INFO")
func _log_verbose(message: String) 
func _log_position(message: String)
func _log_error(message: String)

# 优化后 (1个函数)
func _log(message: String, level: LogLevel = LogLevel.INFO):
    if DEBUG_MODE and level >= current_log_level:
        print("HandDock[%s]: %s" % [level, message])
```

### 阶段2: 合并重复功能 (优先级: 🔴 高)

#### 统一位置管理
```gdscript
# 当前问题: 两个重排函数功能重叠
- _rearrange_cards()              # 110行
- _rearrange_cards_smart()        # 80行

# 重构方案: 合并为一个函数
func _rearrange_cards(preserve_positions: bool = true):
    if is_rearranging: return
    is_rearranging = true
    
    var layout = _calculate_layout(preserve_positions)
    _apply_layout(layout)
    
    is_rearranging = false

func _calculate_layout(preserve_positions: bool) -> Array:
    # 纯计算逻辑，返回位置数组
    var cards = _get_sorted_cards()
    if preserve_positions:
        return _calculate_smart_layout(cards)
    else:
        return _calculate_fixed_layout(cards)

func _apply_layout(layout: Array):
    # 纯应用逻辑，设置卡牌位置
    for i in range(layout.size()):
        var card = layout[i].card
        var position = layout[i].position
        card.position = position
```

#### 简化选择管理
```gdscript
# 当前: 3个分散的函数
- _add_to_selected_list()
- _remove_from_selected_list()  
- _update_selected_list()

# 重构: 1个统一函数
func _update_selection(card_instance, is_selected: bool):
    var index = selected_cards.find(card_instance)
    
    if is_selected and index == -1:
        selected_cards.append(card_instance)
        _log("卡牌已添加到选中列表")
    elif not is_selected and index != -1:
        selected_cards.remove_at(index)
        _log("卡牌已从选中列表移除")
```

### 阶段3: 重构复杂函数 (优先级: 🟡 中)

#### 拆分_ready()函数
```gdscript
# 当前: 77行的巨大函数
func _ready():
    # 77行代码...

# 重构: 拆分为多个小函数
func _ready():
    _setup_mouse_filters()
    _setup_ui_references()
    _setup_signal_connections()
    _setup_position_system()
    _log("HandDock初始化完成")

func _setup_mouse_filters():
    mouse_filter = MOUSE_FILTER_PASS
    if card_container:
        card_container.mouse_filter = MOUSE_FILTER_PASS

func _setup_ui_references():
    # 验证并获取UI节点引用
    var required_nodes = [
        "ButtonPanel/ButtonGrid/PlayButtonContainer/PlayButton",
        "ButtonPanel/ButtonGrid/DiscardButtonContainer/DiscardButton"
    ]
    
    for node_path in required_nodes:
        var node = get_node_or_null(node_path)
        if not node:
            _log("找不到必需节点: %s" % node_path, LogLevel.ERROR)

func _setup_signal_connections():
    # 所有信号连接逻辑
    _connect_button_signals()
    _connect_existing_card_signals()

func _setup_position_system():
    _init_position_management()
```

#### 简化update_ui()函数
```gdscript
# 当前: 48行混合逻辑
func update_ui():
    # 检查选中卡牌、获取资源、更新按钮...

# 重构: 分离关注点
func update_ui():
    var state = _get_ui_state()
    _update_button_states(state)

func _get_ui_state() -> Dictionary:
    return {
        "has_selected_cards": selected_cards.size() > 0,
        "focus_available": _is_resource_available("focus"),
        "essence_available": _is_resource_available("essence")
    }

func _update_button_states(state: Dictionary):
    if play_button:
        play_button.disabled = not (state.has_selected_cards and state.focus_available)
    if discard_button:
        discard_button.disabled = not (state.has_selected_cards and state.essence_available)

func _is_resource_available(resource_type: String) -> bool:
    var game_mgr = get_node_or_null("/root/GameManager")
    if not game_mgr: return true
    
    match resource_type:
        "focus": return game_mgr.get("focus_count", 1) > 0
        "essence": return game_mgr.get("essence_count", 1) > 0
        _: return true
```

### 阶段4: 性能优化 (优先级: 🟡 中)

#### 减少重排频率
```gdscript
# 当前问题: 每次操作都可能触发重排
# 解决方案: 使用延迟重排

var _rearrange_timer: Timer
var _pending_rearrange: bool = false

func _request_rearrange():
    if _pending_rearrange: return
    
    _pending_rearrange = true
    if not _rearrange_timer:
        _rearrange_timer = Timer.new()
        _rearrange_timer.wait_time = 0.1
        _rearrange_timer.one_shot = true
        _rearrange_timer.timeout.connect(_execute_pending_rearrange)
        add_child(_rearrange_timer)
    
    _rearrange_timer.start()

func _execute_pending_rearrange():
    _pending_rearrange = false
    _rearrange_cards()
```

#### 优化信号连接
```gdscript
# 当前: 每次都检查连接状态
# 优化: 使用信号管理器

class_name SignalManager
extends RefCounted

var _connections: Dictionary = {}

func safe_connect(source: Object, signal_name: String, target: Object, method_name: String):
    var key = "%s:%s->%s:%s" % [source.get_instance_id(), signal_name, target.get_instance_id(), method_name]
    
    if _connections.has(key): return
    
    if source.has_signal(signal_name):
        source.connect(signal_name, Callable(target, method_name))
        _connections[key] = true
```

## 🏗️ 新的类结构设计

### 主类简化
```gdscript
class_name HandDock
extends Panel

# 核心组件
var _card_manager: HandDockCardManager
var _layout_manager: HandDockLayoutManager
var _ui_manager: HandDockUIManager

# 简化的主要接口
func add_card(card_instance): _card_manager.add_card(card_instance)
func remove_card(card_instance): _card_manager.remove_card(card_instance)
func update_layout(): _layout_manager.rearrange_cards()
func update_ui(): _ui_manager.update_all()
```

### 分离的管理器类
```gdscript
# 卡牌管理器
class_name HandDockCardManager
extends RefCounted

func add_card(card_instance)
func remove_card(card_instance)  
func get_selected_cards() -> Array
func clear_selection()

# 布局管理器
class_name HandDockLayoutManager
extends RefCounted

func calculate_positions(cards: Array) -> Array
func apply_positions(layout: Array)
func rearrange_cards()

# UI管理器
class_name HandDockUIManager
extends RefCounted

func update_button_states()
func connect_signals()
func handle_interactions()
```

## 📊 重构效果预估

| 方面 | 重构前 | 重构后 | 改善 |
|------|--------|--------|------|
| 代码行数 | 1260行 | 700-800行 | -40% |
| 调试代码 | 200行 | 20行 | -90% |
| 重复代码 | 150行 | 30行 | -80% |
| 函数数量 | 45个 | 25个 | -44% |
| 平均函数长度 | 28行 | 18行 | -36% |

## ✅ 实施检查清单

### 阶段1完成标准
- [ ] 移除所有调试验证函数
- [ ] 移除位置监控系统  
- [ ] 简化日志系统
- [ ] 移除调试输入处理

### 阶段2完成标准
- [ ] 合并位置管理函数
- [ ] 统一选择管理逻辑
- [ ] 消除代码重复

### 阶段3完成标准
- [ ] _ready()函数拆分完成
- [ ] update_ui()函数简化
- [ ] 复杂函数重构完成

### 阶段4完成标准
- [ ] 实现延迟重排机制
- [ ] 优化信号连接逻辑
- [ ] 性能测试通过

**预期完成时间**: 2-3个工作日
**风险评估**: 低 (主要是代码清理和重构)
**测试要求**: 确保所有现有功能正常工作
