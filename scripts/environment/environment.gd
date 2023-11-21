extends Node2D

var grids = [{}, {}]
var cells = {}
var to_check = []
var alive_color: Color
var dead_color = Color(32)
var zoom = 1.0

const ZOOM_STEP = 0.1

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_cell(event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			remove_cell(event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(ZOOM_STEP)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(-ZOOM_STEP)
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			move_camera(event.relative)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		start_stop()
	if event.is_action_pressed("ui_reset"):
		reset()

func place_cell(pos: Vector2):
	pos = mouse_pos_to_cam_pos(pos)
	var grid_pos = get_grid_pos(pos)
	if not cells.has(grid_pos):
		add_new_cell(grid_pos)
		
		
func add_new_cell(grid_pos: Vector2):
	var pos = grid_pos * 32.0
	var cell = $Cell.duplicate()
	cell.position = pos
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[1][grid_pos] = true
	print("Created cell on position " + str(grid_pos))
	
func remove_cell(pos: Vector2):
	var key = get_grid_pos(mouse_pos_to_cam_pos(pos))
	if cells.has(key):
		cells[key].queue_free()
		cells.erase(key)
		grids[1].erase(key)
		print("Removed cell on position " + str(key))
		

func mouse_pos_to_cam_pos(pos):
	return pos + $Camera2D.offset / $Camera2D.zoom - get_viewport_rect().size / 2
	
func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels
	
func start_stop():
	if $GenerationTimer.is_stopped() and cells.size() > 0:
		$GenerationTimer.start()
	else:
		$GenerationTimer.stop()
	
func reset():
	$GenerationTimer.stop()
	for key in cells.keys():
		cells[key].queue_free()
	grids[1].clear()
	cells.clear()

func change_zoom(dz: float):
	zoom = clamp(zoom + dz, 0.1, 8.0)
	$Camera2D.zoom = Vector2(zoom, zoom)

func move_camera(dv: Vector2):
	$Camera2D.offset -= dv
	
func regenerate():
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[0][key]: # Alive
			grids[1][key] = (n == 2 or n == 3)
		else: # Dead
			grids[1][key] = (n == 3)

func update_cells():
	for key in cells.keys():
		cells[key].modulate = alive_color if grids[1][key] else dead_color
	
func get_num_live_cells(pos: Vector2, first_pass = true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var new_pos = pos + Vector2(x, y)
				if grids[0].has(new_pos):
					if grids[0][new_pos]: # If alive
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(new_pos)
	return num_live_cells
	
func add_new_cells():
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
		if n == 3 and not grids[1].has(pos):
			add_new_cell(pos)
	to_check = []

func _on_Timer_timeout():
	grids.reverse()
	grids[1].clear()
	regenerate()
	add_new_cells()
	update_cells()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
