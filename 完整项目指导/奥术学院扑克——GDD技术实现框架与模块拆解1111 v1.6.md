# 奥术学院扑克——技术实现框架与模块拆解 v1.6

基于您提供的Godot项目架构，我们将详细规划如何逐步实现完整的游戏功能。

## 核心架构与设计原则

- **单例模式**：`GameManager` (全局游戏状态和核心逻辑)、`UIRegistry` (UI组件管理)、`EventManager` (全局事件管理)、`ScoreCalculator` (复杂的得分计算)。
- **数据驱动**：所有游戏内容（卡牌数据、法器、法术、守护灵、强化效果、游戏配置等）都通过`Resource`文件或JSON等数据格式定义，而非硬编码。
- **信号系统**：实现模块间松散耦合通信。管理模块发出信号，UI模块或其他逻辑模块监听并响应。
- **状态机**：`GameManager` 将采用更复杂的状态机来管理游戏流程（学年、学期、研习/商店/考核等）。
- **责任分离**：每个模块只做一件事，且做好。例如，`CardManager`只管牌的逻辑，`CardView`只管牌的显示，`ScoreCalculator`只管分数的计算。

------

## 逐步实现计划与模块拆解

我们将按功能层级和依赖关系，从基础数据到复杂逻辑，分阶段实现。

### **阶段一：基础数据与全局常量**

**目标**：定义所有游戏数据结构为Godot `Resource`，并创建全局枚举和配置，为后续所有模块提供数据基础。

1. **全局常量与配置 (`cs/Global/`)**

   - `cs/Global/GlobalEnums.gd` (新建GDScript文件)

     - **目的**：集中管理所有游戏中使用的枚举类型，确保代码一致性和可读性。

     - 代码示例

       ：

       ```
       class_name GlobalEnums
       enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
       enum TermType { SPRING, SUMMER, AUTUMN, WINTER }
       enum FactionType { ELEMENTAL, RUNE, TIME_SPACE, ARTIFICE }
       enum CardReinforcementType { WAX_SEAL, FRAME, MATERIAL }
       enum WaxSealType { RED, BLUE, PURPLE, GOLD, GREEN, ORANGE, BROWN, WHITE }
       enum FrameType { STONE, SILVER, GOLD }
       enum MaterialType { GLASS, ROCK, METAL }
       enum EffectTriggerTiming { ON_TURN_START, BEFORE_PLAY, ON_SCORE_CALCULATION, ON_TURN_END, ON_DRAW, ON_DISCARD, ON_DESTROY }
       enum SpellType { INSTANT_USE, ACTIVE_SKILL } # 新增，区分瞬发法术类型
       # ... 其他需要的枚举 (例如牌型类型，可以定义为字符串常量方便Dict索引)
       const CARD_TYPE_HIGH_CARD = "HighCard"
       const CARD_TYPE_PAIR = "Pair"
       # ... 其它牌型
       ```

     - **实现建议**：将其设置为**自动加载 (Autoload)**，便于在任何脚本中直接访问。

   - `cs/Global/GameConfig.gd` (新建GDScript Resource)

     - **目的**：存储所有游戏平衡性相关的配置数据，方便策划调整。

     - **继承**：`extends Resource`

     - 字段示例

       ：

       ```
       class_name GameConfig extends Resource
       
       @export var victory_scores: Dictionary = {1: 500, 2: 1200, 3: 2500, 4: 5000, 5: 10000, 6: 20000}
       @export var term_rewards: Dictionary # {GlobalEnums.TermType.SPRING: {xp: 20, card_wax: GlobalEnums.WaxSealType.RED}, ...}
       @export var initial_hand_size: int = 8
       @export var max_active_spells_per_turn: int = 2 # 每回合可使用技能区法术上限
       @export var max_discard_redraw_count: int = 3 # 弃牌/换牌上限
       
       @export var card_type_base_scores: Dictionary = {
           GlobalEnums.CARD_TYPE_HIGH_CARD: 5,
           GlobalEnums.CARD_TYPE_PAIR: 10,
           # ... 所有牌型基础分
       }
       @export var card_type_level_multipliers: Dictionary = {
           GlobalEnums.CARD_TYPE_HIGH_CARD: [1.0, 1.2, 1.4, 1.6, 1.8],
           GlobalEnums.CARD_TYPE_PAIR: [1.5, 2.0, 2.5, 3.0, 3.5],
           # ... 所有牌型倍率
       }
       # ... 商店刷新概率、法器/法术/守护灵费用范围等
       ```

     - **实现建议**：在 `assets/data/` 目录下创建 `GameConfig.tres` 资源实例，并在 `GameManager` 中加载它。

