# res://scenes/item_drop.gd
extends Node2D
class_name ItemDrop
signal player_entered(drop)
signal player_exited(drop)

# Reference to the global Inventory singleton
@onready var inventory = inventory_autoload
# The ID of the item to drop
@export var item_id   : String
# Number of items in this drop
@export var count     : int = 1
# Sprite node to display the item icon
@onready var icon      = $Icon       as Sprite2D
# Label node to display the item name
@onready var name_lbl  = $NameLabel  as Label
# Area2D node used as the pickup trigger area
@onready var trigger   = $Area2D     as Area2D

func _ready():
	# Load the item resource from the inventory using its ID
	var itm = inventory.get_item_resource(item_id)
	# Set the icon texture and name text
	icon.texture     = itm.icon
	name_lbl.text    = itm.name
	# Hide the name label by default
	name_lbl.visible = false
	# Connect signals for when the player enters or exits the trigger area
	trigger.connect("body_entered", Callable(self, "_on_body_entered"))
	trigger.connect("body_exited",  Callable(self, "_on_body_exited"))

# Called when any physics body enters the trigger area
func _on_body_entered(body):
	# If the body is the player, emit player_entered signal
	if body.name == "player":
		emit_signal("player_entered", self)

# Called when any physics body exits the trigger area
func _on_body_exited(body):
	# If the body is the player, emit player_exited signal
	if body.name == "player":
		emit_signal("player_exited", self)

# Show or hide the item name label
func show_label(visible: bool) -> void:
	name_lbl.visible = visible

# Pick up the item: add it to the inventory and remove this node
func pickup():
	inventory.add_item_by_id(item_id, count)
	queue_free()
