# res://scripts/EquipSlot.gd
extends ItemSlot
class_name EquipSlot

# 玩家点击装备槽时发出：参数是槽位索引 和 当前物品 ID（"" 表示脱装）
signal equip_changed(slot_index: int, item_id: String)

func _ready() -> void:
	# 调用父类 _ready()，以便初始化鼠标监听
	super._ready()
	# 绑定自己的 slot_clicked 信号
	connect("slot_clicked", Callable(self, "_on_slot_clicked"))

func _on_slot_clicked(clicked_index: int) -> void:
	# 点击后发出 equip_changed，传递当前存的 item_id
	# ItemSlot 已在 set_item() 里把 self.item_id 设值
	emit_signal("equip_changed", slot_index, item_id)
