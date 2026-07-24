# slash_effect.gd
extends AnimatedSprite2D


func _ready() -> void:
	play("SwordSlice")
	# Automatically destroy this node when the animation finishes
	animation_finished.connect(queue_free)
