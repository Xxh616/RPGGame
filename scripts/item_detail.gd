# res://scripts/ItemDetail.gd
extends MarginContainer
class_name ItemDetail
signal craft_requested(recipe_id: int)

var bound_recipe_id      : int         = -1
var bound_recipe_needs   : Dictionary  = {}
# —— onready 定位各个控件 —— #
@onready var icon_texture   = $HBoxContainer/MarginContainer/Icon           as TextureRect
@onready var name_label     = $HBoxContainer/MarginContainer2/NamePathVBox/NameMargin/Label as Label
@onready var summary_label  = $HBoxContainer/MarginContainer2/NamePathVBox/PathMargin/HBoxContainer/Label   as Label
@onready var arrow_button   = $HBoxContainer/MarginContainer2/NamePathVBox/PathMargin/HBoxContainer/Button  as Button
@onready var craft_button   = $HBoxContainer/MarginContainer3/Button             as Button
@onready var inventory = inventory_autoload
@onready var materials_popup  = $MaterialsPopup                                   as PopupPanel
@onready var content_vbox     = $MaterialsPopup/PanelContainer/VBoxContainer       as VBoxContainer

# 当前这一行绑定的 CraftRecipe
var bound_recipe : CraftRecipe = null

func _ready() -> void:
	# 点击箭头，就弹出材料列表
	arrow_button.connect("pressed", Callable(self, "_on_arrow_pressed"))
	# 点击“合成”，发信号
	craft_button.connect("pressed", Callable(self, "_on_craft_pressed"))

	# PopupPanel 默认 invisible = true
	# 当 PopupPanel 被横向或纵向点击外面时会自动 hide
	# 你也可以在 Inspector 里勾 “Exclusive = true” 让它只允许点自己关闭

	# 初始时，第一行显示什么都不填
	clear_detail()


# 给 SynthesisUI 用，设置这一行要显示的内容
func set_detail(_icon: Texture2D, _name: String, _recipe: CraftRecipe) -> void:
	print(">> ItemDetail.set_detail() 被调用，recipe_id=", _recipe.get_instance_id())
	bound_recipe = _recipe
	bound_recipe_id=_recipe.get_instance_id()
	bound_recipe_needs = _recipe.needs.duplicate()
	# 第一行：Icon 和 Name
	icon_texture.texture = _icon
	name_label.text = _name

	# 先把之前 PopupPanel 里的子节点全清空
	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()

	# 拿到材料字典
	var needs = bound_recipe.needs  # Dictionary: 材料id -> 数量
	var count_mat = needs.keys().size()
	summary_label.text = "材料列表（共 %d 项）" % count_mat

	# 如果没有材料，就把箭头按钮隐藏，否者显示“▼”
	if count_mat > 0:
		arrow_button.visible = true
		arrow_button.text = "▼"
	else:
		arrow_button.visible = false

	# 在 PopupPanel 里为每条材料再生成一个 Label
	# 先获取全局 Inventory 单例，拿到 Item 资源才可显示材料的中文名
	var inv = inventory_autoload   # 如果你在 Autoload 列表里名字是 inventory_autoload
	for mat_id in needs.keys():
		var cnt = int(needs[mat_id])
		var mat_res : Item = inv.get_item_resource(mat_id)
		var mat_name : String
		if mat_res != null:
			mat_name = mat_res.name
		else:
			mat_name = mat_id
		var lab = Label.new()
		lab.text = "%s × %d" % [ mat_name, cnt ]
		content_vbox.add_child(lab)
	# 材料都放好了，PopupPanel 先是隐藏
	materials_popup.hide()

	# 先判断一下本地按钮是否可用
	var ok = true
	for mat_id in needs.keys():
		var cnt = int(needs[mat_id])
		if not inv.has_item(mat_id, cnt):
			ok = false
			break
	craft_button.disabled = not ok


# 如果该行不需要显示（比如超出了总配方数），就清空所有子控件，隐藏箭头和按钮
func clear_detail() -> void:
	bound_recipe = null
	icon_texture.texture = null
	name_label.text = ""
	summary_label.text = ""
	arrow_button.visible = false
	craft_button.disabled = true

	# 清空 PopupPanel
	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()
	materials_popup.hide()


# 点击箭头按钮时，弹出或隐藏 PopupPanel
func _on_arrow_pressed() -> void:
	print("▶▶▶ _on_arrow_pressed() 被触发，bound_recipe_id=", bound_recipe_id)
	# 如果配方没绑定，就不弹
	if bound_recipe_id ==-1:
		return

	# 如果当前 popup 已经可见，就收起并换箭头图标
	if materials_popup.visible:
		materials_popup.hide()
		arrow_button.text = "▼"
		return

	# 1) 清空以前残留的 Label
	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()

	# 2) 逐条创建最简单的 Label，只填“材料名称 × 数量”
	for mat_id in bound_recipe_needs.keys():
		var cnt = int(bound_recipe_needs[mat_id])
		var mat_res : Item = inventory.get_item_resource(mat_id)
		var mat_name : String = mat_id
		if mat_res != null:
			mat_name = mat_res.name

		var lab = Label.new()
		lab.text = "%s × %d" % [mat_name, cnt]
		# 不额外设置 wrap/对齐/size_flags，只要文字出来就行
		content_vbox.add_child(lab)
	# 隐藏一下，确保从收起状态切到弹出状态
	

	# 3) 计算一下“箭头按钮”下方的位置，把弹窗显示出来
	#    这里演示把 PopupPanel 弹到当前 ItemDetail 整个控件的正下方
	var rect = get_global_rect()   # 取本节点的全局 Rect2
	var popup_pos = Vector2(rect.position.x, rect.position.y + rect.size.y + 5)

	# Godot 4 里直接用 popup()，参数是一个 Rect2（或一个 Vector2 表示左上角），
	# 也可以直接传一个 Vector2 表示左上坐标，剩下尺寸会自动用最小尺寸。
	# 这里我们只关心“左上角”位置，把弹窗顶在它下面 5 像素。  
	materials_popup.popup(Rect2(popup_pos, Vector2.ZERO))

	# 最后把箭头换成“向上”，表示下次点一下是收起
	arrow_button.text = "▲"


# 点击“合成”时，向父界面发出 craft_requested(signal)
func _on_craft_pressed() -> void:
	if bound_recipe:
		emit_signal("craft_requested", bound_recipe.get_instance_id())
