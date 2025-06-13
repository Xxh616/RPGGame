# res://scripts/ItemDetail.gd
extends MarginContainer
class_name ItemDetail
signal craft_requested(recipe_id: int)

var bound_recipe_id      : int = -1
var bound_recipe_needs   : Dictionary = {}
# onready locate various controls
@onready var icon_texture    = $HBoxContainer/MarginContainer/Icon           as TextureRect
@onready var name_label      = $HBoxContainer/MarginContainer2/NamePathVBox/NameMargin/Label as Label
@onready var summary_label   = $HBoxContainer/MarginContainer2/NamePathVBox/PathMargin/HBoxContainer/Label as Label
@onready var arrow_button    = $HBoxContainer/MarginContainer2/NamePathVBox/PathMargin/HBoxContainer/Button as Button
@onready var craft_button    = $HBoxContainer/MarginContainer3/Button         as Button
@onready var inventory       = inventory_autoload
@onready var materials_popup = $MaterialsPopup                                 as PopupPanel
@onready var content_vbox    = $MaterialsPopup/PanelContainer/VBoxContainer    as VBoxContainer

# The CraftRecipe currently bound to this detail line
var bound_recipe : CraftRecipe = null

func _ready() -> void:
	# Connect arrow button to toggle materials list
	arrow_button.connect("pressed", Callable(self, "_on_arrow_pressed"))
	# Connect craft button to emit craft_requested signal
	craft_button.connect("pressed", Callable(self, "_on_craft_pressed"))
	# Initially clear all detail fields
	clear_detail()

# Used by SynthesisUI to set icon, name, and recipe details
func set_detail(_icon: Texture2D, _name: String, _recipe: CraftRecipe) -> void:
	print(">> ItemDetail.set_detail() called, recipe_id=", _recipe.get_instance_id())
	bound_recipe = _recipe
	bound_recipe_id = _recipe.get_instance_id()
	bound_recipe_needs = _recipe.needs.duplicate()

	# Display icon and name
	icon_texture.texture = _icon
	name_label.text = _name

	# Clear previous PopupPanel children
	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()

	# Get materials dictionary (material_id -> quantity)
	var needs = bound_recipe.needs
	var material_count = needs.keys().size()
	summary_label.text = "Materials list (%d items)" % material_count

	# Show or hide arrow button based on material count
	arrow_button.visible = material_count > 0

	# Populate PopupPanel with material labels
	var inv = inventory_autoload
	for mat_id in needs.keys():
		var cnt = int(needs[mat_id])
		var mat_res : Item = inv.get_item_resource(mat_id)
		var mat_name : String =mat_res.name if  mat_res != null else str(mat_id)
		var lab = Label.new()
		lab.text = "%s × %d" % [mat_name, cnt]
		content_vbox.add_child(lab)

	# Hide the materials popup initially
	materials_popup.hide()

	# Enable or disable craft button based on inventory availability
	var can_craft = true
	for mat_id in needs.keys():
		var cnt = int(needs[mat_id])
		if not inv.has_item(mat_id, cnt):
			can_craft = false
			break
	craft_button.disabled = not can_craft

# Clear all detail fields, hide arrow and disable craft button
func clear_detail() -> void:
	bound_recipe = null
	icon_texture.texture = null
	name_label.text = ""
	summary_label.text = ""
	arrow_button.visible = false
	craft_button.disabled = true

	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()
	materials_popup.hide()

# Toggle the materials popup when arrow button is pressed
func _on_arrow_pressed() -> void:
	print("▶▶▶ _on_arrow_pressed() triggered, bound_recipe_id=", bound_recipe_id)
	if bound_recipe_id == -1:
		return

	if materials_popup.visible:
		materials_popup.hide()
		return

	# Remove leftover labels
	for child in content_vbox.get_children():
		content_vbox.remove_child(child)
		child.queue_free()

	# Create labels for each material
	for mat_id in bound_recipe_needs.keys():
		var cnt = int(bound_recipe_needs[mat_id])
		var mat_res : Item = inventory.get_item_resource(mat_id)
		var mat_name : String =mat_res.name if  mat_res != null  else str(mat_id)
		var lab = Label.new()
		lab.text = "%s × %d" % [mat_name, cnt]
		content_vbox.add_child(lab)

	# Calculate popup position below this control
	var rect = get_global_rect()
	var popup_pos = Vector2(rect.position.x, rect.position.y + rect.size.y + 5)
	materials_popup.popup(Rect2(popup_pos, Vector2.ZERO))

	# TODO: Change arrow icon to indicate collapse next time

# Emit craft_requested signal when craft button is pressed
func _on_craft_pressed() -> void:
	if bound_recipe:
		emit_signal("craft_requested", bound_recipe.get_instance_id())
