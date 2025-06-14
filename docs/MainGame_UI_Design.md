# 智牌奇旅 - 主界面UI设计文档

## 基本信息

- **场景名称**: MainGame
- **分辨率**: 1920 x 1080
- **主题风格**: 魔法学术风格，深蓝色系

## 整体布局

游戏界面分为以下主要区域：

1. **左侧边栏** - 包含游戏信息和资源显示
2. **顶部区域** - 包含法器和魔法发现面板
3. **底部区域** - 玩家手牌区域
4. **右下角** - 符文库
5. **中央区域** - 游戏主要交互区域

## 样式定义

### 主要面板样式

```gdscript
bg_color = Color(0.0705882, 0.0862745, 0.207843, 0.741176)
border_width = 2
border_color = Color(0.356863, 0.454902, 0.901961, 0.737255)
corner_radius = 8
shadow_color = Color(0, 0, 0, 0.239216)
shadow_size = 3
```

### 按钮样式

1. **金色按钮** (主要操作)
```gdscript
bg_color = Color(0.25, 0.18, 0.07, 0.85)
border_color = Color(0.8, 0.65, 0.2, 0.6)
corner_radius = 10
font_color = Color(1, 0.87, 0.55, 1)
```

2. **蓝色按钮** (次要操作)
```gdscript
bg_color = Color(0.121569, 0.156863, 0.301961, 1)
border_color = Color(0.34902, 0.439216, 0.8, 0.6)
corner_radius = 6
font_color = Color(0.866667, 0.933333, 1, 1)
```

3. **浅色按钮** (辅助操作)
```gdscript
bg_color = Color(0.18, 0.22, 0.28, 0.9)
border_color = Color(0.65, 0.75, 0.85, 0.7)
corner_radius = 10
font_color = Color(0.9, 0.95, 1, 1)
```

## 详细区域说明

### 1. 背景

- **类型**: TextureRect
- **位置**: (0, 0)
- **大小**: 1920 x 1080
- **纹理**: "res://assets/images/background/image_fx_看图王.png"
- **拉伸模式**: 6 (保持宽高比)

### 2. 左侧边栏 (SidePanel)

- **位置**: (40, 15)
- **大小**: 285 x 1029
- **样式**: 深蓝色背景，右侧边框，圆角
```gdscript
bg_color = Color(0.0470588, 0.0627451, 0.137255, 0.862745)
border_width_right = 1
border_color = Color(0.356863, 0.454902, 0.901961, 0.498039)
corner_radius_top_right = 12
corner_radius_bottom_right = 12
```

#### 2.1 设置按钮

- **位置**: 顶部
- **大小**: 高度50
- **文本**: "✧ 设置选项 ✧"
- **字体大小**: 24
- **装饰**: 左右两侧各有一个齿轮图标(⚙)

#### 2.2 标题面板

- **高度**: 50
- **文本**: "智牌奇旅"
- **字体大小**: 28
- **颜色**: 浅蓝色 (0.866667, 0.933333, 1, 1)
- **阴影**: 黑色阴影，偏移(2, 2)

#### 2.3 魔力面板

- **高度**: 110
- **标题**: "学识魔力"
- **字体大小**: 18 (标题), 48 (数值)
- **数值颜色**: 白色带蓝色阴影
- **数值**: "0" (初始值)

#### 2.4 目标面板

- **高度**: 120
- **标题**: "学术试炼"
- **字体大小**: 23
- **内容**:
  - 目标分数: "300分"
  - 奖励: "10学识点"
- **颜色**: 目标值为金色，奖励值为绿色

#### 2.5 资源面板

- **高度**: 180
- **标题**: "魔法资源"
- **字体大小**: 28
- **内容**:
  - 集中力: "5"
  - 精华: "3"
  - 学识点: "4"
- **布局**: 使用网格布局，左侧标签右侧数值

#### 2.6 分数面板

- **高度**: 160
- **标题**: "奥术收益"
- **内容**:
  - 基础分数: "50" (红色面板)
  - 倍数: "x1" (蓝色面板)
- **布局**: 两个子面板水平排列

#### 2.7 进度面板

- **高度**: 200
- **标题**: "✧ 学术进度 ✧"
- **内容**:
  - 学年: "第1学年"
  - 学期: "1/4"
- **装饰**: 四角有装饰性符号，标题下方有点状分隔线

### 3. 符文库面板 (RuneLibraryPanel)

- **位置**: (1658, 692)
- **大小**: 220 x 340
- **标题**: "符文库"
- **内容**:
  - 卡牌背面图像 (120 x 180)
  - 计数器: "52 / 52"

### 4. 手牌区域 (HandArea)

