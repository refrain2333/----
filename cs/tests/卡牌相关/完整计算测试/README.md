# 🧪 完整计算测试系统

## 📋 概述

完整计算测试系统是基于原有牌型识别测试系统的扩展版本，专门用于测试包括守护灵、法术、法器等各种因素影响下的得分计算。

## 🎯 测试目标

- **基础牌型计算**: 验证V2.3牌型识别和得分计算的准确性
- **守护灵效果**: 测试守护灵对得分计算的影响
- **法术效果**: 测试法术对得分的修改效果
- **法器效果**: 测试法器的被动加成效果
- **组合效果**: 测试多种能力同时作用的复杂情况

## 📁 文件结构

```
cs/tests/卡牌相关/完整计算测试/
├── CompleteCalculationTestScript.gd    # 主测试脚本
├── CompleteCalculationTestScene.tscn   # 测试场景
├── CompleteTestGameManager.gd          # 测试用游戏管理器
└── README.md                          # 本说明文档
```

## 🔧 核心组件

### CompleteCalculationTestScript.gd

主测试脚本，包含以下功能：

- **CompleteTestCase类**: 扩展的测试用例数据结构，支持守护灵、法术、法器配置
- **效果模拟系统**: 模拟各种能力对得分计算的影响
- **测试执行引擎**: 自动化执行所有测试用例并生成报告

### CompleteTestGameManager.gd

专门为测试设计的游戏管理器，提供：

- **能力管理**: 守护灵、法术、法器的添加、移除和查询
- **状态跟踪**: 游戏状态、分数、回合等信息管理
- **配置支持**: 灵活的游戏参数配置

## 🎮 使用方法

### 运行测试

1. 在Godot编辑器中打开 `CompleteCalculationTestScene.tscn`
2. 点击"运行场景"按钮
3. 查看控制台输出的测试结果

### 添加新测试用例

在 `create_complete_test_cases()` 函数中添加新的测试用例：

```gdscript
# 创建新测试用例
var new_test = CompleteTestCase.new(
    "C6.1",                              # 测试ID
    "描述信息",                           # 测试描述
    ["D1", "S1", "H13", "C11", "D8"],    # 卡牌ID数组
    1,                                   # 牌型等级
    0,                                   # 基础附加分
    1.0,                                 # 最终倍率
    64,                                  # 期望得分
    HandTypeEnumsClass.HandType.PAIR,    # 期望牌型
    1.2                                  # 期望倍率
)

# 添加守护灵效果
new_test.jokers.append(create_test_joker("id", "名称", "效果类型", 效果值))

# 添加法器效果
new_test.artifacts.append(create_test_artifact("id", "名称", "效果类型", 效果值))

# 添加法术效果
new_test.spells.append(create_test_spell("id", "名称", "效果类型", 效果值))

cases.append(new_test)
```

## 🎭 支持的效果类型

### 守护灵效果

| 效果类型 | 描述 | 参数示例 |
|----------|------|----------|
| SCORE_PERCENT_BONUS | 分数百分比加成 | 0.2 (20%加成) |
| BONUS_SCORE_FLAT | 固定分数加成 | 50 (增加50分) |
| CARD_TYPE_MULTIPLIER_PAIR | 对子倍率加成 | 0.3 (30%加成) |

### 法器效果

| 效果类型 | 描述 | 参数示例 |
|----------|------|----------|
| SCORE_MULTIPLIER | 分数倍率 | 1.5 (1.5倍) |
| BONUS_SCORE_ARTIFACT | 法器固定分数加成 | 30 (增加30分) |
| LORE_POINTS_PERCENT_BONUS | 传说点数加成 | 0.05 (5%加成) |

### 法术效果

| 效果类型 | 描述 | 参数示例 |
|----------|------|----------|
| DOUBLE_SCORE | 分数翻倍 | 2.0 (翻倍) |
| BONUS_SCORE_SPELL | 法术固定分数加成 | 40 (增加40分) |
| DRAW_CARDS | 抽牌效果 | 3 (抽3张牌) |

## 📊 测试用例示例

### 基础测试
```gdscript
# C1.1: 基础一对A测试
CompleteTestCase.new("C1.1", "基础一对A", ["D1", "S1", "H13", "C11", "D8"], 1, 0, 1.0, 64, HandTypeEnumsClass.HandType.PAIR, 1.2)
```

### 守护灵效果测试
```gdscript
# C2.1: 一对A + 20%分数加成守护灵
var joker_test = CompleteTestCase.new("C2.1", "一对A + 分数加成守护灵", ["D1", "S1", "H13", "C11", "D8"], 1, 0, 1.0, 77, HandTypeEnumsClass.HandType.PAIR, 1.2)
joker_test.jokers.append(create_test_joker("score_bonus", "分数加成", "SCORE_PERCENT_BONUS", 0.2))
```

### 组合效果测试
```gdscript
# C5.1: 三条7 + 守护灵 + 法器 + 法术组合
var combo_test = CompleteTestCase.new("C5.1", "三条7 + 守护灵 + 法器 + 法术", ["D7", "S7", "H7", "C1", "D5"], 3, 50, 1.0, 832, HandTypeEnumsClass.HandType.THREE_KIND, 2.2)
combo_test.jokers.append(create_test_joker("bonus_flat", "固定加成", "BONUS_SCORE_FLAT", 30))
combo_test.artifacts.append(create_test_artifact("artifact_bonus", "法器加成", "BONUS_SCORE_ARTIFACT", 20))
combo_test.spells.append(create_test_spell("double_score", "分数翻倍", "DOUBLE_SCORE", 2.0))
```

## 🔍 测试结果解读

测试运行后会在控制台输出详细信息：

```
🧪 开始完整计算测试

📊 开始执行 5 个完整计算测试用例...

🔍 执行测试: C1.1 - 基础一对A
✅ C1.1: 通过

🔍 执行测试: C2.1 - 一对A + 分数加成守护灵
🎭 应用守护灵效果: 分数加成
✅ C2.1: 通过

🎯 完整计算测试结果总结:
  通过: 5
  失败: 0
  总计: 5
  成功率: 100.0%
```

## 🚀 扩展指南

### 添加新的效果类型

1. 在对应的 `apply_xxx_effect()` 函数中添加新的效果处理逻辑
2. 更新效果类型文档
3. 创建相应的测试用例

### 集成真实的效果系统

当项目中的效果系统完善后，可以将模拟的效果应用替换为真实的效果系统调用。

## 🎯 与原测试系统的区别

| 特性 | 原牌型识别测试 | 完整计算测试 |
|------|----------------|--------------|
| 测试范围 | 仅牌型识别和基础计算 | 包含所有能力系统 |
| 测试用例 | 23个基础用例 | 5个扩展用例（可继续添加） |
| 效果支持 | 无 | 守护灵、法术、法器 |
| 复杂度 | 简单 | 复杂组合效果 |
| 独立性 | 完全独立 | 基于原系统扩展 |

## 📝 注意事项

1. **独立性**: 本测试系统完全独立于原有测试，不会影响原有测试内容
2. **UID唯一性**: 所有文件都使用了新的UID，确保不会产生冲突
3. **扩展性**: 设计时考虑了未来的扩展需求，可以轻松添加新的测试用例和效果类型
4. **模拟性**: 当前的效果应用是模拟实现，实际项目中应该集成真实的效果系统

## 🎉 总结

完整计算测试系统为项目提供了一个强大的测试平台，能够验证复杂的游戏机制和能力系统的正确性。通过这个系统，可以确保游戏的核心计算逻辑在各种情况下都能正常工作。
