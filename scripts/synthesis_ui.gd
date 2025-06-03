# res://scripts/SynthesisUI.gd
extends Control

const ITEMS_PER_PAGE := 5

@export var recipes_base_path : String = "res://Resources/recipes"

var recipes_by_category := {
	"Weapon": [],
	"Consumable": [],
	"Special": []
}

var current_category := "Weapon"
var current_page := 0
var max_pages := 1

@onready var weapon_btn     = $TopButtonVBox/ButtomMargin/HBoxContainer/LeftMargin/LeftVBox/MarginContainer/Button       as Button
@onready var consumable_btn = $TopButtonVBox/ButtomMargin/HBoxContainer/LeftMargin/LeftVBox/MarginContainer2/Button     as Button
@onready var special_btn    = $TopButtonVBox/ButtomMargin/HBoxContainer/LeftMargin/LeftVBox/MarginContainer3/Button     as Button

@onready var detail_nodes := [
	$TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/ItemDetail  as MarginContainer,
	$TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/ItemDetail2 as MarginContainer,
	$TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/ItemDetail3 as MarginContainer,
	$TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/ItemDetail4 as MarginContainer,
	$TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/ItemDetail5 as MarginContainer
]

@onready var prev_page_btn = $TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer/Button as Button
@onready var next_page_btn = $TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer3/Button as Button
@onready var page_label    = $TopButtonVBox/ButtomMargin/HBoxContainer/RightMargin/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer2/PageLabel  as Label

@onready var inventory = inventory_autoload

func _ready() -> void:
	# 1) 先把 recipes 目录下的所有 .tres 资源 load 进来
	_load_all_recipes()
	# 2) 绑定翻页按钮
	prev_page_btn.connect("pressed", Callable(self, "_on_PrevPage_pressed"))
	next_page_btn.connect("pressed", Callable(self, "_on_NextPage_pressed"))
	# 先打一下 detail_nodes 内容
	for i in range(detail_nodes.size()):
		var dn = detail_nodes[i]
		print(">>> detail_nodes[", i, "] = ", dn)
	# 3) 绑定 5 个 ItemDetail 里自定义的 craft_requested 信号
	for dn in detail_nodes:
		dn.connect("craft_requested", Callable(self, "_on_DetailCraft_requested"))

	# 4) （手动已经在编辑器里连好了）分类按钮 pressed → 以下三个回调
	#    所以这里不需要再写 connect 代码，直接实现回调体即可。

	# 5) 默认先显示 Weapon 第 1 页
	_select_category("Weapon")
	_refresh_page()

# -------------------------------------------------------
func _load_all_recipes() -> void:
	var base_dir = DirAccess.open(recipes_base_path)
	if base_dir == null:
		push_error("找不到配方根目录：" + recipes_base_path)
		return

	base_dir.list_dir_begin()
	var subdir_name = base_dir.get_next()
	while subdir_name != "":
		if subdir_name.begins_with("."):
			subdir_name = base_dir.get_next()
			continue

		var full_subdir = recipes_base_path + "/" + subdir_name
		var sub_da = DirAccess.open(full_subdir)
		# 只要能打开这个路径，就当作一个“目录”来遍历 .tres 文件
		if sub_da != null:
			if not recipes_by_category.has(subdir_name):
				recipes_by_category[subdir_name] = []
			_load_recipes_from_dir(subdir_name, full_subdir)
		subdir_name = base_dir.get_next()
	base_dir.list_dir_end()

func _load_recipes_from_dir(category_name: String, dir_path: String) -> void:
	var da = DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var fname = da.get_next()
	while fname != "":
		# 只对 .tres 资源文件进行加载
		if fname.to_lower().ends_with(".tres"):
			var full_path = dir_path + "/" + fname
			var r = ResourceLoader.load(full_path)
			if r and r is CraftRecipe:
				recipes_by_category[category_name].append(r)
			else:
				push_warning("“%s” 不是 CraftRecipe 资源" % full_path)
		fname = da.get_next()
	da.list_dir_end()

