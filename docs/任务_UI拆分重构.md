# UI 拆分重构方案

> 目的：消除 `MainGame.tscn` 与 `cs/主场景/ui/` 中 UI 场景重复，形成 **单一来源**。主场景仅负责拼装，具体 UI 组件按功能拆分为独立 tscn，放置于 `cs/主场景/ui/` 目录，方便复用与主题切换。

---

## 1. 现状问题
| 文件 | 角色 | 问题 |
| ---- | ---- | ---- |
| `MainGame.tscn` | 运行入口 | 内嵌大量 Panel/Button/Label；与 `ui` 目录场景功能重复；维护困难 |
| `cs/主场景/ui/` | HUD.tscn、HandPanel.tscn... | 新增 UI 组件，但主场景未引用或功能重叠 |

---

## 2. 拆分原则
1. **功能单一**：每个 tscn 负责一块 UI 区域（Sidebar/Hud/HandDock/DeckWidget）。  
2. **无逻辑耦合**：展示逻辑放组件脚本；游戏逻辑统一由 `UIManager` 转发信号。  
3. **MainGame 只挂 `UIManager`**：在 `_ready()` 中实例化各 UI 子场景并加入树中。  

---

## 3. 目标目录结构
```
cs/主场景/
  MainGame.tscn
  MainGame.gd
  ui/
    Sidebar.tscn        # 左侧信息面板
    Hud.tscn            # 资源 / 结束回合 按钮
    HandDock.tscn       # 手牌 & 操作按钮
    DeckWidget.tscn     # 牌库堆叠
    TopDock.tscn        # 法器槽 + 发现槽
    UIManager.gd        # 实例化 & 信号桥
```
每个 tscn 均有对应脚本，如 `Sidebar.gd` 只处理 UI 展示。

---

## 4. 具体拆分步骤
### Step 1 备份
- 将现 `MainGame.tscn` 复制为 `MainGame_backup.tscn`，确保可回滚。

### Step 2 新建子场景
在 Godot Editor：
1. 创建新场景 `Sidebar.tscn`，从 MainGame 复制左栏节点 → 保存。  
2. 重复操作：`Hud.tscn`, `HandDock.tscn`, `DeckWidget.tscn`, `TopDock.tscn`。  
3. 为每个子场景根节点挂脚本（模板见下）。

### Step 3 编写 UIManager.gd
```gdscript
class_name UIManager
extends CanvasLayer

@export var sidebar_scene:PackedScene
@export var hud_scene:PackedScene
# ... 其余场景

func _ready():
    add_child(sidebar_scene.instantiate())
    add_child(topdock_scene.instantiate())
    var hud = hud_scene.instantiate()
    add_child(hud)
    emit_signal("hud_ready", hud)
```
- MainGame 在场景树中新增 `UIManager` 节点，设置导出变量引用各 tscn。

### Step 4 清理 MainGame.tscn
- 删除原有 Panel/Button 等 UI 节点，仅保留游戏逻辑容器（桌面、管理器）。  
- 确保背景 TextureRect 仍存在或移至 `TopDock` 持有。

### Step 5 信号接线
1. `UIManager.hud_ready` → `TurnManager.connect_ui(hud)` (已有文档)。  
2. `HandDock.play_pressed` / `discard_pressed` → `CardManager.play_selected()` / `discard_selected()`。

### Step 6 测试
- 运行 F5：检查 UI 位置、按钮功能、无重复显示。  
- `rg -n "Panel.*sidebar" cs/主场景` 验证主场景不再包含 UI 具体节点。

---

## 5. 示例脚本 Sidebar.gd
```gdscript
class_name Sidebar
extends Panel

@onready var focus_label   : Label = $VBox/FocusLabel
@onready var essence_label : Label = $VBox/EssenceLabel
@onready var score_label   : Label = $VBox/ScoreLabel

func _ready():
    GameManager.resources_changed.connect(_update)
    GameManager.score_changed.connect(_update_score)
    _update(GameManager.focus, GameManager.essence, GameManager.deck_size)
    _update_score(GameManager.score)
```

---

## 6. 里程碑
| 时间 | 子任务 |
| ---- | ------ |
| +0.5h | 备份 + 创建子场景 |
| +1h | UIManager.gd 实例化 & MainGame 清理 |
| +0.5h | 信号接线 + 本地测试 |
| +0.25h | Git 提交 PR |

---

## 7. Git 提交示例
```bash
git checkout -b refactor/ui_split
git add cs/主场景/ui *.tscn *.gd
git commit -m "refactor(ui): split MainGame UI into modular scenes"
git push origin refactor/ui_split
```

> 完成后请将 `MainGame_backup.tscn` 删除，并在《技术设计与开发指南》待办 #2 标记 ✅。