2. **核心数据资源定义 (`cs/主场景/abilities/` 和 `cs/主场景/card/`)**

   - `cs/主场景/card/CardData.gd` (重构为GDScript Resource)

     - **目的**：定义每张符文牌的完整数据，包括其强化状态。

     - **继承**：`extends Resource`

     - 字段

       ：

       ```
       class_name CardData extends Resource
       @export var id: String # 唯一ID, 如 "H1", "S13"
       @export var base_value: int # 1-13 (A-K)
       @export var suit: String # "hearts", "diamonds", "clubs", "spades"
       @export var name: String # "红桃A"
       @export var image_path: String # 卡牌图片路径
       
       @export var wax_seals: Array[String] = [] # 存储 GlobalEnums.WaxSealType 字符串
       @export var frame_type: String = "" # 存储 GlobalEnums.FrameType 字符串
       @export var material_type: String = "" # 存储 GlobalEnums.MaterialType 字符串
       ```

     - 方法

       ：

       ```
       func get_modified_value(game_manager: GameManager) -> int: # 获取当前牌面修正值
           var modified_val = base_value
           # 示例：应用真理之眼、石质牌框、学年Debuff等
           if frame_type == GlobalEnums.FrameType.STONE:
               modified_val += 2
           # 根据 GameManager 提供的效果接口计算，例如：modified_val += game_manager.get_active_effect_modifier("card_value_modifier")
           return modified_val
       
       func add_reinforcement(type: String, effect: String):
           # 根据 type (WAX_SEAL/FRAME/MATERIAL) 添加 effect 到对应数组/字段
           # 确保 wax_seals 允许重复，frame_type/material_type 覆盖
       
       func remove_wax_seal(seal_type: String):
           # 从 wax_seals 数组中移除指定类型的蜡封
       
       func clone() -> CardData: # 深拷贝卡牌实例，用于复制牌
           var new_card = CardData.new()
           new_card.id = id + "_" + str(randi()) # 复制品有新ID
           new_card.base_value = base_value
           new_card.suit = suit
           new_card.name = name
           new_card.image_path = image_path
           new_card.wax_seals = wax_seals.duplicate() # 复制数组
           new_card.frame_type = frame_type
           new_card.material_type = material_type
           return new_card
       ```

     - **实现建议**：在 `assets/data/cards/` 目录下为所有52张基础牌创建 `.tres` 文件。

   - `cs/主场景/abilities/ArtifactData.gd` (新建GDScript Resource)

     - **目的**：定义传奇法器的数据。
     - **字段**：`id`, `name`, `description`, `rarity` (GlobalEnums.Rarity), `cost`, `effect_type` (String, 描述效果类型如"ADD_XP_PER_PAIR"), `effect_value` (Variant, 效果参数)。
     - **实现建议**：在 `assets/data/artifacts/` 目录下创建所有法器的 `.tres` 文件。

   - `cs/主场景/abilities/SpellData.gd` (新建GDScript Resource)

     - **目的**：定义瞬发法术的数据。
     - **字段**：`id`, `name`, `description`, `rarity`, `cost`, `spell_type` (GlobalEnums.SpellType), `effect_type`, `effect_value`, `charges` (int, 如果是技能区常驻法术，用于记录数量)。
     - **实现建议**：在 `assets/data/spells/` 目录下创建所有法术的 `.tres` 文件。

   - `cs/主场景/abilities/JokerData.gd` (新建GDScript Resource)

     - **目的**：定义守护灵的数据。
     - **字段**：`id`, `name`, `description`, `cost`, `trigger_timing` (GlobalEnums.EffectTriggerTiming), `effect_type`, `effect_value`.
     - **实现建议**：在 `assets/data/jokers/` 目录下创建所有守护灵的 `.tres` 文件。

### **阶段二：核心管理模块**

**目标**：实现游戏状态、流程、能力、事件的核心管理逻辑，使各个系统能够协同工作。

