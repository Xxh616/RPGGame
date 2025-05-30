# res://scenes/item_drop.gd
extends Node2D
class_name ItemDrop
signal player_entered(drop)
signal player_exited(drop)

@onready var inventory = inventory_autoload
@export  var item_id   : String
@export  var count     : int = 1
@onready var icon      = $Icon       as Sprite2D
@onready var name_lbl  = $NameLabel  as Label
@onready var trigger   = $Area2D     as Area2D


func _ready():
	var itm = inventory.get_item_resource(item_id)
	icon.texture     = itm.icon
	name_lbl.text    = itm.name
	name_lbl.visible = false
	trigger.connect("body_entered", Callable(self, "_on_body_entered"))
	trigger.connect("body_exited",  Callable(self, "_on_body_exited"))
	
func _on_body_entered(body):
	if body.name=="player":
		emit_signal("player_entered", self)
		

func _on_body_exited(body):
	if body.name=="player":
		emit_signal("player_exited", self)
func show_label(visible: bool) -> void:
	name_lbl.visible = visible

func pickup():
	inventory.add_item_by_id(item_id, count)
	queue_free()