- **位置**: 底部中央，(水平居中, 底部-420)
- **大小**: 1200 x 390
- **边框样式**:
```gdscript
bg_color = Color(0.0705882, 0.0862745, 0.207843, 0.741176)
border_width = 3
border_color = Color(0.356863, 0.568627, 0.901961, 0.737255)
corner_radius = 12
```

#### 4.1 手牌标题

- **文本**: "✦ 符文掌控台 ✦"
- **字体大小**: 30
- **位置**: 顶部居中

#### 4.2 卡牌容器

- **位置**: 面板内部，留有边距
- **布局**: 水平排列，间距35
- **装饰**: 面板内有装饰性符号 "⚝" 和 "✧"

#### 4.3 按钮面板

- **位置**: 底部
- **高度**: 70
- **内容**:
  - 吟唱咒语按钮 (金色): "✦ 吟唱咒语 ✦"
  - 排序按钮 (蓝色): "✧ 按能量排序 ✧" 和 "✧ 按元素排序 ✧"
  - 使用精华按钮 (浅色): "✧ 使用精华 ✧"
- **布局**: 三个部分水平排列，中间部分包含两个排序按钮

### 5. 法器面板 (ArtifactPanel)

- **位置**: (500, 15)
- **大小**: 920 x 250
- **标题**: "传奇法器"
- **计数**: "0 / 6"
- **内容容器**: 水平排列，间距30

### 6. 魔法发现面板 (MagicDiscoveryPanel)

- **位置**: (1440, 15)
- **大小**: 450 x 245
- **标题**: "魔法发现"
- **计数**: "0 / 3"
- **内容容器**: 水平排列，间距15

### 7. 中央区域指示器 (CenterAreaIndicator)

- **位置**: 屏幕中央
- **大小**: 160 x 240
- **内容**: 大型装饰符号 "✦"
- **颜色**: 半透明蓝色 (0.356863, 0.454902, 0.901961, 0.06)
- **字体大小**: 200

## 字体和颜色方案

### 主要颜色

- **背景蓝**: Color(0.0705882, 0.0862745, 0.207843, 0.741176)
- **边框蓝**: Color(0.356863, 0.454902, 0.901961, 0.737255)
- **标题蓝**: Color(0.631373, 0.807843, 0.968627, 1)
- **文本蓝**: Color(0.866667, 0.933333, 1, 1)
- **强调金**: Color(1, 0.858824, 0.411765, 1)
- **奖励绿**: Color(0.4, 0.85, 0.4, 1)

### 字体大小

- **大标题**: 28-30
- **中标题**: 24-26
- **小标题**: 20-22
- **正文**: 16-18
- **强调数值**: 30-48

## 装饰元素

界面使用了多种符号作为装饰元素，增强魔法学术的主题氛围：
- **✧** - 星形装饰，用于标题和按钮
- **⚙** - 齿轮图标，用于设置按钮
- **⚜** - 百合花纹，用于手牌区域顶部
- **⚝** - 星形装饰，用于手牌区域
- **•** - 点状装饰，用于分隔线

## 交互连接

场景中定义了以下信号连接：
1. 设置按钮 → `_on_settings_button_pressed()`
2. 吟唱咒语按钮 → `_on_play_button_pressed()`
3. 按能量排序按钮 → `sort_cards_by_value()`
4. 按元素排序按钮 → `sort_cards_by_suit()`
5. 使用精华按钮 → `_on_discard_button_pressed()`

---

## 进一步完善内容

### 8. Godot 节点树结构

```text
MainGame (Control)
├── Background                 (TextureRect)
├── SidePanel                  (VBoxContainer)
│   ├── SettingsButton         (Button)
│   ├── TitleLabel             (Label)
│   ├── ManaPanel              (VBoxContainer)
│   ├── TargetPanel            (VBoxContainer)
│   ├── ResourcePanel          (GridContainer)
│   ├── ScorePanel             (HBoxContainer)
│   └── ProgressPanel          (VBoxContainer)
├── ArtifactPanel              (Control)
├── MagicDiscoveryPanel        (Control)
├── HandArea                   (Control)
│   ├── HandTitle              (Label)
│   ├── CardContainer          (HBoxContainer)
│   └── BottomButtons          (HBoxContainer)
├── RuneLibraryPanel           (Control)
└── CenterAreaIndicator        (Label)
```

> 提示：保持节点命名与脚本中的变量名一致，方便通过 `$` 快捷访问。

### 9. Anchor 与 Margin 设置（响应式）

