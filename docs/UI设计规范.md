# 主场景 UI 设计规范

> 版本：v1.0 最后更新：2025-06-14
> 
> 适用 Godot 4.4

---

## 目录
1. 设计目标与原则  
2. 分辨率与自适应  
3. 资源与命名  
4. 节点树 & 布局  
5. 样式指南（配色 / 字体 / StyleBox）  
6. 组件规范  
7. 动画与交互  
8. 折叠侧栏实现  
9. 手牌弧形 Dock 实现  
10. Shader & 特效  
11. 主题扩展  
12. 参考 Mock-up

---

## 1. 设计目标与原则
| # | 原则 | 说明 |
| - | ---- | ---- |
| 1 | 信息层级清晰 | 背景 < 面板 < 卡牌/按钮 < 浮动提示/特效 |
| 2 | 响应式布局 | 支持 1280×720 ‑ 2560×1440，无需滚动 |
| 3 | 像素艺术融合 | 保留像素背景 & 符文卡图，UI 元素使用干净扁平化风格，避免干扰像素观感 |
| 4 | 低耦合 | 每个主要区域独立场景，可复用、可替换 |
| 5 | 可主题化 | 色板和 StyleBox 存于 `theme/`，支持切换 |

---

## 2. 分辨率与自适应
- 参考设计：1920×1080（16:9）。
- 根节点 `MainGame.tscn` 使用 `Control`，`Anchor = FullRect`。
- **自适应规则**
  1. `SidebarLeft`、`TopDock`、`HandDock` 固定像素高/宽；通过 `SizeFlagsStretchRatio` 在窄屏压缩到 85% 最大值。  
  2. 其余面板 Anchor 采用百分比，`MinSize` 限制过小尺寸。  
  3. 字体随 UI 缩放：读取 `ProjectSettings.display/window/size/viewport_width` 计算比例，写入 `Theme.default_font_size`。

---

## 3. 资源与命名
| 资源 | 路径示例 | 说明 |
| ---- | -------- | ---- |
| BG 图 | `res://assets/background/joker_bg.png` | 1920×1080 像素艺术 |
| 卡背 | `res://assets/cards/back.png` | 96×128 |
| UI 纹理 | `res://assets/ui/crystal_tile.png` | 面板贴图 64×64 可平铺 |
| Icon | `res://assets/icons/setting.svg` | 按钮图标统一尺寸 32×32 |
| Theme | `res://theme/night_theme.tres` | 见 §11 |

---

## 4. 节点树 & 布局
```
MainGame (Control)
├─ BG (TextureRect)  # Joker 背景，Depth -10
├─ EffectLayer (CanvasLayer)  # 所有特效 & toast
├─ SidebarLeft (Panel / VBoxContainer) 200px
│  ├─ SectionList (VBox) -> SectionScene.tscn 实例 5 次
│  └─ CollapseBtn (TextureButton)
├─ TopDock (Panel / HBoxContainer) 96px
│  ├─ Spacer (Control, expand)
│  ├─ RuneSlotBar (HBox) x6 SlotScene
│  ├─ DiscoveryBar (VBox) x3 SlotScene
│  └─ SettingBtn (TextureButton)
├─ RuneConsole (PanelContainer)  # 中央操作台
│  └─ GlyphGrid (GridContainer) 6×4
├─ HandDock (NinePatchRect) 160px  底部
│  ├─ EndTurnBtn (Button)
│  ├─ HandContainer (HBox) -> 动态卡牌
│  ├─ DiscardBtn (Button)
│  └─ JokerBtn (Button)
└─ DeckWidget (VBoxContainer)  # 右下角
   ├─ DeckTexture (TextureRect)
   └─ DeckLabel (Label)
```

> 所有子区域（SidebarLeft、TopDock、RuneConsole、HandDock、DeckWidget）各自保存为 .tscn，可独立复用。

### Anchor / Offset
| 节点 | Anchor A | Anchor B | Offset / Size |
| ---- | -------- | -------- | ------------- |
| SidebarLeft | (0,0) | (0,1) | W=200, Left=0 |
| TopDock | (0,0) | (1,0) | H=96, Top=0 |
| RuneConsole | (0.10,0.55) | (0.90,0.73) | 自动 |
| HandDock | (0,0.85) | (1,1) | H=160 |
| DeckWidget | (0.92,0.55) | (1,1) | Auto |

---

