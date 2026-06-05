extends Area3D

func _on_body_entered(body):
	if body.is_in_group("player"):
		await get_tree().create_timer(0.14).timeout
		$RigidBody3D.freeze = false
