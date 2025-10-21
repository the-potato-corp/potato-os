extends Node

func create_timer(duration: float) -> SceneTreeTimer:
	return get_tree().create_timer(duration)

func call_deferred_on_tree(callable: Callable) -> void:
	callable.call_deferred()