1. **游戏管理器 (`cs/Global/GameManager.gd`)**

   - **职责**：**全局核心单例**。管理游戏状态（学年、学期、分数、资源）、玩家能力列表、牌型等级、游戏流程推进。

   - 字段

     ：

     ```
     var current_year: int = 1
     var current_term: GlobalEnums.TermType = GlobalEnums.TermType.SPRING
     var player_score: int = 0 # 当前学年累积总分
     var lore_points: int = 0  # 货币
     var artifact_slots: int = 2
     var spell_bag_capacity: int = 3
     var joker_slots: int = 1
     var equipped_artifacts: Array[ArtifactData] = [] # 存储法器 Resource 实例
     var spell_inventory: Array[SpellData] = [] # 存储 SpellData Resource 实例 (注意：这里需要是实例，且 charges 可变)
     var active_jokers: Array[JokerData] = [] # 存储 JokerData Resource 实例
     var card_type_levels: Dictionary = {} # 存储牌型等级，所有牌型初始为LV1 (GameConfig中定义默认)
     var player_hand_size_modifier: int = 0 # 来自法器/学年Debuff等，影响手牌上限
     var current_assessment_score: int = 0 # 冬季考核累积得分
     
     @onready var game_config: GameConfig = preload("res://assets/data/game_config.tres") # 预加载配置
     ```

   - 主要方法

     ：

     - `_ready()`: 确保是单例，初始化 `card_type_levels` 从 `game_config`。
     - `initialize_game_state()`: 在新游戏开始时调用，重置所有玩家数据、清空能力列表、重置牌型等级。
     - `start_new_year(year: int)`: 更新 `current_year`，应用学年限制/增益，发出 `new_year_started` 信号。
     - `start_term(term: GlobalEnums.TermType)`: 更新 `current_term`，发出 `term_started` 信号。
     - `end_term()`: **触发 `TermRewardsManager` 获取学期奖励** (将在UI阶段实现)，然后发出 `term_ended` 信号（通知 `MainGame` 进入商店）。
     - `start_wisdom_hall()`: 准备商店数据，发出 `wisdom_hall_opened` 信号。
     - `start_assessment()`: 重置 `current_assessment_score`，获取目标分数，发出 `assessment_started` 信号。
     - `add_lore(amount: int)`: 增加学识点，考虑**魔力水晶法器加成** (`get_active_effects(ON_SCORE_CALCULATION)`)，发出 `lore_changed` 信号。
     - `add_artifact(artifact: ArtifactData)`: 添加法器到 `equipped_artifacts`，发出 `player_abilities_changed`。
     - `add_spell(spell: SpellData)`: 添加法术到 `spell_inventory`（注意叠加逻辑，如果已有同名则 `charges++`），发出 `player_abilities_changed`。
     - `activate_joker(joker: JokerData, old_joker_index: int = -1)`: 激活守护灵，处理替换逻辑，发出 `player_abilities_changed`。
     - `get_current_hand_size() -> int`: 计算当前实际手牌上限 (基础 + 法器 `增幅手套` + 学年Debuff `手牌上限-2`)。
     - `get_card_type_level(type_name: String) -> int`: 获取牌型等级。
     - `modify_card_type_level(type_name: String, amount: int)`: 提升牌型等级，限制在LV5，发出 `card_type_levels_changed`。
     - `get_active_effects(timing: GlobalEnums.EffectTriggerTiming) -> Array[Dictionary]`: **非常关键**。遍历 `equipped_artifacts` 和 `active_jokers`，根据 `effect_type` 和 `effect_value` 收集所有在特定 `timing` 触发的效果参数，例如 `{"type": "ADD_XP_PER_PAIR", "value": 3}`。`EventManager` 的 Buff/Debuff 也通过此接口提供。
     - `trigger_effect_logic(effect_data: Dictionary, params: Dictionary)`: 根据 `effect_data` (来自 `get_active_effects` 返回的字典) 调度具体的逻辑。例如，如果 `effect_type` 是 "ADD_XP_PER_PAIR"，则从 `params` 中获取牌型信息，然后调用 `add_lore()`。
     - `use_active_spell(spell_id: String, target_cards: Array[CardData] = [])`: 玩家从UI点击法术时调用，消耗法术 charges，触发法术效果。

   - 信号

     ：

     - `game_state_changed`: (year, term, player_score, lore_points) - UI更新
     - `player_abilities_changed`: (artifacts, spells, jokers) - UI更新
     - `card_type_levels_changed`: (card_type_levels) - UI更新
     - `new_year_started(year_num)`
     - `term_started(term_type)`
     - `term_ended()`
     - `wisdom_hall_opened()`
     - `assessment_started(year_num)`
     - `assessment_score_updated(current_score, target_score)`
     - `game_won()`
     - `game_lost()`
     - `lore_changed(new_lore_points)`
     - `spell_used(spell_id)`

