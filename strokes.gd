extends MeshInstance3D

@export var hand_left:XRController3D
@export var hand_right:XRController3D

@onready var simple_sketch = SimpleSketch.new()

func _ready():
	simple_sketch.target_mesh = mesh

var prev_hand_left_transform:Transform3D
var prev_hand_right_transform:Transform3D
var prev_hand_left_pressed:bool
var prev_hand_right_pressed:bool
func _process(delta):
	var hand_left_pressed = hand_left.is_button_pressed("trigger_click")
	var hand_right_pressed = hand_right.is_button_pressed("trigger_click")
	
	if hand_left_pressed:
		var from = to_local(prev_hand_left_transform.origin)
		var to = to_local(hand_left.global_transform.origin)
		
		var hand_left_just_pressed = hand_left_pressed && !prev_hand_left_pressed

		simple_sketch.addLine(from, to, .01, .01, Color(1,1,1), Color(1,1,1), hand_left_just_pressed)
	
	if hand_right_pressed:
		var from = to_local(prev_hand_right_transform.origin)
		var to = to_local(hand_right.global_transform.origin)
		
		var hand_right_just_pressed = hand_right_pressed && !prev_hand_right_pressed
		
		simple_sketch.addLine(from, to, .01, .01, Color(0,0,0), Color(0,0,0), hand_right_just_pressed)
	
	prev_hand_left_transform = hand_left.global_transform
	prev_hand_right_transform = hand_right.global_transform
	prev_hand_left_pressed = hand_left_pressed
	prev_hand_right_pressed = hand_right_pressed