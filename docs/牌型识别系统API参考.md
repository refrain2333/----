# 🎯 牌型识别系统 - API参考文档

## 📋 概述

本文档提供牌型识别系统所有公共API的详细参考，包括方法签名、参数说明、返回值格式和使用示例。

---

## 🧠 SmartHandAnalyzer

智能多张牌最佳组合分析器，支持1-13张任意数量卡牌的牌型识别。

### find_best_hand()

从N张卡牌中找出最佳5张组合并分析牌型。

```gdscript
static func find_best_hand(cards: Array) -> Dictionary
```

**参数**：
- `cards: Array[CardData]` - 要分析的卡牌数组（1-13张）

**返回值**：`Dictionary` - 分析结果字典
```gdscript
{
    "hand_type": HandTypeEnums.HandType,      # 牌型枚举
    "hand_type_name": String,                 # 牌型名称
    "description": String,                    # 详细描述
    "primary_value": int,                     # 主要数值
    "secondary_value": int,                   # 次要数值
    "kickers": Array[int],                    # 踢脚牌
    "base_score": int,                        # 基础分值
    "cards": Array[CardData],                 # 构成牌型的卡牌
    "best_hand_cards": Array[CardData],       # 最佳组合卡牌
    "discarded_cards": Array[CardData],       # 弃置卡牌
    "analysis_time": int,                     # 分析耗时(ms)
    "combinations_tested": int,               # 测试组合数量
    "total_cards": int                        # 总卡牌数量
}
```

**使用示例**：
```gdscript
var cards = [card1, card2, card3, card4, card5]
var result = SmartHandAnalyzer.find_best_hand(cards)
print("牌型: %s" % result.hand_type_name)
print("得分: %d" % result.base_score)
```

---

## 🎯 HandTypeAnalyzer

基础5张牌牌型识别器，专门处理标准5张牌的牌型分析。

### analyze_hand()

分析5张牌的牌型。

```gdscript
static func analyze_hand(cards: Array) -> Dictionary
```

**参数**：
- `cards: Array[CardData]` - 必须是5张卡牌

**返回值**：`Dictionary` - 分析结果字典（格式同SmartHandAnalyzer）

**使用示例**：
```gdscript
var five_cards = [card1, card2, card3, card4, card5]
var result = HandTypeAnalyzer.analyze_hand(five_cards)
```

---

## 💰 HandTypeScoreManager

牌型得分计算管理器，负责完整的得分计算逻辑。

### calculate_poker_hand_score()

计算扑克牌型的完整得分。

```gdscript
static func calculate_poker_hand_score(cards: Array, ranking_manager: HandTypeRankingManager = null) -> Dictionary
```

**参数**：
- `cards: Array[CardData]` - 要计算得分的卡牌数组
- `ranking_manager: HandTypeRankingManager` - 等级管理器实例（可选，默认创建新实例）

**返回值**：`Dictionary` - 得分计算结果
```gdscript
{
    "hand_analysis": Dictionary,              # 牌型分析结果
    "fixed_base_score": int,                  # 固定基础分
    "dynamic_rank_score": int,                # 动态等级分
    "bonus_score": int,                       # 附加分
    "dynamic_multiplier": float,              # 动态倍率
    "final_score": int,                       # 最终得分
    "calculation_formula": String,            # 计算公式
    "detailed_formula": String,               # 详细公式
    "hand_type_level": int,                   # 牌型等级
    "level_info": String                      # 等级信息
}
```

**使用示例**：
```gdscript
var ranking_manager = HandTypeRankingManager.new()
var result = HandTypeScoreManager.calculate_poker_hand_score(cards, ranking_manager)
print("最终得分: %d" % result.final_score)
print("计算公式: %s" % result.detailed_formula)
```

### calculate_quick_score()

快速计算得分（简化版本）。

```gdscript
static func calculate_quick_score(cards: Array) -> int
```

**参数**：
- `cards: Array[CardData]` - 要计算得分的卡牌数组

**返回值**：`int` - 最终得分

**使用示例**：
```gdscript
var score = HandTypeScoreManager.calculate_quick_score(cards)
print("快速得分: %d" % score)
```

---

## 🎯 HandTypeRankingManager

动态牌型等级管理器，负责LV1-LV5等级管理和倍率计算。

### 构造函数

```gdscript
func _init()
```

创建新的等级管理器实例，所有牌型初始化为LV1。

### get_hand_type_level()

获取牌型当前等级。

