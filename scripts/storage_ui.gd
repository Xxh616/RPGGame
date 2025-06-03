# res://scripts/Storage_UI.gd
extends Control
class_name StorageUI

const SLOTS_PER_PAGE := 14

@onready var select_storage_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/UISelectButtonMargin/HBoxContainer/StorageMargin/SelectStorageButton   as Button
@onready var select_inventory_btn = $TopBottomMargin/BottomMargin/HBoxContainer/UISelectButtonMargin/HBoxContainer/InventoryMargin/SelectInventoryButton as Button

@onready var weapon_btn     = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/WeaponMargin/WeaponButton     as Button
@onready var consumable_btn = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/ConsumableMargin/ConsumableButton as Button
@onready var material_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/MaterialMargin/MaterialButton   as Button
@onready var special_btn    = $TopBottomMargin/BottomMargin/HBoxContainer/ButtonIdentifyContainer/HBoxContainer/SpecialMargin/SpecialButton    as Button

@onready var slot_container = $TopBottomMargin/BottomMargin/HBoxContainer/SlotMargin/GridContainer as GridContainer
@onready var slot_nodes     : Array = []  # 存放 SLOTS_PER_PAGE 个 StorageSlot 实例

@onready var prev_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer/Button   as Button
@onready var page_label = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer2/PageLabel as Label
@onready var next_btn   = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer3/Button   as Button
@onready var get_btn    = $TopBottomMargin/BottomMargin/HBoxContainer/MarginContainer/HBoxContainer/MarginContainer4/Button   as Button

# —— 状态字段 —— #
var is_storage_mode : bool = true                # true=“从储藏箱取出”， false=“往储藏箱存入”
var current_category := Item.ItemType.Misc       # 默认显示 “Misc” 类别
var current_page := 0
var max_pages := 1

# 存放“筛选后、分页后”本页要显示的 item 列表：
# 每项是 Dictionary {"item_id":String, "count":int, "icon":Texture2D, "name":String}
var page_items : Array = []

func _ready() -> void:
	# 1) 找到 GridContainer 里的每个 StorageSlot，并存到 slot_nodes 数组里
	slot_nodes.clear()
	for chi in slot_container.get_children():
		if chi is StorageSlot:
			slot_nodes.append(chi)
	# slot_nodes 应该就是 SLOTS_PER_PAGE 个 StorageSlot 实例
	# 2) 连接“Storage/Inventory”切换按钮
	select_storage_btn.connect("pressed", Callable(self, "_on_storage_button_pressed"))
	select_inventory_btn.connect("pressed", Callable(self, "_on_inventory_button_pressed"))

	# 3) 连接类型筛选按钮
	

	# 4) 连接翻页按钮
	prev_btn.connect("pressed", Callable(self, "_on_prev_pressed"))
	next_btn.connect("pressed", Callable(self, "_on_next_pressed"))

	# 5) 连接每个 StorageSlot 发出的 amount_changed 信号
	for slot in slot_nodes:
		slot.connect("amount_changed", Callable(self, "_on_slot_amount_changed"))
	
	# 6) 连接 GetButton
	get_btn.connect("pressed", Callable(self, "_on_get_pressed"))
	
	inventory_autoload.add_item_by_id("Sword_I", 1)
	StorageAutoload.add_item_by_id("Sword_I", 2)
	StorageAutoload.add_item_by_id("Sword_Power", 1)
	StorageAutoload.add_item_by_id("Slime vial", 5)
	inventory_autoload.add_item_by_id("health_potion", 3)
	inventory_autoload.add_item_by_id("First-grade ore", 10)
	# 7) 初始化：默认选“取出模式”+“武器分类”
	_update_mode_buttons()
	_select_mode(true)    # true = storage 模式
	_on_category_button_pressed(Item.ItemType.Weapon)
	


#—————— 模式与分类切换回调 ——————
func _on_storage_button_pressed() -> void:
	_select_mode(true)

func _on_inventory_button_pressed() -> void:
	_select_mode(false)

func _select_mode(to_storage: bool) -> void:
	if is_storage_mode == to_storage:
		return
	is_storage_mode = to_storage
	current_page = 0
	_update_mode_buttons()
	_refresh_page()