## 5. 样式指南
### 5.1 配色
| 名称 | Hex | 用途 |
| ---- | ---- | ---- |
| Primary | #5ec8fa | 主按钮、强调描边 |
| Accent  | #ffbf69 | 次级按钮、卡牌费用高亮 |
| Danger  | #f25f5c | 负面提示、删除 |
| BGDeep | #0d1a2d | 背景深蓝 |
| PanelBG | #162033 | 面板色 |

### 5.2 字体
- Noto Sans SC Regular / SemiBold / Bold。  
- JetBrains Mono Bold 用于数值。  
- 通过 Theme 设置：`DefaultFont` 家族 = Noto Sans SC，大小随缩放。

### 5.3 StyleBox
```
StyleBoxFlat
  bg_color: PanelBG
  border_width_all: 2
  border_color: #7e7bff
  corner_radius: 4
```
按钮：派生 StyleBox，Hover `bg_color` 亮度 +10%，Press 亮度 ‑10%。

---

## 6. 组件规范
### 6.1 PanelSection.tscn (Sidebar)
```
PanelSection (PanelContainer)
├─ Title (Label)
└─ ContentVBox (VBox)
```
- `Title.theme_override_font_sizes/font_size = 16` **SemiBold**。  
- Content 行用 `HBox`：Icon + ValueLabel。

### 6.2 RuneSlot.tscn
- 基类 `TextureButton` 96×128，空槽灰度贴图。  
- Signals：`slot_clicked(slot)`。

### 6.3 CardView.tscn
```
CardRoot (TextureButton)
├─ CostLabel (Label, top-left)
├─ RuneIcon (TextureRect, center)
└─ NameLabel (Label, bottom)
```
- `drag_type = preview`，自定义 `get_drag_data()` 返回缩放后纹理。  
- Hover → `scale=1.05` & DropShadow。

### 6.4 弧形 HandDock
- NinePatchRect 背景材质：弧形 PNG（256×128）切片 (Left/Right/Top=64, Bottom=32)。
- `HandContainer` `SizeFlagsHorizontal = Expand`，`Alignment = Center`。

---

## 7. 动画与交互
| 动作 | 时长 | 曲线 | 节点 | 说明 |
| ---- | ---- | ---- | ---- | ---- |
| 按钮 Hover | 0.08 s | QuadOut | `*Btn` | scale 1→1.05 |
| 按钮 Press | 0.1 s | QuadIn | `*Btn` | scale 1.05→0.95→1 |
| 卡牌 Hover | 0.1 s | CubicOut | CardView | scale 1→1.05 |
| 卡牌拖拽 | - | - | CardView | 显示透明拖影、Line2D 轨迹 |
| Sidebar 折叠 | 0.2 s | Cubic | SidebarLeft | pos.x 0→-200 |
| HUD Shake | 0.3 s | Random | HandDock | 回合结束时偏移 ±2 px |

---

## 8. 折叠侧栏实现
```gdscript
@onready var tween := create_tween()
@export var collapsed_x := -200
var _collapsed := false

func toggle_collapse():
    _collapsed = !_collapsed
    var target_x = 0 if !_collapsed else collapsed_x
    tween.kill() # restart
    tween = create_tween().tween_property(self, "position:x", target_x, 0.2)
```
`CollapseBtn` 按下 → `SidebarLeft.toggle_collapse()`。

---

## 9. 手牌弧形 Dock 实现
- 预绘制弧形背景（半径 700 px），NinePatch 切片。  
- `HandContainer` `RotationDegrees` 根据索引轻微旋转：`-10° → 10°`。  
- 使用 `Tween` 在抽牌时从底部弹入（Y +50 → 0）。

---

## 10. Shader & 特效
- **高斯模糊背景**：`BG.material` 使用 `screen_texture` + kernel blur。  
- **漂字分数**：`EffectLayer` 动态实例化 `Label`, Tween Alpha & Y。  
- **Card Glow**：`CardRoot.material` Simple Shader：`if hover {EMISSION = Color(Primary,0.6)}`。

---

## 11. 主题扩展
```
res://theme/
  night_theme.tres   # 默认深蓝
  neon_theme.tres    # 霓虹桃红 + 青绿
  parchment_theme.tres # 古纸黄 + 深棕
```
切换：写 `Settings` 保存到 JSON，然后在 `_ready()` 根据文件加载对应 Theme 到 `get_tree().set_theme()`。

---

## 12. 参考 Mock-up
> Figma 链接（示意）：<https://www.figma.com/file/XXXXX/CardGameUI>

如需源文件或进一步标注（像素坐标/切片图），请联系设计师或在此文档继续补充。
