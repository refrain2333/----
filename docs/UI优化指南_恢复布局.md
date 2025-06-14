# UI 优化与布局恢复指南 (基于 Godot 4.4)

> 目标：确保经过 **UI 拆分重构** 后的各子场景 (`cs/主场景/ui/*.tscn`) 的布局、尺寸、样式与 `MainGame_backup.tscn` 完全一致，同时保持高内聚、低耦合的模块化结构，方便后续主题切换与多分辨率适配。

---

## 1. 全局设置

1. **分辨率基准**：`1920 × 1080` (16:9)。在 `Project ‣ Project Settings ‣ Display ‣ Window` 中：
   - Size/Width = **1920** ，Height = **1080**
   - Stretch/Mode = **"viewport"**，Aspect = **"keep"**

2. **顶层 UI 容器**：`UIContainer` (Control)
   - Anchors：`Full Rect (Preset 15)`
   - Offsets：全部 `0`
   - Layout Mode：`Anchors + Offsets` (保持默认)

3. **主题资源统一**：
   - 在 `res://themes/` 创建 `default_ui_theme.tres`，将 `MainGame_backup.tscn` 中的所有 `StyleBoxFlat_*` 子资源迁移进去。
   - 所有子场景通过 **Project Theme** 继承共享基础样式，只在需要的节点做 `theme_override_styles/*`。

---

## 2. 子场景详细布局

下面列出了每个 UI 子场景根节点 (Root) 的 **锚点 (Anchor)**、**偏移 (Offset)** 和 **最小尺寸** 设置；以及与旧场景中对应节点的路径，方便在 Godot Inspector 中一一对照。

| 子场景 | 旧节点路径 (MainGame_backup) | Root 类型 | Anchors (L,T,R,B) | Offsets (L,T,R,B) | 说明 |
| ------ | --------------------------- | --------- | ----------------- | ----------------- | ---- |
| `Sidebar.tscn` | `UIContainer/SidePanel` | `Panel` | `0, 0, 0, 0` | **40, 15, -1595, -36** | 固定左侧宽 **285 px**，距顶 15，距底 36 |
| `Hud.tscn` | `UIContainer/HudPanel` | `Panel` | `0.5, 1, 0.5, 1` | `-145, -138, 145, -15` | 底部中央浮动，宽 290，高 123 |
| `HandDock.tscn` | `UIContainer/HandArea/HandPanel` | `Panel` | `0, 1, 1, 1` | `40, -285, -40, -15` | 底部横向，左右各留 40，距底 15，高 270 |
| `DeckWidget.tscn` | `UIContainer/TableArea/DeckWidget` | `Panel` | `1, 0.5, 1, 0.5` | `-240, -240, -40, -60` | 右中，保持正方形 200×200 |
| `TopDock.tscn` | `UIContainer/TopDock` | `Panel` | `0.5, 0, 0.5, 0` | `-360, 15, 360, 135` | 顶部中央，宽 720，高 120 |

> 备注：如果旧场景中的某些 Panel 命名不一致，可通过坐标及功能对应关系确认。

### 2.1 设置步骤
以 `Sidebar.tscn` 为例：
1. 选中根节点 `Sidebar` → `Layout ‣ Presets ‣ Custom` → 将 **Anchor** `Left/Top/Right/Bottom` 分别设为 `0/0/0/0`。
2. 在 **Offset** 中输入 `40, 15, -1595, -36` (右、下为负数)。
3. 将 `theme_override_styles/panel` 指向 `default_ui_theme.tres/StyleBoxFlat_sidebar`。其余子节点全部保持原层级 & 排版。
4. 运行场景，检查与旧版位置、尺寸是否一致。

其余子场景重复以上流程，只是数值不同 (见表格)。

### 2.2 主要组件 Anchor / Offset 对照表

> 以下表格列出常用交互/信息组件的精确布局数据，数字均来源于 `MainGame_backup.tscn`，按场景分组。若未列出，可参照 Godot **Inspector → Rect → Anchors / Offsets** 手动比对。

#### Sidebar.tscn
| 组件路径 | Anchors (L,T,R,B) | Offsets (L,T,R,B) | 说明 |
| -------- | ----------------- | ----------------- | ---- |
| `VBoxContainer` | `0,0,1,1` | `15,15,-15,-15` | 内部容器，填充侧边栏 |
| `ManaPanel` | `0,0,1,0` | `0,0,0,110` | 高 110，之后多个 Panel 间隔 Separator |
| `ManaTitle` | `0,0,1,0` | `10,3,-10,25` | 顶部标题 |
| `ManaLabel` | `0,0.5,1,0.5` | `10,-5.5,-10,51` | 数值大字 |
| `FocusPanel` / `EssencePanel` / `LorePointsPanel` | 同上 | 同上 (仅高度 80) | 集中力/精华/学识点 |

