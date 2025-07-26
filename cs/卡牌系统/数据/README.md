# 卡牌系统数据目录

本目录是卡牌游戏系统的核心数据层，包含所有游戏中使用的数据模型和管理器。通过将数据定义和管理逻辑集中在此目录下，我们实现了更清晰的MVC架构分离。

## 数据模型

这些文件定义了游戏中各种实体的数据结构：

- **CardData.gd** - 定义卡牌的基础数据，包括花色、点数、强化效果等
- **ArtifactData.gd** - 定义法器的数据，包括效果类型、参数等
- **JokerData.gd** - 定义守护灵的数据，包括触发时机、效果等
- **SpellData.gd** - 定义法术的数据，包括施放类型、充能等

所有数据模型都继承自`Resource`，可以序列化为`.tres`文件，便于存储和加载。

## 管理器

`管理器`子目录包含各种管理游戏逻辑的类：

- **CardManager.gd** - 管理牌库、手牌、弃牌堆和销毁堆
- **CardEffectManager.gd** - 处理卡牌的各种效果（蜡封、牌框、材质等）
- **DiscoveryManager.gd** - 管理魔法发现和法器的UI显示
- **JokerManager.gd** - 管理守护灵的UI显示和交互

## 数据与视图的关系

数据模型（如`CardData`）定义了游戏实体的状态和行为，而视图类（如`CardView`）负责将这些数据可视化。管理器类则协调数据和视图之间的交互。

## 使用示例

```gdscript
# 创建一张新卡牌
var card = CardData.new()
card.id = "H1"
card.base_value = 1
card.suit = "hearts"
card.name = "红桃A"

# 添加强化效果
card.add_reinforcement("WAX_SEAL", "RED")

# 创建一个守护灵
var joker = JokerData.new()
joker.item_id = "time_wizard"
joker.item_name = "时间术士"
joker.effect_type_id = "ADD_XP_PER_PAIR"
joker.effect_value_param = 3
joker.trigger_event_timing = GlobalEnums.EffectTriggerTiming.ON_SCORE_CALCULATION
```

## 重构说明

本目录整合了原先分散在`cs/主场景/abilities`、`cs/主场景/card`、`cs/主场景/discovery`和`cs/主场景/joker`等目录下的数据定义和管理器类，使项目结构更加清晰和符合MVC架构。 