2. **事件管理器 (`cs/Global/EventManager.gd`)**

   - **职责**：管理游戏中的各种随机事件和临时Buff/Debuff。

   - 字段

     ：

     ```
     var active_term_buffs: Array[Dictionary] = [] # 跳过研习获得的学年Buff
     var active_turn_buffs: Array[Dictionary] = [] # 跳过研习获得的回合Buff
     var active_debuffs: Array[Dictionary] = [] # 事件造成的临时Debuff (结构如 {"type": "HAND_SIZE_MODIFIER", "value": -1, "duration": 1})
     var arcane_intuition_perfect_score: int = -1 # 奥术直觉考验的目标分
     var is_arcane_intuition_active: bool = false
     var arcane_intuition_target_info: Dictionary = {} # 存储奥术直觉考验时的游戏状态快照
     ```

   - 主要方法

     ：

     - `_ready()`: 确保是单例。

     - `add_term_buff(buff_data: Dictionary)`: 添加学年Buff，持续到学年结束。

     - `add_turn_buff(buff_data: Dictionary)`: 添加回合Buff，在 `GameManager` 回合结束时调用 `EventManager.clear_turn_buffs()`。

     - `apply_debuff(debuff_data: Dictionary)`: 添加Debuff，根据 `duration` 字段在每回合结束时减少 `duration` 或由 `GameManager` 在学年结束时清除。

     - `get_modifier(effect_type: String) -> Variant`: 返回所有活跃Buff/Debuff对某个效果的累积修改量（例如，手牌上限修正、基础分修正），供 `GameManager` 和 `ScoreCalculator` 调用。

     - `trigger_random_event(current_year: int)`: 根据学年和概率触发随机事件（包括奥术直觉考验或临时Debuff）。

     - ```
       trigger_arcane_intuition_test(player_hand: Array[CardData], player_abilities: Dictionary, game_state: Dictionary)
       ```

       :

       - 调用 `ScoreCalculator.calculate_perfect_score(...)` 计算最优解，存储在 `arcane_intuition_perfect_score`。
       - 设置 `is_arcane_intuition_active = true`。
       - 发出 `arcane_intuition_started` 信号。

     - ```
       check_arcane_intuition_result(player_actual_score: int)
       ```

       :

       - 比较 `player_actual_score` 与 `arcane_intuition_perfect_score`。
       - 给予奖励（调用 `GameManager.add_lore()`，`GameManager.trigger_effect_logic()`），重置状态。
       - 发出 `arcane_intuition_finished` 信号。

     - `clear_turn_buffs()`: 在每回合结束时调用，清除回合Buff。

     - `clear_term_buffs()`: 在每学年结束时调用，清除学年Buff。

   - 信号

     ：

     - `arcane_intuition_started()`
     - `arcane_intuition_finished(succeeded: bool)`
     - `buff_applied(buff_data)`
     - `debuff_applied(debuff_data)`
     - `random_event_triggered(event_id, event_description)`

