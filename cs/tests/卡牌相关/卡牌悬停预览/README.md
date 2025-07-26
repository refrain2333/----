# 卡牌悬停信息预览功能

## 📋 功能概述

卡牌悬停信息预览功能为玩家提供了一种直观的方式来查看卡牌的详细信息，无需点击或进入特殊界面。当鼠标在卡牌上悬停一定时间后，会自动显示一个包含完整卡牌信息的浮层面板。

## ✨ 主要特性

### 🎯 核心功能
- **延时触发**: 鼠标悬停0.8秒后自动显示预览面板
- **智能定位**: 预览面板自动选择最佳显示位置，避免超出屏幕边界
- **动画效果**: 平滑的淡入淡出动画，提升用户体验
- **层级管理**: 预览面板始终显示在最前层，不被其他UI遮挡

### 📊 显示内容
- **基础信息**: 卡牌名称、数值、花色
- **数值修正**: 显示基础数值和修正后数值的对比
- **游戏属性**: 伤害、防御、消耗等战斗相关属性
- **强化效果**: 蜡封、牌框、材质等强化信息
- **稀有度**: 卡牌稀有度，带颜色区分
- **描述文本**: 卡牌的详细描述信息

### ⚙️ 可配置选项
- **悬停延时**: 可调整触发预览的等待时间（0.1-2.0秒）
- **功能开关**: 可以完全启用或禁用预览功能
- **位置调整**: 预览面板会根据卡牌位置智能调整显示位置

## 🏗️ 技术实现

### 核心组件

#### 1. CardInfoPreview.tscn/gd
- **职责**: 信息预览面板的UI和逻辑
- **特点**: 
  - 响应式布局，根据内容自动调整大小
  - 支持动态显示/隐藏不同信息区块
  - 颜色编码的信息分类显示

#### 2. CardView.gd (扩展)
- **新增属性**:
  ```gdscript
  var hover_timer: Timer = null          # 悬停计时器
  var info_preview: CardInfoPreview = null # 预览面板实例
  var hover_delay: float = 0.8           # 悬停延时
  var is_hovering: bool = false          # 悬停状态
  var preview_enabled: bool = true       # 功能开关
  ```

- **新增方法**:
  ```gdscript
  func _setup_hover_preview()           # 初始化预览系统
  func _start_hover_timer()             # 启动悬停计时器
  func _stop_hover_timer()              # 停止悬停计时器
  func _show_info_preview()             # 显示预览面板
  func _hide_info_preview()             # 隐藏预览面板
  func set_hover_delay(delay: float)    # 设置悬停延时
  func set_preview_enabled(enabled: bool) # 设置功能开关
  ```

### 工作流程

```
鼠标进入卡牌
    ↓
启动悬停计时器
    ↓
等待指定时间
    ↓
计时器超时 → 显示预览面板
    ↓
鼠标离开卡牌
    ↓
隐藏预览面板
```

## 🧪 测试说明

### 测试场景
运行 `cs/tests/卡牌悬停预览/CardHoverPreviewTest.tscn` 来测试功能。

### 测试内容
1. **基础功能测试**
   - 悬停触发预览面板显示
   - 鼠标离开时预览面板消失
   - 预览面板内容正确性

2. **配置测试**
   - 调整悬停延时时间
   - 开关预览功能
   - 不同卡牌数据的显示效果

3. **边界情况测试**
   - 屏幕边缘的位置调整
   - 快速移动鼠标的响应
   - 多张卡牌同时悬停的处理

### 测试卡牌
测试场景使用以下预制卡牌：
- `C1.tres` - 梅花A（基础卡牌）
- `H3.tres` - 红桃3（可能有强化）
- `S7.tres` - 黑桃7（中等数值）
- `D11.tres` - 方片J（高数值）
- `H13.tres` - 红桃K（最高数值）

## 🎮 使用方法

### 在现有卡牌中启用
如果你有现有的CardView实例，预览功能会自动启用。你可以通过以下方式进行配置：

```gdscript
# 设置悬停延时为1.2秒
card_view.set_hover_delay(1.2)

# 禁用预览功能
card_view.set_preview_enabled(false)

# 重新启用预览功能
card_view.set_preview_enabled(true)
```

### 在新项目中集成
1. 确保你的卡牌使用了 `CardView` 类
2. 确保 `CardData` 包含所需的属性字段
3. 将 `CardInfoPreview.tscn` 和 `CardInfoPreview.gd` 复制到你的项目中
4. 更新 `CardView.gd` 中的预览面板路径引用

## 🔧 自定义配置

### 修改预览面板样式
编辑 `CardInfoPreview.tscn` 中的样式：
- 调整背景颜色和透明度
- 修改字体大小和颜色
- 调整面板大小和边距

### 添加新的信息字段
在 `CardInfoPreview.gd` 中的 `_update_display()` 方法中添加新的信息显示逻辑：

```gdscript
# 添加新的信息字段
func _update_custom_info():
    if custom_info_label:
        custom_info_label.text = current_card_data.custom_field
```

### 调整触发条件
修改 `CardView.gd` 中的触发逻辑：

```gdscript
# 例如：只在特定条件下启用预览
func _start_hover_timer():
    if not preview_enabled or not hover_timer or not card_data:
        return
    
    # 添加自定义条件
    if not should_show_preview():
        return
    
    hover_timer.start()
```

## 🐛 故障排除

### 常见问题

1. **预览面板不显示**
   - 检查 `preview_enabled` 是否为 `true`
   - 确认 `card_data` 不为空
   - 验证预览面板场景路径是否正确

2. **预览面板位置错误**
   - 检查卡牌的 `global_position` 是否正确
   - 确认场景树结构正常
   - 验证预览面板的 `z_index` 设置

3. **信息显示不正确**
   - 检查 `CardData` 中的字段是否正确设置
   - 验证信息更新逻辑是否正常执行
   - 确认节点引用是否正确

### 调试技巧

1. **启用调试输出**
   ```gdscript
   # 在CardView.gd中添加调试信息
   func _on_hover_timeout():
       print("悬停超时，显示预览: ", card_data.name)
       if is_hovering and preview_enabled and card_data:
           _show_info_preview()
   ```

2. **检查节点结构**
   ```gdscript
   # 验证预览面板是否正确添加到场景树
   func _add_preview_to_scene():
       var main_scene = get_tree().current_scene
       print("主场景: ", main_scene)
       print("预览面板: ", info_preview)
   ```

## 📈 性能考虑

### 优化策略
1. **对象复用**: 每个CardView只创建一个预览面板实例
2. **延迟加载**: 预览面板在首次需要时才创建
3. **智能更新**: 只在数据变化时更新预览内容
4. **资源清理**: 在CardView销毁时正确清理预览面板

### 内存管理
- 预览面板会在CardView销毁时自动清理
- 计时器会在适当时机停止，避免内存泄漏
- 使用对象池模式可进一步优化性能（可选）

## 🔮 未来扩展

### 可能的改进方向
1. **动画效果**: 添加更丰富的显示动画
2. **主题支持**: 支持多种预览面板主题
3. **交互功能**: 在预览面板中添加快捷操作按钮
4. **自适应布局**: 根据屏幕大小自动调整预览面板大小
5. **多语言支持**: 支持本地化的信息显示

这个功能为卡牌游戏提供了更好的用户体验，让玩家能够快速获取卡牌信息，做出更明智的游戏决策。