#### Hud.tscn
| 组件路径 | Anchors | Offsets | 说明 |
| -------- | ------- | ------- | ---- |
| `TopPanel` | `0,0,1,0` | `350,15,-350,50` | 顶部提示栏 |
| `StatusLabel` | `0,0,1,1` | `10,0,-10,0` | 填充 TopPanel |
| `TurnPanel` | `1,1,1,1` | `-320,-150,-40,-40` | 右下回合信息 |
| `EndTurnButton` | `0,0,0,0` | `0,?` (VBox 自动) | 结束回合按钮 |
| `ScorePanel` | `0,1,0,1` | `40,-150,320,-40` | 左下得分 |
| `ScoreValue` / `MultiplierValue` | `0,0,0,0` (VBox) | `-` | 大号数字 |

#### HandDock.tscn（简要）
| 组件 | Anchors | Offsets | 说明 |
| ---- | ------- | ------- | ---- |
| `ButtonPanel` | `0,0,1,0` | `20,20,-20,60` | 手牌操作按钮区 |
| `PlayButton` / `DiscardButton` | `0,0,0,0` (Grid) | `-` | 240×55 按钮 |

其余如 `DeckWidget.tscn` 和 `TopDock.tscn` 组件较少，按照 root 表格直接核对即可。

> **技巧**：在 Godot 中选中旧节点后按 **Ctrl+C** → 选中新节点按 **Ctrl+Shift+V** 即可复制 **Rect & Theme** 属性，避免手动输入错误。
以 `Sidebar.tscn` 为例：
1. 选中根节点 `Sidebar` → `Layout ‣ Presets ‣ Custom` → 将 **Anchor** `Left/Top/Right/Bottom` 分别设为 `0/0/0/0`。
2. 在 **Offset** 中输入 `40, 15, -1595, -36` (右、下为负数)。
3. 将 `theme_override_styles/panel` 指向 `default_ui_theme.tres/StyleBoxFlat_sidebar`。其余子节点全部保持原层级 & 排版。
4. 运行场景，检查与旧版位置、尺寸是否一致。

其余子场景重复以上流程，只是数值不同 (见表格)。

---

## 3. 适配脚本 (可选)

若希望自动根据分辨率缩放，可在 `UIManager.gd` 中加入：
```gdscript
func _notification(what):
    if what == NOTIFICATION_RESIZED:
        _rescale_ui()

func _rescale_ui():
    var scale_factor = get_viewport_rect().size.y / 1080.0
    for child in get_children():
        if child is Control:
            child.scale = Vector2(scale_factor, scale_factor)
```
> *注意*：使用 `viewport` 模式时通常不需要额外缩放；若使用 `canvas_items` 伸缩，可根据项目需求调整。

---

## 4. 样式一致性检查清单

1. **字体大小**：对照 `MainGame_backup` 中 `theme_override_font_sizes/*`，确保各 Label/Button 字号一致。
2. **颜色**：使用 Theme 中的统一颜色常量，如 `color_text_primary`、`color_panel_bg`。
3. **StyleBox**：所有 Panel/Button 的 `hover/pressed/normal` 样式均来自 `default_ui_theme.tres`。
4. **Separator**：`HSeparator`/`VSeparator` 的 `theme_override_styles/separator` 设为 `StyleBoxFlat_button`。

---

## 5. 验证流程 (QA Checklist)

1. **逐分辨率测试**：1920×1080、1600×900、1280×720 → 所有 UI 不溢出/压缩破坏。
2. **互动测试**：按钮点击区域未偏移，信号仍由 `UIManager` 转发。
3. **视觉对比**：
   - 在 `MainGame_backup.tscn` 和 `MainGame.tscn` 中分别截屏 (F8)，使用视差对比工具 (如 PS 差值、Diffchecker) → 偏差 < **2 px**。
4. **可维护性**：运行 `rg -n "theme_override_styles/panel" cs/主场景/ui | wc -l` ≤ 原先数量，确保样式未重复定义。

---

## 6. 后续改进建议