3. **分数计算器 (`cs/Global/ScoreCalculator.gd`)**

   - **职责**：**纯函数式单例**。只负责根据输入数据（玩家手牌、玩家能力、当前游戏状态），纯粹地**计算**最终得分，不修改任何游戏状态。

   - 方法

     ：

     ```
     class_name ScoreCalculator extends Node
     
     @onready var game_config: GameConfig = preload("res://assets/data/game_config.tres")
     
     func calculate_score(
         played_cards: Array[CardData], 
         game_manager: GameManager # 直接传入 GameManager 实例来获取所有状态和能力
     ) -> int:
         var initial_cards = played_cards.duplicate(true) # 复制一份，避免修改原数据
     
         # 1. 牌型识别与点数修正
         #   - 遍历 initial_cards，调用 card.get_modified_value(game_manager) 更新其临时点数。
         #   - 处理金色蜡封复制 (可能需要临时增加 duplicate cardData 到 played_cards 数组进行牌型识别)
         #   - 识别牌型 (扑克牌型算法)
         #   - 处理牌型转化 (双子法典, 符文大师)
         var recognized_card_type: String = GlobalEnums.CARD_TYPE_HIGH_CARD # 识别出的牌型名称
         var base_score_pre_multiply: int = 0
     
         # 2. 获取基础学识点与直接加成
         base_score_pre_multiply = game_config.card_type_base_scores[recognized_card_type]
         #   - 学年增益/限制: base_score_pre_multiply += game_manager.get_active_effect_modifier("base_score_modifier")
         #   - 紫色蜡封: 遍历 played_cards，若有紫色蜡封，base_score_pre_multiply += 20
         #   - 灵光一闪 (翻倍): 若有，base_score_pre_multiply *= 2
         #   - 贤者之石: 若有，base_score_pre_multiply += 15 (需要 GameManager 标记每回合是否第一次打牌)
         #   - 魔力灌注: 若有，base_score_pre_multiply += 20
         #   - 奥术激发: 若有，base_score_pre_multiply += 10
         #   - 秩序维护者: 若有，且牌型符合，base_score_pre_multiply += 10
         #   - 虚空吞噬者: 若有，且打出玻璃材质牌，base_score_pre_multiply += 30
     
         # 3. 应用牌型等级倍率
         var level_multiplier = game_config.card_type_level_multipliers[recognized_card_type][game_manager.card_type_levels[recognized_card_type] - 1]
         #   - 秘法爆发 (等级视为LV5): 如果有，覆盖 level_multiplier 为 LV5 的倍率
         var score_after_level = base_score_pre_multiply * level_multiplier
     
         # 4. 应用最终百分比倍率
         var cumulative_percent_bonus = 0.0
         var multiplicative_factor = 1.0
     
         #   - 累加百分比 (魔力水晶, 幸运妖精, 奥术圣物匣)
         #       - 遍历 game_manager.get_active_effects(ON_SCORE_CALCULATION)
         #       - 如果是 "PERCENT_TOTAL_XP_BONUS" 类型，累加其 value
         cumulative_percent_bonus += game_manager.get_active_effect_modifier("total_xp_percent_bonus")
     
         #   - 连乘倍率 (黄金牌框, 连锁反应者)
         #       - 黄金牌框: 遍历 played_cards，若有，multiplicative_factor *= 1.5
         #       - 连锁反应者: 若有，且条件满足，multiplicative_factor *= 1.25
     
         var score_after_percent = score_after_level * (1.0 + cumulative_percent_bonus) * multiplicative_factor
     
         # 5. 应用额外固定学识点
         var final_score = score_after_percent
         #   - 学徒笔记: 若牌型为"Pair"，final_score += 3
         #   - 符文精粹: 若打出带有石质牌框的牌，final_score += 5
         #   - 红色蜡封: 遍历 played_cards，若有红色蜡封，final_score += 10
         #   - 符文描拓板: 若有，且条件满足，final_score += 2
         #   - 丰饶之手: 若有，且条件满足，final_score += 20
         #   - 赌徒之魂: 若有，且条件满足，final_score += 50
         #   - 镜像使者: 若有，且条件满足，final_score += 15
         #   - 秘藏守卫: 若有，且条件满足，final_score += 10
         #   - 冥想法师: 注意这个是在回合结束触发，不在这里计算
     
         return round(final_score) # 四舍五入取整
     
     func calculate_perfect_score(
         player_hand_cards: Array[CardData], 
         game_manager: GameManager
     ) -> int:
         # 这是奥术直觉考验的核心算法
         # 1. 遍历 player_hand_cards 的所有 5 张牌组合 (Combinations)
         # 2. 对每个组合，模拟使用所有可能的瞬发法术组合 (Effect Combinations)
         #    - 例如，如果有 "灵光一闪" 和 "命运改写" 两种法术，需要考虑：
         #      - 不使用任何法术
         #      - 只使用 "灵光一闪"
         #      - 只使用 "命运改写" (对每张手牌尝试改写)
         #      - 同时使用 "灵光一闪" 和 "命运改写"
         # 3. 对每种组合和法术使用情况，调用 calculate_score() 来获取模拟得分。
         #    - 注意：需要传入临时的 GameManager 状态快照，或者在 calculate_score 中加入 is_perfect_score_check 标志以避免触发实际的副作用。
         # 4. 返回所有模拟得分中的最大值。
         # 这个算法会比较复杂，可能需要递归或迭代生成所有组合。
         return 0 # 示例，待实现
     ```

   - **低耦合点**：`ScoreCalculator` 接收所有必要数据作为参数，不直接访问 `GameManager` 的内部变量，只通过 `GameManager` 提供的方法获取活动效果等。

### **阶段三：UI与交互实现**

**目标**：构建新的UI场景，并使它们与管理模块进行双向交互。

1. **卡牌视图强化显示 (`cs/主场景/card/CardView.gd`)**

   - **职责**：将 `CardData` 中的 `wax_seals`, `frame_type`, `material_type` 视觉化。

   - 实现

     ：

     - 在 `CardView.tscn` 中添加 `Node2D` 或 `Control` 节点作为强化效果的容器。
     - 加载预先制作好的强化效果图片（蜡封图标、牌框纹理、材质透明度/着色器）。
     - 在 `set_card_data(data)` 方法中，根据 `data.wax_seals` 动态创建 `TextureRect` 显示蜡封，根据 `data.frame_type` 改变卡牌边框纹理，根据 `data.material_type` 应用着色器或叠加图片。

