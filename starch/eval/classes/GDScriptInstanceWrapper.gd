class_name GDScriptInstanceWrapper

var gd_instance: Object
var _method_remap: Dictionary = {}

func _init(instance):
	gd_instance = instance
	
	# Check if the instance has a _methods dictionary for remapping
	if "_methods" in gd_instance:
		_method_remap = gd_instance._methods

func _get(property):
	print("    _GET CALLED FOR: ", property)
	var actual_property = property
	var wrapper_ref = self  # Capture wrapper reference at the start
	
	if _method_remap.has(property):
		var remap_target = _method_remap[property]
		
		if typeof(remap_target) == TYPE_STRING:
			actual_property = remap_target
		elif remap_target is Callable:
			return func(args):
				print("      CALLABLE LAMBDA EXECUTING")
				var result = remap_target.callv(args)
				print("      Result: ", result)
				print("      Result ID: ", result.get_instance_id() if result != null else "null")
				print("      gd_instance ID: ", wrapper_ref.gd_instance.get_instance_id())
				# If result is self (builder pattern), return wrapper
				if result != null and result.get_instance_id() == wrapper_ref.gd_instance.get_instance_id():
					print("      IDs MATCH! Returning wrapper")
					return wrapper_ref
				print("      IDs don't match, returning raw result")
				return result
	
	if gd_instance.has_method(actual_property):
		return func(args):
			var result = gd_instance.callv(actual_property, args)
			if result != null and result.get_instance_id() == wrapper_ref.gd_instance.get_instance_id():
				return wrapper_ref
			return result
	
	if actual_property in gd_instance:
		return gd_instance.get(actual_property)
	
	push_warning("GDScriptInstanceWrapper: Property '%s' not found" % property)
	return null

func _to_string() -> String:
	if gd_instance.has_method("_to_string"):
		return gd_instance._to_string()
	return "<GDScript WRAPPER around %s>" % gd_instance.get_class()

func unwrap():
	return gd_instance