1. **动态布局**：使用 `Container` 节点 (如 `MarginContainer`, `CenterContainer`) 替代部分绝对偏移以增强适配力。
2. **统一字体资源**：将所有字体打包到 Theme，并通过 `Fallback` 方案支持多语言。
3. **响应式动画**：为主要按钮添加 `Tween` 或 `AnimationPlayer` 的微交互，让 UI 更生动。
4. **文档持续同步**：完成本指南实施后，请在《技术设计与开发指南》附录 A 中更新“UI 标准尺寸表”。

---

> **完成后提交 PR**：
> ```bash
> git checkout -b chore/ui_layout_fix
> git add cs/主场景/ui/*.tscn themes/default_ui_theme.tres docs/UI优化指南_恢复布局.md
> git commit -m "chore(ui): align refactored UI with legacy layout & theme"
> git push origin chore/ui_layout_fix
> ```

祝你调优顺利！

---

# A. 一键同步（首选）

1. **创建脚本** `res://tools/rect_sync.gd`：
   ```gdscript
   @tool
   extends EditorScript

   const MAP := {
       "res://cs/主场景/ui/Sidebar.tscn": "UIContainer/SidePanel",
       "res://cs/主场景/ui/Hud.tscn":      "UIContainer/HudPanel",
       "res://cs/主场景/ui/HandDock.tscn": "UIContainer/HandArea/HandPanel",
       "res://cs/主场景/ui/DeckWidget.tscn":"UIContainer/TableArea/DeckWidget",
       "res://cs/主场景/ui/TopDock.tscn":  "UIContainer/TopDock",
   }

   func _run() -> void:
       var backup := load("res://cs/主场景/MainGame_backup.tscn").instantiate()
       for path in MAP:
           var packed := load(path) as PackedScene
           var inst   := packed.instantiate()
           var src := backup.get_node(MAP[path])
           if src and inst:
               _copy(src, inst)
               packed.pack(inst)
               ResourceSaver.save(packed, path)
               print("✓", path.get_file(), "已同步")
           else:
               push_error("✗ 未找到节点 %s" % MAP[path])
       print("=== Rect & Theme 批量同步完成 ===")

   func _copy(src:Control, dst:Control):
       dst.anchor_left   = src.anchor_left
       dst.anchor_top    = src.anchor_top
       dst.anchor_right  = src.anchor_right
       dst.anchor_bottom = src.anchor_bottom
       dst.offset_left   = src.offset_left
       dst.offset_top    = src.offset_top
       dst.offset_right  = src.offset_right
       dst.offset_bottom = src.offset_bottom
       dst.theme         = src.theme
       for c in src.get_children():
           if c is Control and dst.has_node(c.name):
               _copy(c, dst.get_node(c.name))
   ```
2. **运行脚本**：在 Godot `FileSystem` 面板右键 → `Run`。五个 UI 子场景将自动写入备份布局与样式。
3. **目检**：按 `F5` 运行游戏，界面应与 `MainGame_backup.tscn` 完全一致。

> 提示：运行前建议 `git commit` 形成回滚点。

# B. 根节点布局对照表

| 子场景 | 备份节点 | Anchors (L,T,R,B) | Offsets (L,T,R,B) |
| ------ | -------- | ----------------- | ----------------- |
| Sidebar.tscn | UIContainer/SidePanel | 0,0,0,0 | 40,15,-1595,-36 |
| Hud.tscn | UIContainer/HudPanel | 0.5,1,0.5,1 | -145,-138,145,-15 |
| HandDock.tscn | UIContainer/HandArea/HandPanel | 0,1,1,1 | 40,-285,-40,-15 |
| DeckWidget.tscn | UIContainer/TableArea/DeckWidget | 1,0.5,1,0.5 | -240,-240,-40,-60 |
| TopDock.tscn | UIContainer/TopDock | 0.5,0,0.5,0 | -360,15,360,135 |

# C. 关键子节点对照

### Sidebar.tscn
| 节点 | Anchors | Offsets |
| ---- | ------- | ------- |
| VBoxContainer | 0,0,1,1 | 15,15,-15,-15 |
| ManaPanel / FocusPanel / EssencePanel / LorePointsPanel | 0,0,1,0 | 0,0,0,80~110 |
| ManaTitle | 0,0,1,0 | 10,3,-10,25 |
| ManaLabel | 0,0.5,1,0.5 | 10,-5,-10,51 |

