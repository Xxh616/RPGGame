# res://scripts/StorageSlot.gd
# 适用于 Godot 4.x
extends MarginContainer
class_name StorageSlot
# “可点/未选中” 的 Normal 样式
const SB_SELECT_NORMAL  : StyleBoxTexture = preload("res://Resources/ButtonItem/empty.tres")
# “选中后” 的 Normal 样式
const SB_SELECT_PRESSED : StyleBoxTexture = preload("res://Resources/ButtonItem/Noempty.tres")
# —— 信号定义 —— #
# 当玩家点击选中本格，要把 select_amount 传给父节点
signal amount_changed(item_id: String, new_amount: int)
var selectornot=false
# —— 内部变量 —— #
# 这一格当前代表的物品 ID（外部赋值），比如 "HealthPotion"
var item_id: String = ""

# 该格当前所在模式：true = “Storage 模式”（从箱子取出）， false = “Inventory 模式”（从背包存入）
var is_storage_mode: bool = true

# 在 Storage 模式下，available_count 代表“箱子里此物品总量”
# 在 Inventory 模式下，available_count 代表“背包里此物品总量”
var available_count: int = 0

# “本格当前要转移”的数量（范围 0 ~ available_count）
var select_amount: int = 0


# —— onready 缓存各子节点 —— #
@onready var select_button   = $SlotVBox/SelectMargin/SelectButton   as Button
@onready var icon_texture    = $SlotVBox/IconMargin/Icon             as TextureRect
@onready var count_badge     = $SlotVBox/IconMargin/Label            as Label
@onready var name_label      = $SlotVBox/NameMargin/Name             as Label
@onready var minus_button    = $SlotVBox/CountSelectMargin/HBoxContainer/MinusMargin/MinusButton  as Button
@onready var count_label     = $SlotVBox/CountSelectMargin/HBoxContainer/CountMargin/CountLabel   as Label
@onready var add_button      = $SlotVBox/CountSelectMargin/HBoxContainer/AddMargin/AddButton     as Button
@onready var selectbuttonbackground    = $SlotVBox/SelectMargin/NinePatchRect as NinePatchRect
@onready var countlabelbackground    = $SlotVBox/CountSelectMargin/HBoxContainer/CountMargin/NinePatchRect as NinePatchRect
func _ready() -> void:
	
	# 1) 连接“减号”“加号”按钮
	minus_button.connect("pressed", Callable(self, "_on_minus_pressed"))
	add_button.connect("pressed",   Callable(self, "_on_add_pressed"))
	# 2) 连接“选择”按钮（ToggleButton），当切换时触发更新
	select_button.connect("pressed", Callable(self, "_on_select_toggled"))
	# 3) 初始化 UI 为“空格”状态
	_clear_slot()


# ────────────────────────────────────── #
# —— 外部调用接口：由父节点（StorageUI）逐行调用 —— #
func set_slot(
		item_id_str: String,
		icon_tex: Texture2D,
		display_name: String,
		total_count: int,
		storage_mode: bool
	) -> void:
	
	# 记录当前行的属性
	item_id = item_id_str
	is_storage_mode = storage_mode
	available_count = max(total_count, 0)
	# 先清除之前所有状态（只隐藏内部子节点，保留格子背景）
	_clear_slot()

	# 1) 图标 + 徽章 + 名称 都显示出来
	icon_texture.texture = icon_tex
	icon_texture.visible = true

	name_label.text = display_name
	name_label.visible = true

	count_badge.text = str(available_count)
	count_badge.visible = true

	# 2) “取出/存入” 小圆圈 按钮
	select_button.visible  = true
	select_button.disabled = (available_count <= 0)

	count_label.text = "0"
	count_label.visible = true
	minus_button.visible = true
	minus_button.disabled = true
	add_button.visible = true
	add_button.disabled = (available_count <= 0)
	selectbuttonbackground.visible=true
	countlabelbackground.visible=true
	# 根节点保持可见，保留格子背景
	self.visible = true
	
# 然后刷新本次的样式：要么灰显（删了覆盖后默认就是空），要么仍然空着
	_update_select_button_style()