2. **手牌区域 (`cs/主场景/ui/HandDock.gd`)**

   - **职责**：管理手牌的显示和用户选择，以及打牌/弃牌/使用法术按钮的交互。

   - **字段**：`selected_cards_view: Array[CardView]`, `selected_spell_view: CardView` (如果法术也是CardView显示)。

   - 方法

     ：

     - `_on_hand_changed(current_hand: Array[CardData])`: 接收 `CardManager` 信号，动态添加/移除 `CardView` 实例。根据 `GameManager.get_current_hand_size()` 调整手牌排列。

     - **法术背包UI**：添加一个容器，显示 `GameManager.spell_inventory` 中的法术，每个法术用一个简单的UI按钮或自定义控件表示。

     - `_on_card_clicked(card_view: CardView)`: 切换选中状态，并更新UI（例如，出牌/弃牌按钮的可用性）。

     - ```
       _on_play_button_pressed()
       ```

       :

       - 获取 `selected_cards_view` 对应的 `CardData` 数组。
       - 验证选牌数量是否为5。
       - 调用 `CardManager.play_selected_cards(selected_cards_data)`。

     - ```
       _on_discard_button_pressed()
       ```

       :

       - 获取 `selected_cards_view` 对应的 `CardData` 数组。
       - 验证弃牌数量是否在 `GameConfig.max_discard_redraw_count` 范围内。
       - 调用 `CardManager.discard_selected_cards(selected_cards_data)`。

     - ```
       _on_spell_button_pressed(spell_id: String)
       ```

       :

       - 调用 `GameManager.use_active_spell(spell_id, selected_cards_data)` (如果法术需要目标牌)。
       - 更新法术按钮状态（已使用或消耗）。

   - 监听信号

     ：

     - `CardManager.hand_changed`
     - `GameManager.player_abilities_changed` (更新法术背包UI)

3. **侧边栏 (`cs/主场景/ui/Sidebar.gd`)**

   - **职责**：显示所有与玩家状态相关的UI信息。

   - 方法

     ：

     - `_on_game_state_changed(year, term, player_score, lore_points)`: 更新学年、学期、学识点、当前考核得分等。
     - `_on_player_abilities_changed(artifacts, spells, jokers)`: 更新法器槽位、法术背包容量、守护灵槽位、显示已装备法器和激活守护灵图标。
     - `_on_card_type_levels_changed(card_type_levels)`: 更新牌型等级表。
     - `_on_deck_changed(deck_size, discard_size, destroyed_size)`: 更新牌库/弃牌堆/销毁区数量。
     - `update_current_year_effects(year, term_type)`: 显示当前学年限制/增益（从 `GameManager` 获取）。

   - 监听信号

     ：

     - `GameManager.game_state_changed`, `player_abilities_changed`, `card_type_levels_changed`
     - `CardManager.deck_changed`

4. **牌库浏览器 (`cs/主场景/ui/DeckBrowserUI.tscn` / `cs/主场景/ui/DeckBrowser.gd`)**

   - **职责**：可视化玩家的牌库、弃牌堆、销毁区。

   - **实现**：一个独立的UI场景，包含多个 `ScrollContainer` 和 `GridContainer`。

   - 方法

     ：

     - ```
       open_browser()
       ```

       :

       - 从 `CardManager` 获取 `deck`, `discard_pile`, `destroyed_pile` 中的所有 `CardData` 实例。
       - 为每张牌创建 `CardView` 实例并添加到对应的 `GridContainer`。

     - `_on_deck_changed(...)`: 接收 `CardManager` 信号，如果浏览器打开，则刷新内容。

   - **监听信号**：`CardManager.deck_changed`。

