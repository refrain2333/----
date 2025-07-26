# 卡牌系统管理器

本目录包含游戏系统中的各种管理器类，负责协调数据模型和视图之间的交互。

## 管理器列表

- **CardManager.gd** - 管理卡牌的核心逻辑
  - 牌库管理（抽牌、洗牌、弃牌等）
  - 手牌管理（打出卡牌、添加强化等）
  - 卡牌效果触发

- **CardEffectManager.gd** - 处理卡牌效果
  - 蜡封效果处理
  - 牌框效果处理
  - 材质效果处理

- **DiscoveryManager.gd** - 管理发现和法器系统
  - 魔法发现UI管理
  - 法器UI管理
  - 发现和法器的添加/移除

- **JokerManager.gd** - 管理守护灵系统
  - 守护灵UI管理
  - 守护灵的添加/移除
  - 守护灵效果触发

## 使用方式

这些管理器类通常由主游戏场景实例化并持有引用，例如：

```gdscript
# 在MainGame.gd中
var card_manager: CardManager
var joker_manager: JokerManager

func _ready():
    card_manager = CardManager.new(self)
    joker_manager = JokerManager.new(self)
    
    # 设置UI容器
    card_manager.setup(hand_container)
    joker_manager.setup(joker_container)
```

## 重构说明

这些管理器类原先分散在`cs/主场景/card`、`cs/主场景/discovery`和`cs/主场景/joker`等目录下，现在整合到数据层的管理器目录中，使项目结构更加清晰和符合MVC架构。 