| 节点                  | Anchor (L,T,R,B) | Margin 说明 |
|-----------------------|------------------|-------------|
| `Background`          | 0,0,1,1          | 全填充 |
| `SidePanel`           | 0,0,0,1          | 左固定宽 285px，顶部/底部 15px 间距 |
| `ArtifactPanel`       | 0.26,0.0,0.74,0  | 顶部距 15px，居中宽 920px，固定高 250px |
| `MagicDiscoveryPanel` | 0.75,0.0,1,0     | 顶部距 15px，右侧固定宽 450px，高 245px |
| `HandArea`            | 0.21,1,0.79,1    | 底部向上 420px，高 390px，水平居中 |
| `RuneLibraryPanel`    | 1,0.64,1,0.95    | 右侧固定宽 220px，底部距 48px，高 340px |

> 使用归一化 Anchor 保证在 16:9 不同分辨率下仍保持布局比例。

### 10. Theme 资源

统一使用 `res://theme/main_game_theme.tres` 作为主题资源，在 Theme 中：
1. 创建 `StyleBoxFlat` 用于主要面板，引用前文的颜色与圆角。
2. 创建 `Button` 3 种变体：`PrimaryButton`、`SecondaryButton`、`TertiaryButton`，分别对应金色、蓝色、浅色按钮。
3. 设置 `Label` 默认字体为 `res://assets/fonts/SourceHanSerifCN-SemiBold.otf`，字号 18。

在场景脚本中：
```gdscript
@onready var theme := preload("res://theme/main_game_theme.tres")
func _ready():
    self.theme = theme
```

### 11. 动画与音效

| 交互          | 动画描述 | Tween/SpriteFrames | 音效 |
|---------------|----------|--------------------|-------|
| 按钮 Hover    | Scale 1→1.05 (0.12s 缓出) | Tween  | `res://assets/sfx/ui_hover.wav` |
| 按钮 Press    | Scale 1.05→0.97→1 (0.18s 弹性) | Tween | `res://assets/sfx/ui_click.wav` |
| 资源变化闪光  | Alpha 0→1→0 (0.5s) | AnimationPlayer | `res://assets/sfx/pickup.wav` |

> 所有动画统一放置在同级 `AnimationPlayer`，并通过 `play()` 调用，避免在脚本中硬编码时间线。

### 12. 资源列表

| 资源 | 路径 |
|------|------|
| 背景图 | `res://assets/images/background/image_fx_看图王.png` |
| 卡牌背面 | `res://assets/images/cards/back_green.png` |
| UI 图标 | `res://assets/images/ui/*.png` |
| SFX | `res://assets/sfx/*.wav` |
| 主字体 | `res://assets/fonts/SourceHanSerifCN-SemiBold.otf` |

### 13. 脚本及信号约定

```gdscript
# signal 定义示例 (位于 UIManager.gd)
signal settings_requested
signal play_requested
signal sort_by_value_requested
signal sort_by_suit_requested
signal essence_requested

# 连接方法
SettingsButton.pressed.connect(-> emit_signal("settings_requested"))
```

> 通过信号向游戏逻辑层解耦发送请求，遵循高内聚低耦合原则。

### 14. 版本控制与命名规范

- 所有 UI 相关脚本统一放置于 `res://ui/`。
- 主题、图集、字体放置于 `res://theme/`、`res://assets/fonts/`。
- 文件、小写下划线；类、PascalCase；信号、snake_case。

---

至此，主界面 UI 设计文档已补充完毕，提供了完整的节点结构、主题资源、动画音效与响应式布局细节，可直接据此在 Godot 4.4 中实现。

---

## 15. 逐控件属性表（像素级）