5. **智慧殿堂 (`cs/主场景/ui/WisdomHallUI.tscn` / `cs/主场景/ui/WisdomHallManager.gd`)**

   - **职责**：管理商店逻辑和UI。

   - **实现**：独立的场景。

   - **`WisdomHallManager` 字段**：`current_shop_offers: Array[Dictionary]`, `offer_card_scenes: Array[PackedScene]` (预设的商品卡牌显示场景)。

   - `WisdomHallManager` 方法

     ：

     - `_ready()`: 监听 `GameManager.wisdom_hall_opened` 信号。

     - `on_wisdom_hall_opened()`: 调用 `refresh_shop_offers()`。

     - ```
       refresh_shop_offers()
       ```

       :

       - 根据稀有度概率和 `current_year` (从 `GameManager` 获取)，从预定义的法器/法术/守护灵数据中随机生成5个商品实例 (`ArtifactData`/`SpellData`/`JokerData`)。
       - 将商品数据存储在 `current_shop_offers`。
       - 更新UI显示（显示商品卡牌视图）。

     - ```
       buy_item(item_data: Resource)
       ```

       :

       - 从 `GameManager` 扣除 `lore_points`。
       - 调用 `GameManager.add_artifact()`, `add_spell()`, 或 `activate_joker()`。
       - 移除已购买的商品UI。
       - 更新UI（学识点、能力槽位）。

   - **监听信号**：`GameManager.wisdom_hall_opened`, `GameManager.lore_changed`, `GameManager.player_abilities_changed`。

6. **冬季考核UI (`cs/主场景/ui/AssessmentUI.tscn` / `cs/主场景/ui/AssessmentManager.gd`)**

   - **职责**：管理冬季考核流程和UI。

   - **实现**：可以复用大部分 `MainGame` 的研习UI布局，但有独立逻辑。

   - **`AssessmentManager` 字段**：`target_score: int`, `current_assessment_rounds: int`。

   - `AssessmentManager` 方法

     ：

     - `_ready()`: 监听 `GameManager.assessment_started` 信号。

     - `on_assessment_started(year_num)`: 获取 `GameConfig.victory_scores[year_num]` 作为 `target_score`，初始化考核回合数。更新UI。

     - ```
       on_turn_ended_in_assessment()
       ```

       : (监听

        

       ```
       MainGame
       ```

        

       发出的回合结束信号)

       - 累积 `GameManager.player_score` 到 `current_assessment_score`。
       - 减少 `current_assessment_rounds`。
       - 更新UI (`assessment_score_updated` 信号)。
       - 判断是否达到 `target_score` 或回合数用尽。
       - 如果未达标，调用 `GameManager.game_lost()`。
       - 如果达标，调用 `GameManager.game_won()`。

   - **监听信号**：`GameManager.assessment_started`, `GameManager.game_state_changed`。

7. **学期奖励弹窗 (`cs/主场景/ui/TermRewardUI.tscn` / `cs/主场景/ui/TermRewardManager.gd`)**

   - **职责**：显示学期结束奖励。

   - **实现**：独立的弹窗场景。

   - `TermRewardManager` 方法

     ：

     - `_ready()`: 监听 `GameManager.term_ended` 信号。
     - `on_term_ended()`: 获取 `GameConfig.term_rewards[current_term]`。
     - 根据奖励类型，调用 `GameManager.add_lore()`, `CardManager.add_card_to_deck()` 等。
     - 显示奖励UI，等待玩家点击确认。
     - 确认后，发出 `rewards_claimed` 信号 (通知 `MainGame` 切换到智慧殿堂)。

   - **信号**：`rewards_claimed()`。

8. **事件弹窗 (`cs/主场景/ui/EventPopup.tscn` / `cs/主场景/ui/EventManager.gd` 辅助方法)**

   - **职责**：通用事件显示弹窗，包括奥术直觉考验提示、临时Debuff等。

   - **实现**：简单的弹窗场景，包含文本框和确认按钮。

   - `EventManager` 辅助方法

     ：

     - `show_event_popup(title: String, description: String, on_confirm: Callable = null)`: 加载弹窗场景，显示文本，连接确认按钮到 `on_confirm` 回调。

### **阶段四：流程整合与测试**

**目标**：将所有模块连接起来，确保游戏流程顺畅，并进行初步功能测试。

1. **`MainGame.gd` (主协调者)**

   - **职责**：现在 `MainGame` 变得非常薄，主要负责场景切换和信号监听/转发。

   - 方法

     ：

     - `_ready()`: 连接所有单例信号。

     - `_start_game()`: 调用 `GameManager.initialize_game_state()`，然后 `GameManager.start_new_year(1)`。

     - 连接 `GameManager` 的各种信号

        

       (

       ```
       new_year_started
       ```

       ,

        

       ```
       term_started
       ```

       ,

        

       ```
       term_ended
       ```

       ,

        

       ```
       wisdom_hall_opened
       ```

       ,

        

       ```
       assessment_started
       ```

       ,

        

       ```
       game_won
       ```

       ,

        

       ```
       game_lost
       ```

       ) 来：

       - 加载/卸载对应的UI场景。
       - 调用子模块的初始化/更新方法。

     - **连接 `TermRewardUI.rewards_claimed` 信号**，在奖励领取后调用 `GameManager.start_wisdom_hall()`。

     - **连接 `EventManager` 的事件信号** (`random_event_triggered`, `arcane_intuition_started`, `arcane_intuition_finished`)，弹出对应的 `EventPopup`。

     - **信号转发**：将 `HandDock` 的 `play_button_pressed` 和 `discard_button_pressed` 信号转发给 `CardManager` (或直接连接 `HandDock` 到 `CardManager`，减少 `MainGame` 的中转负担)。