func _update_mode_buttons() -> void:
	# ** 不做任何 pressed、modulate、add_color_override 之类的操作 **
	# 只更新最下方那个 Get 按钮的文字
	get_btn.text = "取出" if is_storage_mode else "存入"



# 统一的分类切换函数
func _on_category_button_pressed(t: int) -> void:
	if current_category == t:
		return
	current_category = t
	current_page = 0
	_refresh_page()


#—————— 翻页 ——————
func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_refresh_page()

func _on_next_pressed() -> void:
	if current_page < max_pages - 1:
		current_page += 1
		_refresh_page()


#—————— 格子里「要转移数量」发生变化时回调（可选） ——————
func _on_slot_amount_changed(item_id: String, new_amount: int) -> void:
	# 目前不做更新提示，留空即可
	pass


#—————— GetButton 被按下 —— 真正执行转移动作 ——————
func _on_get_pressed() -> void:
	for slot in slot_nodes:
		print("slot_id=%s"%slot.item_id)
		var id = slot.item_id
		var amt = slot.select_amount
		if id == "" or amt <= 0:
			continue
		if is_storage_mode:
			# 从储藏箱取出 amt 件到背包
			if StorageAutoload.remove_item_by_id(id, amt):
				inventory_autoload.add_item_by_id(id, amt)
			else:
				push_warning("StorageUI: 无法从储藏箱取出 %s × %d" % [id, amt])
		else:
			# 从背包取出 amt 件，存到储藏箱里
			if inventory_autoload.remove_item(id, amt):
				StorageAutoload.add_item_by_id(id, amt)
			else:
				push_warning("StorageUI: 背包中无法移出 %s × %d" % [id, amt])
	var store_list = StorageAutoload.get_items_by_type(current_category)
	print_debug(">>> 操作后，仓库里 “类别 %s” 下的物品列表：" % str(current_category))
	for d in store_list:
		print_debug("    %s  × %d" % [d["item_id"], d["count"]])

	# 2) 打印当前“背包”里所有物品
	var inv_list = inventory_autoload.get_items_by_type(current_category)
	print_debug(">>> 操作后，背包里 “类别 %s” 下的物品列表：" % str(current_category))
	for d in inv_list:
		print_debug("    %s  × %d" % [d["item_id"], d["count"]])
	# 转移完毕 → 刷新界面
	_refresh_page()


#—————— 核心：刷新当前页显示内容 ——————
func _refresh_page() -> void:
	var all_items: Array = []
	if is_storage_mode:
		all_items = StorageAutoload.get_items_by_type(current_category)
		
	else:
		all_items = inventory_autoload.get_items_by_type(current_category)
		
	

	var total = all_items.size()
	max_pages = int(ceil(float(total) / SLOTS_PER_PAGE))
	if max_pages == 0:
		max_pages = 1
	
	prev_btn.disabled = (current_page <= 0)
	next_btn.disabled = (current_page >= max_pages - 1)
	page_label.text   = "第 %d / %d 页" % [current_page + 1, max_pages]

	for i in range(SLOTS_PER_PAGE):
		var slot_node = slot_nodes[i] as StorageSlot
		var idx = current_page * SLOTS_PER_PAGE + i
		if idx < total:
			var info = all_items[idx]
			slot_node.set_slot(
				info["item_id"],
				info["icon"],
				info["name"],
				info["count"],
				is_storage_mode
			)
		else:
			# 只调用 clear_slot，让格子背景保持可见，内部空白
			slot_node._clear_slot()
		
 

#—————— 四个分类按钮的回调 ——————
func _on_weapon_button_pressed() -> void:
	if current_category == Item.ItemType.Weapon:
		return
	current_category = Item.ItemType.Weapon
	current_page = 0
	_refresh_page()

func _on_consumable_button_pressed() -> void:
	if current_category == Item.ItemType.Consumable:
		return
	current_category = Item.ItemType.Consumable
	current_page = 0
	_refresh_page()

func _on_material_button_pressed() -> void:
	if current_category == Item.ItemType.Material:
		return
	current_category = Item.ItemType.Material
	current_page = 0
	_refresh_page()

func _on_special_button_pressed() -> void:
	if current_category == Item.ItemType.Special:
		return
	current_category = Item.ItemType.Special
	current_page = 0
	_refresh_page()
