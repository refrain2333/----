# UIManager 合并与节点路径修复实施文档

> 关联任务：技术设计与开发指南 §6 待办 #2  
> 目标用时：0.5 人日  
> 更新日期：2025-06-14

---

## 0. 背景
早期版本存在两个 UI 管理脚本：
1. `cs/主场景/ui/UIManager.gd`（新版，依赖信号总线，分离逻辑/视图）。  
2. `cs/主场景/ui/UIManager_backup.gd`（旧版，硬编码节点路径）。

重复脚本导致：
- 部分场景仍引用旧脚本，运行时报 **Null Instance**。  
- 新增 UI 元素需在两处维护。  

本任务将：
1. 确认并保留新版 `UIManager.gd`。  
2. 统一所有场景/脚本引用。  
3. 删除旧脚本与遗留节点。  
4. 增加自动查找函数，避免硬编码路径。  
5. 编写一次性迁移检测 GDScript。  

---

## 1. 文件检查
| 动作 | 命令 (PowerShell) | 输出应包含 |
| ---- | ----------------- | ---------- |
| 搜索 UIManager 引用 | `rg -n "UIManager_backup.gd" cs` | 若存在行 → 需替换 |
| 搜索节点路径字符串 | `rg -n "hud/" cs/主场景` | 列出硬编码路径 |

> **提示**：使用 Cursor 的 “Replace in Project” 工具对结果批量处理。

---

## 2. 新版 UIManager.gd 设计
```gdscript
class_name UIManager
extends Node

signal hud_ready(hud)

@export var hud_scene: PackedScene
var hud: Hud

func _ready():
    if hud_scene:
        hud = hud_scene.instantiate()
        add_child(hud)
        emit_signal("hud_ready", hud)
```
改动：
- `Hud` 场景序列化为 `PackedScene`，运行时实例化  可热插拔皮肤。  
- 不暴露任何具体节点路径，由 Hud 内部自行管理按钮/数值。

---

## 3. 修改主场景 MainGame.tscn
1. 选中 `UIManager` 节点，脚本路径改为 `res://cs/主场景/ui/UIManager.gd`。  
2. Inspector → **hud_scene** 指向 `res://cs/主场景/ui/Hud.tscn`。  
3. 删除旧节点 `UIManager_backup`、信号重新连接：
   - `UIManager.hud_ready` → `TurnManager.connect_ui(hud)` (新增函数)。

### TurnManager 新函数
```gdscript
func connect_ui(hud: Node):
    hud.end_turn_pressed.connect(_on_end_turn_pressed)
    # 更多 ui 信号绑定
```

---

## 4. 替换硬编码路径
示例：
```gdscript
# BEFORE
var mana_label = get_node("../../ui/Hud/ManaLabel")

# AFTER
autoload UIRegistry # 存储对子 node 引用，或通过传参注入
var mana_label = UIRegistry.mana_label
```

集中存放于 `cs/主场景/ui/UIRegistry.gd`：
```gdscript
class_name UIRegistry
extends Node
var mana_label: Label
var hp_label: Label
# ...
```
Scene  完成 `hud_ready` 后向 registry 写入引用。

---

## 5. 清理与测试
1. **删除文件** `cs/主场景/ui/UIManager_backup.gd`。  
2. Godot Editor 运行 `F6` 单场景 MainGame，观察：
   - 控制台无 `Missing Script`。  
   - 点击“结束回合”仍能触发 TurnManager。  
3. 运行 GUT：  
   ```bash
   godot -q --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gfilter="ui*"
   ```
   测试用例：
   - `test_ui_manager.tres` → 确认 hud 实例化 & 信号绑定。  

---

## 6. 回滚方案
- Git 保留 `UIManager_backup.gd` 历史，可 `git checkout` 指定 commit 恢复。  
- 若出现大面积路径失效，执行 `scripts/tools/restore_old_ui.gd` 临时切回旧 manager。

---

## 7. 时间线
| 时段 | 子任务 |
| ---- | ------ |
| 09:00-09:30 | 文件检索 & 路径替换 |
| 09:30-10:30 | 实现新版 UIManager、Registry、TurnManager 绑定 |
| 10:30-11:00 | 删除旧脚本、跑测试、提交 MR |

> **Done Definition**：Editor 运行无错误，`EndTurnButton` 正常工作，`rg "UIManager_backup"` 无输出，CI 测试通过。

---

## 8. Git 提交流程
```bash
git checkout -b feature/ui_manager_refactor
# 进行代码修改
# 确认测试通过
git add cs docs test
git commit -m "refactor(ui): merge UIManager and remove legacy paths"
git push origin feature/ui_manager_refactor
```
开 PR → 指派 Reviewer → CI 通过后 Merge。