```gdscript
func get_hand_type_level(hand_type: HandType) -> int
```

**参数**：
- `hand_type: HandTypeEnums.HandType` - 牌型枚举

**返回值**：`int` - 当前等级（1-5）

### set_hand_type_level()

设置牌型等级。

```gdscript
func set_hand_type_level(hand_type: HandType, level: int) -> bool
```

**参数**：
- `hand_type: HandTypeEnums.HandType` - 牌型枚举
- `level: int` - 要设置的等级（1-5）

**返回值**：`bool` - 设置是否成功

### level_up_hand_type()

升级牌型等级。

```gdscript
func level_up_hand_type(hand_type: HandType) -> bool
```

**参数**：
- `hand_type: HandTypeEnums.HandType` - 牌型枚举

**返回值**：`bool` - 升级是否成功

### get_multiplier()

获取牌型当前倍率。

```gdscript
func get_multiplier(hand_type: HandType) -> float
```

**参数**：
- `hand_type: HandTypeEnums.HandType` - 牌型枚举

**返回值**：`float` - 当前倍率

### get_base_multiplier()

获取牌型基础倍率（LV1倍率）。

```gdscript
func get_base_multiplier(hand_type: HandType) -> float
```

### set_all_levels()

批量设置所有牌型等级。

```gdscript
func set_all_levels(level: int) -> bool
```

**参数**：
- `level: int` - 要设置的等级（1-5）

**返回值**：`bool` - 设置是否成功

### reset_all_levels()

重置所有牌型等级为LV1。

```gdscript
func reset_all_levels()
```

### get_all_levels()

获取所有牌型的等级状态。

```gdscript
func get_all_levels() -> Dictionary
```

**返回值**：`Dictionary` - 所有牌型的等级映射

### 信号

```gdscript
signal hand_type_level_changed(hand_type: HandType, old_level: int, new_level: int)
signal hand_type_upgraded(hand_type: HandType, new_level: int, new_multiplier: float)
signal all_levels_reset()
```

**使用示例**：
```gdscript
var ranking_manager = HandTypeRankingManager.new()

# 设置一对为LV3
ranking_manager.set_hand_type_level(HandTypeEnums.HandType.PAIR, 3)

# 获取倍率
var multiplier = ranking_manager.get_multiplier(HandTypeEnums.HandType.PAIR)
print("一对LV3倍率: %.1fx" % multiplier)

# 升级三条
ranking_manager.level_up_hand_type(HandTypeEnums.HandType.THREE_KIND)
```

---

## 📊 HandTypeEnums

牌型枚举和常量定义，提供系统中所有的枚举、常量和配置数据。

### 枚举定义

#### HandType

```gdscript
enum HandType {
    HIGH_CARD = 1,        # 高牌
    PAIR = 2,             # 一对
    TWO_PAIR = 3,         # 两对
    THREE_KIND = 4,       # 三条
    STRAIGHT = 5,         # 顺子
    FLUSH = 6,            # 同花
    FULL_HOUSE = 7,       # 葫芦
    FOUR_KIND = 8,        # 四条
    STRAIGHT_FLUSH = 9,   # 同花顺
    ROYAL_FLUSH = 10,     # 皇家同花顺
    FIVE_KIND = 11        # 五条
}
```

### 常量定义

#### HAND_TYPE_NAMES

```gdscript
const HAND_TYPE_NAMES = {
    HandType.HIGH_CARD: "高牌",
    HandType.PAIR: "一对",
    HandType.TWO_PAIR: "两对",
    HandType.THREE_KIND: "三条",
    HandType.STRAIGHT: "顺子",
    HandType.FLUSH: "同花",
    HandType.FULL_HOUSE: "葫芦",
    HandType.FOUR_KIND: "四条",
    HandType.STRAIGHT_FLUSH: "同花顺",
    HandType.ROYAL_FLUSH: "皇家同花顺",
    HandType.FIVE_KIND: "五条"
}
```

#### BASE_SCORES

```gdscript
const BASE_SCORES = {
    HandType.HIGH_CARD: 5,
    HandType.PAIR: 10,
    HandType.TWO_PAIR: 20,
    HandType.THREE_KIND: 30,
    HandType.STRAIGHT: 40,
    HandType.FLUSH: 50,
    HandType.FULL_HOUSE: 60,
    HandType.FOUR_KIND: 80,
    HandType.STRAIGHT_FLUSH: 100,
    HandType.ROYAL_FLUSH: 150,
    HandType.FIVE_KIND: 200
}
```

