# 奥术学院扑克 - 测试模块说明

本目录包含奥术学院扑克项目的各种测试脚本和场景。

## 测试类型

### 1. 单元测试

这些测试验证各个模块的基本功能是否正常工作，不涉及视觉展示。

- `CardManager 测试/CardManagerTest.gd` - 测试CardManager的核心功能
- `EventManagerTest.gd` - 测试EventManager的核心功能
- `EffectOrchestratorTest.gd` - 测试EffectOrchestrator的核心功能
- `WisdomHallManagerTest.gd` - 测试WisdomHallManager的核心功能

### 2. 可视化测试

这些测试结合了功能测试和视觉展示，可以直观地看到各个模块的工作效果。

- `CardManager 测试/CardManagerVisualTest.gd` - CardManager的可视化测试，展示卡牌的实际视图
- `CardManager 测试/CardManagerVisualTestSimple.gd` - CardManager的简化可视化测试
- `EventManagerVisualTest.gd` - EventManager的可视化测试，展示Buff和事件效果
- `EffectOrchestratorVisualTest.gd` - EffectOrchestrator的可视化测试，展示效果触发和应用
- `WisdomHallManagerVisualTest.gd` - WisdomHallManager的可视化测试，展示商店界面和购买流程

## 如何运行测试

1. 打开Godot编辑器
2. 加载对应的测试场景（例如 `cs/tests/CardManager 测试/CardManagerTestScene.tscn`）
3. 点击"运行"按钮或按F5运行场景
4. 观察控制台输出和UI显示的测试结果

## 测试结果

所有测试结果将保存在 `cs/tests/test_results/` 目录下，以JSON格式记录测试通过和失败情况。

## 可视化测试说明

### CardManagerVisualTest

这个测试展示了CardManager的功能，并使用实际的卡牌视图展示手牌、弃牌和打出牌的效果。

操作面板提供了以下功能：
- 抽牌：从牌库抽取指定数量的卡牌
- 弃置第一张牌：将手牌中的第一张牌弃置
- 打出第一张牌：将手牌中的第一张牌打出
- 洗牌：洗牌库
- 强化第一张牌：为手牌中的第一张牌添加红色蜡封强化
- 重置：重置所有牌堆并初始化牌库

测试步骤：
1. 使用"抽牌"按钮抽取卡牌，观察手牌区域是否显示卡牌
2. 使用"弃置第一张牌"按钮，观察手牌是否减少
3. 使用"打出第一张牌"按钮，观察手牌是否减少
4. 使用"强化第一张牌"按钮，观察卡牌是否显示强化效果
5. 使用"洗牌"按钮，观察牌库是否重新洗牌
6. 使用"重置"按钮，观察所有牌堆是否重置

## 目录结构说明

- `CardManager 测试/` - 包含所有与CardManager相关的测试文件
  - `CardManagerTest.gd` - CardManager单元测试
  - `CardManagerTestScene.tscn` - CardManager单元测试场景
  - `CardManagerVisualTest.gd` - CardManager可视化测试
  - `CardManagerVisualTestScene.tscn` - CardManager可视化测试场景
  - `CardManagerVisualTestSimple.gd` - CardManager简化可视化测试
  - `CardManagerVisualTestSimpleScene.tscn` - CardManager简化可视化测试场景 