2. **信号连接概览 (示例)**

   - ```
     GameManager.gd
     ```

      

     Emits:

      

     ```
     game_state_changed
     ```

     ,

      

     ```
     player_abilities_changed
     ```

     ,

      

     ```
     card_type_levels_changed
     ```

     ,

      

     ```
     new_year_started
     ```

     ,

      

     ```
     term_started
     ```

     ,

      

     ```
     term_ended
     ```

     ,

      

     ```
     wisdom_hall_opened
     ```

     ,

      

     ```
     assessment_started
     ```

     ,

      

     ```
     game_won
     ```

     ,

      

     ```
     game_lost
     ```

     ,

      

     ```
     lore_changed
     ```

     ,

      

     ```
     spell_used
     ```

     - Listened by: `MainGame`, `Sidebar`, `WisdomHallManager`, `AssessmentManager`

   - ```
     CardManager.gd
     ```

      

     Emits:

      

     ```
     hand_changed
     ```

     ,

      

     ```
     deck_changed
     ```

     ,

      

     ```
     cards_played
     ```

     - Listened by: `HandDock`, `Sidebar`, `DeckBrowserUI`

   - ```
     HandDock.gd
     ```

      

     Emits:

      

     ```
     play_button_pressed
     ```

     ,

      

     ```
     discard_button_pressed
     ```

     ,

      

     ```
     spell_button_pressed
     ```

     - Listened by: `CardManager` (for play/discard), `GameManager` (for spells)

   - ```
     EventManager.gd
     ```

      

     Emits:

      

     ```
     arcane_intuition_started
     ```

     ,

      

     ```
     arcane_intuition_finished
     ```

     ,

      

     ```
     buff_applied
     ```

     ,

      

     ```
     debuff_applied
     ```

     ,

      

     ```
     random_event_triggered
     ```

     - Listened by: `MainGame` (for UI popups), `Sidebar` (for buff/debuff icons)

   - ```
     TermRewardManager.gd
     ```

      

     Emits:

      

     ```
     rewards_claimed
     ```

     - Listened by: `MainGame`

### **阶段五：平衡与优化**

**目标**：通过大量测试，调整数值，确保游戏乐趣和挑战性。

1. 数值调整

   ：

   - `GameConfig.gd` 中的所有数值都需要反复测试。这包括冬季考核的目标分数、学年限制、基础学识点、牌型倍率、商品价格、学期奖励、Buff/Debuff 效果等。
   - 特别注意**牌型等级倍率**和**冬季考核目标**的匹配。

2. 性能优化

   ：

   - `ScoreCalculator.calculate_perfect_score()`：这是最可能成为瓶颈的地方。初始可以先实现一个简化版本（例如，不考虑法术组合，只考虑牌型），再逐步优化。可能需要优化扑克牌型识别算法。
   - UI动态更新：尤其是在 `HandDock` 和 `DeckBrowserUI` 中，避免在每帧都进行昂贵的计算或节点创建/销毁。

3. 用户体验 (UX)

   ：

   - **实时反馈**：在 `HandDock` 中，玩家选择牌时，应实时显示**预估得分**。这需要 `HandDock` 调用 `ScoreCalculator.calculate_score()` 的简化版本。
   - **清晰的信息**：所有Buff/Debuff、法器/守护灵的激活状态、牌型等级等，都应有清晰的UI展示（例如，侧边栏上的小图标和悬停提示）。
   - **动画与音效**：为打牌、抽牌、获得学识点、能力触发等设计丰富动画和音效，增强游戏沉浸感。

4. 调试工具

   ：开发期间，建立一套调试工具，例如：

   - 显示当前所有游戏状态变量的UI。
   - 能够手动添加/移除法器、法术、守护灵。
   - 能够手动调整学识点或牌型等级。
   - 能够手动触发随机事件。

------

通过以上详细的模块拆解和实现思路，您将在Godot中一步步地构建这个复杂的卡牌游戏。核心思想是：**数据定义在前，逻辑实现随后，UI响应数据变化，单例协调全局流程。** 祝您开发顺利，能够构建出这个充满潜力的项目！