# —— 清空本行所有显示状态 —— #
func _clear_slot() -> void:
	# 重置内部状态变量
	is_storage_mode = true
	select_amount = 0

	# 2) 隐藏“图标+徽章+名称”
	icon_texture.visible = false
	count_badge.visible  = false
	name_label.visible   = false

	# 3) 隐藏“加减按钮”+“数量文字”+“取出/存入按钮”
	minus_button.visible    = false
	count_label.visible     = false
	add_button.visible      = false
	select_button.visible   = false
	selectbuttonbackground.visible=false
	countlabelbackground.visible=false
	# 恢复根节点（空格子背景）到正常状态（不灰化）
	self.modulate = Color(1, 1, 1, 1)
	# 保持根节点可见，让“空格子背景”始终占位
	self.visible = true



# ────────────────────────────────────── #
# —— 用户交互：对本行的“选择”按钮、加号、减号操作 —— #

# 当玩家在本行点了【选择】按钮（Toggle）之后
func _on_select_toggled() -> void:
	selectornot=!selectornot
	# 如果按下后处于“选中”状态
	if selectornot:
		# “第一次选中”时，给数量横幅 +1
		select_amount = 1
		count_label.text = str(select_amount)
		minus_button.disabled = (select_amount <= 0)
		add_button.disabled  = (select_amount >= available_count)
	else:
		select_amount = 0
		count_label.text = "0"
		minus_button.disabled = true
		add_button.disabled   = false
	_update_select_button_style()

	# 将当前 select_amount 发给父界面，让它更新“总共要转移的列表”等
	emit_signal("amount_changed", item_id, select_amount)



# 当玩家点了“减号”按钮
func _on_minus_pressed() -> void:
	if select_amount <= 0:
		return
	
	select_amount -= 1
	if select_amount < 0:
		select_amount = 0
	
	count_label.text = str(select_amount)

	# 如果减到 0，就禁用减号；否则保持解锁
	minus_button.disabled = (select_amount <= 0)
	# 如果原先达到了 available_count，就把加号按钮打开
	add_button.disabled   = (select_amount >= available_count)

	# 如果减到 0，就自动取消“选中”状态
	if select_amount == 0:
		selectornot=false
		select_button.set_pressed(false)
	_update_select_button_style()
	emit_signal("amount_changed", item_id, select_amount)



# 当玩家点了“加号”按钮
func _on_add_pressed() -> void:
	if select_amount >= available_count:
		return
	
	select_amount += 1
	if select_amount > available_count:
		select_amount = available_count
	
	count_label.text = str(select_amount)

	# 如果加到 0 < select_amount < available_count，就保持加减都可用
	minus_button.disabled = (select_amount <= 0)
	add_button.disabled   = (select_amount >= available_count)

	# 如果第一次加到 1，就把 ToggleButton 强制设为“选中”状态
	if select_amount > 0:
		selectornot=true
	_update_select_button_style()
	emit_signal("amount_changed", item_id, select_amount)



# （可选）如果想从外部设置 select_amount，可调用此方法
func set_select_amount(new_amount: int) -> void:
	select_amount = clamp(new_amount, 0, available_count)
	count_label.text = str(select_amount)

	# 根据新的值更新按钮可用状态
	minus_button.disabled = (select_amount <= 0)
	add_button.disabled   = (select_amount >= available_count)

	# 如果设为 0 就自动取消 Toggle
	select_button.pressed = (select_amount > 0)

	# 发信号通知父节点
	emit_signal("amount_changed", item_id, select_amount)
func _update_select_button_style() -> void:
	# 如果 available_count == 0，就用“Disabled”样式（灰显），否则再看是否已经“Pressed”
	if count_label.text=="0":
		select_button.add_theme_stylebox_override("normal", SB_SELECT_NORMAL)
		select_button.set_pressed(false)   # 取消选中
		   # 持续保持禁用
		return
	
	
	# 如果按钮本身“已选中”（pressed = true），就用“已选中”样式；否则用“未选中”样式
	if selectornot:
		select_button.add_theme_stylebox_override("normal", SB_SELECT_PRESSED)
	else:
		select_button.remove_theme_stylebox_override("normal")
		select_button.add_theme_stylebox_override("normal", SB_SELECT_NORMAL)
		
	# 确保 disabled 还是 false，这里按钮可用
	select_button.disabled = false