#### LEVEL_MULTIPLIERS

```gdscript
const LEVEL_MULTIPLIERS = {
    HandType.HIGH_CARD: [1.0, 1.2, 1.5, 1.8, 2.0],
    HandType.PAIR: [1.5, 1.8, 2.1, 2.5, 3.0],
    HandType.TWO_PAIR: [2.0, 2.4, 2.8, 3.2, 3.6],
    # ... 其他牌型配置
}
```

### 工具方法

#### is_valid_hand_type()

```gdscript
static func is_valid_hand_type(hand_type: int) -> bool
```

验证牌型枚举值是否有效。

#### is_valid_level()

```gdscript
static func is_valid_level(level: int) -> bool
```

验证等级值是否有效（1-5）。

#### get_hand_type_name()

```gdscript
static func get_hand_type_name(hand_type: HandType) -> String
```

获取牌型的中文名称。

#### calculate_dynamic_multiplier()

```gdscript
static func calculate_dynamic_multiplier(hand_type: HandType, level: int) -> float
```

计算指定牌型和等级的动态倍率。

---

## 🧪 HandTypeTestCore

牌型识别测试核心模块，提供统一的测试接口。

### analyze_hand_type()

分析手牌牌型（主要测试接口）。

```gdscript
func analyze_hand_type(cards: Array) -> Dictionary
```

**参数**：
- `cards: Array[CardData]` - 要分析的卡牌数组

**返回值**：`Dictionary` - 完整的测试结果，包含分析结果和性能指标

**使用示例**：
```gdscript
var test_core = HandTypeTestCore.new()
var result = test_core.analyze_hand_type(cards)
print("测试结果: %s" % result.hand_type_name)
```

---

## 🎮 使用模式

### 基础牌型识别

```gdscript
# 1. 准备卡牌数据
var cards = [
    create_card("hearts", 7),
    create_card("diamonds", 7),
    create_card("clubs", 9)
]

# 2. 执行识别
var result = SmartHandAnalyzer.find_best_hand(cards)

# 3. 处理结果
match result.hand_type:
    HandTypeEnums.HandType.PAIR:
        print("识别到一对: %s" % result.description)
    HandTypeEnums.HandType.HIGH_CARD:
        print("识别到高牌: %s" % result.description)
```

### 完整得分计算流程

```gdscript
# 1. 创建等级管理器
var ranking_manager = HandTypeRankingManager.new()

# 2. 设置牌型等级
ranking_manager.set_hand_type_level(HandTypeEnums.HandType.PAIR, 3)

# 3. 计算完整得分
var score_result = HandTypeScoreManager.calculate_poker_hand_score(cards, ranking_manager)

# 4. 显示结果
print("牌型: %s" % score_result.hand_analysis.hand_type_name)
print("等级: LV%d" % score_result.hand_type_level)
print("倍率: %.1fx" % score_result.dynamic_multiplier)
print("最终得分: %d分" % score_result.final_score)
print("计算公式: %s" % score_result.detailed_formula)
```

### 批量测试

```gdscript
# 1. 准备测试数据
var test_cases = [
    [♠7, ♥7, ♦9, ♣2, ♠5],  # 一对
    [♠5, ♥6, ♦7, ♣8, ♠9],  # 顺子
    [♠2, ♠5, ♠7, ♠9, ♠J]   # 同花
]

# 2. 批量执行测试
for cards in test_cases:
    var result = SmartHandAnalyzer.find_best_hand(cards)
    print("测试结果: %s，得分: %d" % [result.hand_type_name, result.base_score])
```

---

## ⚠️ 注意事项

### 参数验证

- 所有接受卡牌数组的方法都会验证输入参数
- 空数组会返回空结果或默认值
- 超出范围的等级值会被拒绝并返回错误

### 性能考虑

- 1-5张卡牌：使用直接分析，性能最佳
- 6-10张卡牌：使用穷举算法，性能良好
- 11-13张卡牌：使用启发式算法，性能优化

### 内存管理

- 分析结果包含对原始卡牌的引用，注意内存泄漏
- 大量分析时建议使用对象池
- 测试完成后及时清理临时数据

### 错误处理

- 所有静态方法都包含错误检查
- 错误信息通过`push_error()`输出到控制台
- 返回值中包含错误状态标识

---

*API参考版本：v1.0*  
*最后更新：2025-07-29*
