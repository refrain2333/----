class_name LogManager
extends RefCounted

## 统一日志管理系统
## 用于替换HandDock中分散的日志函数

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3
}

static var debug_mode: bool = false
static var current_level: LogLevel = LogLevel.INFO
static var log_to_file: bool = false
static var log_file_path: String = "user://game.log"

## 主要日志方法
static func log_message(component: String, message: String, level: LogLevel = LogLevel.INFO):
	if level < current_level:
		return

	var level_text = ["DEBUG", "INFO", "WARN", "ERROR"][level]
	var timestamp = Time.get_datetime_string_from_system()
	var formatted_message = "[%s] %s[%s]: %s" % [timestamp, component, level_text, message]

	# 输出到控制台
	print(formatted_message)

	# 可选：输出到文件
	if log_to_file:
		_write_to_file(formatted_message)

## 便捷方法
static func debug(component: String, message: String):
	if debug_mode:
		log_message(component, message, LogLevel.DEBUG)

static func info(component: String, message: String):
	log_message(component, message, LogLevel.INFO)

static func warning(component: String, message: String):
	log_message(component, message, LogLevel.WARNING)

static func error(component: String, message: String):
	log_message(component, message, LogLevel.ERROR)

## 设置方法
static func set_debug_mode(enabled: bool):
	debug_mode = enabled

static func set_log_level(level: LogLevel):
	current_level = level

static func enable_file_logging(enabled: bool, file_path: String = "user://game.log"):
	log_to_file = enabled
	log_file_path = file_path

## 私有方法
static func _write_to_file(message: String):
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_line(message)
		file.close()

## 初始化方法（在游戏启动时调用）
static func initialize(config: Dictionary = {}):
	debug_mode = config.get("debug_mode", false)
	current_level = config.get("log_level", LogLevel.INFO)
	log_to_file = config.get("log_to_file", false)
	log_file_path = config.get("log_file_path", "user://game.log")
	
	info("LogManager", "日志系统已初始化 - Debug: %s, Level: %s" % [debug_mode, current_level])