### Hud.tscn
| 节点 | Anchors | Offsets |
| ---- | ------- | ------- |
| TopPanel | 0,0,1,0 | 350,15,-350,50 |
| StatusLabel | 0,0,1,1 | 10,0,-10,0 |
| TurnPanel | 1,1,1,1 | -320,-150,-40,-40 |
| ScorePanel | 0,1,0,1 | 40,-150,320,-40 |

### HandDock.tscn
| 节点 | Anchors | Offsets |
| ---- | ------- | ------- |
| ButtonPanel | 0,0,1,0 | 20,20,-20,60 |
| Play / Discard Buttons | 0,0,0,0 | 0,0,0,0 |

### DeckWidget.tscn
| 节点 | Anchors | Offsets |
| ---- | ------- | ------- |
| Root Panel | 0,0,1,1 | 0,0,0,0 |
| CardPreview | 0.5,0,0.5,0 | -60,15,60,180 |

### TopDock.tscn
| 节点 | Anchors | Offsets |
| ---- | ------- | ------- |
| RuneBar | 0,0,1,0 | 0,0,0,40 |
| DiscoverPanel | 1,0,1,0 | -320,0,0,160 |

# D. 样式同步要点
1. 将全部 `StyleBoxFlat_*` 子资源拖入 `res://themes/default_ui_theme.tres`，然后在 **Project Settings → Gui → Theme** 设置为全局。
2. 校对所有 `theme_override_font_sizes` 与 `theme_override_colors`，如有差异统一到 Theme。

# E. QA Checklist
- [ ] 多分辨率（1920×1080 / 1600×900 / 1280×720）检查
- [ ] 按钮 Hover / Pressed 样式一致
- [ ] 结束回合按钮信号正常
- [ ] 卡牌拖拽坐标正确
- [ ] SidePanel 装饰“⚙”图标对齐
- [ ] 各 Panel 边框、圆角、阴影与备份一致

全部勾选完毕即可删除 `MainGame_backup.tscn` 并合并 PR。

B. 根节点布局对照表（再次列全）
子场景	备份节点	Anchors (L,T,R,B)	Offsets (L,T,R,B)
Sidebar.tscn	UIContainer/SidePanel	0,0,0,0	40,15,-1595,-36
Hud.tscn	UIContainer/HudPanel	0.5,1,0.5,1	-145,-138,145,-15
HandDock.tscn	UIContainer/HandArea/HandPanel	0,1,1,1	40,-285,-40,-15
DeckWidget.tscn	UIContainer/TableArea/DeckWidget	1,0.5,1,0.5	-240,-240,-40,-60
TopDock.tscn	UIContainer/TopDock	0.5,0,0.5,0	-360,15,360,135
C. 关键子节点对照（补全到所有面板）
1. Sidebar.tscn
节点	Anchors	Offsets
VBoxContainer	0,0,1,1	15,15,-15,-15
ManaPanel / FocusPanel / EssencePanel / LorePointsPanel	0,0,1,0	0,0,0,80~110
ManaTitle	0,0,1,0	10,3,-10,25
ManaLabel	0,0.5,1,0.5	10,-5,-10,51
2. Hud.tscn
节点	Anchors	Offsets
TopPanel	0,0,1,0	350,15,-350,50
StatusLabel	0,0,1,1	10,0,-10,0
TurnPanel	1,1,1,1	-320,-150,-40,-40
ScorePanel	0,1,0,1	40,-150,320,-40
3. HandDock.tscn
节点	Anchors	Offsets
ButtonPanel	0,0,1,0	20,20,-20,60
Play / Discard Buttons	0,0,0,0 (Grid)	0,0,0,0
4. DeckWidget.tscn
节点	Anchors	Offsets
Root Panel	0,0,1,1	0,0,0,0
CardPreview	0.5,0,0.5,0	-60,15,60,180
5. TopDock.tscn
节点	Anchors	Offsets
RuneBar	0,0,1,0	0,0,0,40
DiscoverPanel	1,0,1,0	-320,0,0,160
D. 样式同步
Theme 统一
在 res://themes/ 建 default_ui_theme.tres，把所有 StyleBoxFlat_* 子资源拖进去。
然后在 Project Settings – Gui – Theme 勾选全局，自此所有场景都继承同一 Theme。
字体 & 颜色检查
比对 
MainGame_backup.tscn
 中每个 theme_override_font_sizes 与 theme_override_colors/*。
不匹配的地方，通过 Theme 中的 Constants / Colors / Fonts 统一管理。