| Node 路径 | 类型 | Anchor | Margin(L,T,R,B) | Size(px) | 额外属性 |
|-----------|------|--------|-----------------|----------|-----------|
| `SidePanel` | `VBoxContainer` | 0,0,0,1 | 40,15,40+285,15 | 285×1050 | `theme_type_variation: SidePanelStyle` |
| `SidePanel/SettingsButton` | `Button` | 0,0,1,0 | 0,0,0,0 | H50 | `text:"✧ 设置选项 ✧", theme_type_variation: SecondaryButton` |
| `SidePanel/TitleLabel` | `Label` | 0,0,1,0 | 0,60,0,0 | H50 | `text:"智牌奇旅", font_size:28, align:center` |
| `SidePanel/ManaPanel` | `VBoxContainer` | 0,0,1,0 | 0,120,0,0 | H110 | `panel_title:"学识魔力"` |
| `SidePanel/TargetPanel` | `VBoxContainer` | 0,0,1,0 | 0,240,0,0 | H120 | `panel_title:"学术试炼"` |
| `SidePanel/ResourcePanel` | `GridContainer` | 0,0,1,0 | 0,370,0,0 | H180 | `columns:2` |
| `SidePanel/ScorePanel` | `HBoxContainer` | 0,0,1,0 | 0,560,0,0 | H160 | `spacing:20` |
| `SidePanel/ProgressPanel` | `VBoxContainer` | 0,0,1,0 | 0,730,0,0 | H200 | `panel_title:"✧ 学术进度 ✧"` |
| `ArtifactPanel` | `Control` | 0.26,0,0.74,0 | 0,15,0,0 | 920×250 | `panel_title:"传奇法器"` |
| `MagicDiscoveryPanel` | `Control` | 0.75,0,1,0 | 0,15,15,0 | 450×245 | `panel_title:"魔法发现"` |
| `HandArea` | `Control` | 0.21,1,0.79,1 | 0,-420,0,-30 | 1200×390 | `panel_title:"✦ 符文掌控台 ✦"` |
| `HandArea/BottomButtons/PlayButton` | `Button` | 0,0,0,0 | 0,0,0,0 | 300×70 | `theme: PrimaryButton` |
| `HandArea/BottomButtons/SortButtons/SortValueButton` | `Button` | 0,0,0,0 | 0,0,0,0 | 220×70 | `theme: SecondaryButton` |
| `HandArea/BottomButtons/SortButtons/SortSuitButton` | `Button` | 0,0,0,0 | 240,0,0,0 | 220×70 | `theme: SecondaryButton` |
| `HandArea/BottomButtons/EssenceButton` | `Button` | 1,0,1,0 | -300,0,0,0 | 300×70 | `theme: TertiaryButton` |
| `RuneLibraryPanel` | `Control` | 1,0.64,1,0.95 | -260,0,0,-48 | 220×340 | `panel_title:"符文库"` |
| `CenterAreaIndicator` | `Label` | 0.5,0.5,0.5,0.5 | -80,-120,80,120 | 160×240 | `text:"✦", font_size:200, modulate:淡蓝` |

> 上表中的 Margin 数值遵循 Godot 左、上、右、下顺序，负值表示相对父节点底/右。

### 16. Theme 资源示例（main_game_theme.tres）

```tres
[gd_resource type="Theme" format=3]

[resource]

# StyleBoxFlat: 主面板
stylebox/SidePanelStyle = SubResource( 1 )
# StyleBoxFlat: 主要按钮（金色）
stylebox/PrimaryButton = SubResource( 2 )
# StyleBoxFlat: 次要按钮（蓝色）
stylebox/SecondaryButton = SubResource( 3 )
# StyleBoxFlat: 辅助按钮（浅色）
stylebox/TertiaryButton = SubResource( 4 )

# Font Assets
font/default_font = ExtResource( 1 )

[sub_resource type="StyleBoxFlat" id=1]
bg_color = Color(0.0470588, 0.0627451, 0.137255, 0.862745)
border_width_right = 1
border_color = Color(0.356863, 0.454902, 0.901961, 0.498039)
corner_radius_top_right = 12
corner_radius_bottom_right = 12

[sub_resource type="StyleBoxFlat" id=2]
bg_color = Color(0.25, 0.18, 0.07, 0.85)
border_color = Color(0.8, 0.65, 0.2, 0.6)
corner_radius_all = 10

[sub_resource type="StyleBoxFlat" id=3]
bg_color = Color(0.121569, 0.156863, 0.301961, 1)
border_color = Color(0.34902, 0.439216, 0.8, 0.6)
corner_radius_all = 6

[sub_resource type="StyleBoxFlat" id=4]
bg_color = Color(0.18, 0.22, 0.28, 0.9)
border_color = Color(0.65, 0.75, 0.85, 0.7)
corner_radius_all = 10

[ext_resource type="FontFile" path="res://assets/fonts/SourceHanSerifCN-SemiBold.otf" id=1]
```

> 其余字体大小、字体颜色、Icon 可在 Theme 中继续细分 `constant`, `color`, `font_size` 属性。

### 17. 示例脚本片段 (UIManager.gd)

```gdscript
@export var play_button: Button
@export var sort_value_button: Button
@export var sort_suit_button: Button
@export var essence_button: Button

func _ready():
    play_button.pressed.connect(_on_play_button_pressed)
    sort_value_button.pressed.connect(sort_cards_by_value)
    sort_suit_button.pressed.connect(sort_cards_by_suit)
    essence_button.pressed.connect(_on_discard_button_pressed)

func _on_play_button_pressed():
    emit_signal("play_requested")
```

---

以上补充提供了像素级控件表与 Theme 资源文件示例，实现真正一比一复刻。如需再细化（例如每个 Label 的 `custom_minimum_size`、行高`line_spacing`等），请输入指示！ 