# -------------------------------------------------------
func _select_category(cat: String) -> void:
	if current_category == cat:
		return
	current_category = cat
	current_page = 0
	_refresh_page()


# -------------------------------------------------------
func _on_weapon_button_pressed() -> void:
	_select_category("Weapon")


func _on_consumable_button_pressed() -> void:
	_select_category("Consumable")


func _on_special_button_pressed() -> void:
	_select_category("Special")


# -------------------------------------------------------
func _on_PrevPage_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_refresh_page()


func _on_NextPage_pressed() -> void:
	if current_page < max_pages - 1:
		current_page += 1
		_refresh_page()


# -------------------------------------------------------
# 当某行的“合成”被点时，会收到 craft_requested(recipe_idx)
func _on_DetailCraft_requested(recipe_idx: int) -> void:
	var chosen_recipe: CraftRecipe = null
	# 从 recipes_by_category 中找出 instance_id 与 recipe_idx 匹配的那条
	for cat_name in recipes_by_category.keys():
		for r in recipes_by_category[cat_name]:
			if r.get_instance_id() == recipe_idx:
				chosen_recipe = r
				break
		if chosen_recipe:
			break

	if chosen_recipe == null:
		push_warning("找不到索引为 %d 的 CraftRecipe" % recipe_idx)
		return

	# 检查背包材料是否都足够
	var can_craft = true
	for mat_id in chosen_recipe.needs.keys():
		var need_cnt = int(chosen_recipe.needs[mat_id])
		if not inventory.has_item(mat_id, need_cnt):
			can_craft = false
			break
	if not can_craft:
		# 材料不足时弹个提示（假设你已经有一个 UI group 里 show_popup() 的方法）
		get_tree().call_group("UI", "show_popup", "材料不足，无法合成！")
		return

	# 扣除材料
	for mat_id in chosen_recipe.needs.keys():
		var need_cnt = int(chosen_recipe.needs[mat_id])
		inventory.remove_item(mat_id, need_cnt)

	# 加入合成结果
	inventory.add_item(chosen_recipe.result_id, 1)

	# 弹成功提示
	get_tree().call_group("UI", "show_popup", "合成“%s”成功！" % chosen_recipe.result_id)

	# 刷新当前页的显示（因为有按钮状态要重新检查）
	_refresh_page()


# -------------------------------------------------------
func _refresh_page() -> void:
	var arr = recipes_by_category.get(current_category, [])
	var total = arr.size()
	max_pages = int(ceil(float(total) / ITEMS_PER_PAGE))
	if max_pages == 0:
		max_pages = 1

	prev_page_btn.disabled = (current_page <= 0)
	next_page_btn.disabled = (current_page >= max_pages - 1)
	page_label.text = "第 %d / %d 页" % [ current_page+1, max_pages ]

	for i in range(ITEMS_PER_PAGE):
		var detail_node = detail_nodes[i] as ItemDetail  # 你的 ItemDetail 类型
		var global_idx = current_page * ITEMS_PER_PAGE + i
		if global_idx < total:
			var recipe_res : CraftRecipe = arr[global_idx]
			# 拿到合成品资源 (只为了 icon 和 name)
			var item_res : Item = inventory.get_item_resource(recipe_res.result_id)
			if item_res == null:
				detail_node.clear_detail()
				detail_node.visible = false
				continue

			# 第一行需要的 icon 和 name
			var icon_tex = item_res.icon
			var item_name = item_res.name

			# 给 ItemDetail 填充数据 —— 里面会自动塞材料列表到 PopupPanel
			detail_node.set_detail(icon_tex, item_name, recipe_res)

			# 如果你想在这儿再额外设置 craft_button 状态也可以：
			var ok = true
			for mat_id in recipe_res.needs.keys():
				var cnt = int(recipe_res.needs[mat_id])
				if not inventory.has_item(mat_id, cnt):
					ok = false
					break
			detail_node.craft_button.disabled = not ok

			detail_node.visible = true
		else:
			detail_node.clear_detail()
			detail_node.visible = false
