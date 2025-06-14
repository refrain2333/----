class_name InputManager
extends Node

var main_game  # 引用主场景

func _init(game_scene):
    main_game = game_scene

# 符文库鼠标悬停效果
func _on_rune_back_mouse_entered():
    # 当鼠标悬停在符文库上时的效果
    # 放大符文库图像
    var tween = main_game.create_tween()
    tween.tween_property(main_game.ui_manager.rune_back_texture, "scale", Vector2(1.05, 1.05), 0.1)
    main_game.ui_manager.set_status("点击抽取一张符文")

# 符文库鼠标离开效果
func _on_rune_back_mouse_exited():
    # 当鼠标离开符文库时的效果
    # 恢复符文库图像原始大小
    var tween = main_game.create_tween()
    tween.tween_property(main_game.ui_manager.rune_back_texture, "scale", Vector2(1.0, 1.0), 0.1)
    main_game.ui_manager.set_status("请选择要施放的奥术符文")

# 符文库点击效果
func _on_rune_back_input(event):
    # 当点击符文库时的效果
    # 如果是左键点击，抽一张卡牌
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if not GameManager.is_hand_full():
            main_game.card_manager.draw_card_from_library()
        else:
            main_game.ui_manager.set_status("手牌已满，无法抽取更多符文")

# 新增功能 - 处理减少符文费用按钮
func _on_minus_button_pressed():
    if GameManager.rune_cost > GameManager.MIN_RUNE_COST:
        GameManager.set_rune_cost(GameManager.rune_cost - 1)
        main_game.ui_manager.update_ui()
        main_game.ui_manager.set_status("符文费用减少至 " + str(GameManager.rune_cost))

# 新增功能 - 处理增加符文费用按钮
func _on_plus_button_pressed():
    if GameManager.rune_cost < GameManager.max_cost:
        GameManager.set_rune_cost(GameManager.rune_cost + 1)
        main_game.ui_manager.update_ui()
        main_game.ui_manager.set_status("符文费用增加至 " + str(GameManager.rune_cost))

# 新增功能 - 处理设置按钮点击
func _on_settings_button_pressed():
    main_game.ui_manager.set_status("设置菜单即将开放...")
    # 在此添加打开设置菜单的代码
    # 例如: $SettingsMenu.show()
    pass 