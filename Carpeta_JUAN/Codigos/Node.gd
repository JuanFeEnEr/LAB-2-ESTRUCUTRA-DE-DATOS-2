extends Node2D

@export var node_id : String

signal node_clicked(id)

func _ready():
	$Area2D.input_pickable = true

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("node_clicked", node_id)
