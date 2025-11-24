extends Node2D

@export var from_id : String
@export var to_id : String
@export var capacity : int = 0
var flow : int = 0

func residual():
	return capacity - flow

func push(amount:int):
	flow += amount
	$Label.text = str(residual())
