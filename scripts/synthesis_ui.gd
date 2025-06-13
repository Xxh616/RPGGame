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
	# 1) Load all .tres recipe resources under the recipes directory
	_load_all_recipes()
	# 2) Connect pagination buttons
	prev_page_btn.connect("pressed", Callable(self, "_on_PrevPage_pressed"))
	next_page_btn.connect("pressed", Callable(self, "_on_NextPage_pressed"))
	# Debug-print detail_nodes
	for i in range(detail_nodes.size()):
		var dn = detail_nodes[i]
		print(">>> detail_nodes[", i, "] = ", dn)
	# 3) Connect each ItemDetail's craft_requested signal
	for dn in detail_nodes:
		dn.connect("craft_requested", Callable(self, "_on_DetailCraft_requested"))
	# 4) Category buttons are already connected in the editor, so just implement callbacks
	# 5) Default to showing Weapon, page 1
	_select_category("Weapon")
	_refresh_page()

func _process(delta: float) -> void:
	pass

# -------------------------------------------------------
func _load_all_recipes() -> void:
	var base_dir = DirAccess.open(recipes_base_path)
	if base_dir == null:
		push_error("Recipes root directory not found: " + recipes_base_path)
		return

	base_dir.list_dir_begin()
	var subdir_name = base_dir.get_next()
	while subdir_name != "":
		if subdir_name.begins_with("."):
			subdir_name = base_dir.get_next()
			continue

		var full_subdir = recipes_base_path + "/" + subdir_name
		var sub_da = DirAccess.open(full_subdir)
		# Treat any openable folder as a category to scan for .tres files
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
		# Load only .tres resource files
		if fname.to_lower().ends_with(".tres"):
			var full_path = dir_path + "/" + fname
			var r = ResourceLoader.load(full_path)
			if r and r is CraftRecipe:
				recipes_by_category[category_name].append(r)
			else:
				push_warning("%s is not a CraftRecipe resource" % full_path)
		fname = da.get_next()
	da.list_dir_end()

# -------------------------------------------------------
func _select_category(cat: String) -> void:
	if current_category == cat:
		return
	current_category = cat
	current_page = 0
	_refresh_page()

# Category button callbacks
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
# Called when an ItemDetail line's craft button is pressed
func _on_DetailCraft_requested(recipe_idx: int) -> void:
	var chosen_recipe: CraftRecipe = null
	# Find the CraftRecipe instance matching the instance_id
	for cat_name in recipes_by_category.keys():
		for r in recipes_by_category[cat_name]:
			if r.get_instance_id() == recipe_idx:
				chosen_recipe = r
				break
		if chosen_recipe:
			break

	if chosen_recipe == null:
		push_warning("Cannot find CraftRecipe with index %d" % recipe_idx)
		return

	# Check if player has enough materials
	var can_craft = true
	for mat_id in chosen_recipe.needs.keys():
		var need_cnt = int(chosen_recipe.needs[mat_id])
		if not inventory.has_item(mat_id, need_cnt):
			can_craft = false
			break
	if not can_craft:
		get_tree().call_group("UI", "show_popup", "Not enough materials to craft!")
		return

	# Deduct materials
	for mat_id in chosen_recipe.needs.keys():
		var need_cnt = int(chosen_recipe.needs[mat_id])
		inventory.remove_item(mat_id, need_cnt)

	# Add crafted result
	inventory.add_item(chosen_recipe.result_id, 1)

	# Show success popup
	get_tree().call_group("UI", "show_popup", "Crafted “%s” successfully!" % chosen_recipe.result_id)

	# Refresh the page to update button states
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
	page_label.text = " %d / %d " % [ current_page+1, max_pages ]

	for i in range(ITEMS_PER_PAGE):
		var detail_node = detail_nodes[i] as ItemDetail
		var global_idx = current_page * ITEMS_PER_PAGE + i
		if global_idx < total:
			var recipe_res : CraftRecipe = arr[global_idx]
			# Get the result item's resource for icon and name
			var item_res : Item = inventory.get_item_resource(recipe_res.result_id)
			if item_res == null:
				detail_node.clear_detail()
				detail_node.visible = false
				continue

			# Prepare icon and name for this recipe
			var icon_tex = item_res.icon
			var item_name = item_res.name

			# Populate the ItemDetail control (it handles material popup internally)
			detail_node.set_detail(icon_tex, item_name, recipe_res)

			# Optionally manually set craft_button state here:
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


func _on_close_button_pressed() -> void:
	hide()
	
