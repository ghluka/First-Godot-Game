extends Area3D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(0.4).timeout
		if body in get_overlapping_bodies() and not Input.is_action_pressed("sneak"):
			get_tree().call_deferred("reload_current_scene")
