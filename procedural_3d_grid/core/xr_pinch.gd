# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# xr_pinch.gd
# SPDX-License-Identifier: MIT

extends Node3D

@export var hand_left: XRController3D = null
@export var hand_right: XRController3D = null

var prev_hand_left_transform: Transform3D
var prev_hand_right_transform: Transform3D
var prev_hand_left_grab: float = 0
var prev_hand_right_grab: float = 0

var _world_grab = WorldGrab.new()

var from_pivot : Vector3
var to_pivot : Vector3
var grab_pivot : Vector3
var delta_transform: Transform3D
var target_transform: Transform3D = transform

var damping: float = 6.0
const max_pinch_time: float = 0.1 # sensitivity?

enum Mode {
	NONE, # One handed grab
	GRAB, # One handed grab
	PINCH, # Two handed grab
	ORBIT, # Like spinning a globe
}
var state: Mode = Mode.NONE

var left_hand_just_grabbed := BoolTimer.new()
var right_hand_just_grabbed := BoolTimer.new()
var left_hand_just_ungrabbed := BoolTimer.new()
var right_hand_just_ungrabbed := BoolTimer.new()

func _process(_delta: float) -> void:
	var hand_left_grab: float = hand_left.get_float("grip")
	var hand_right_grab: float = hand_right.get_float("grip")
	
	# Dampening
	delta_transform = delta_transform.interpolate_with(Transform3D(), damping * _delta)

	if hand_left_grab and not prev_hand_left_grab: left_hand_just_grabbed.set_true(max_pinch_time)
	if hand_right_grab and not prev_hand_right_grab: right_hand_just_grabbed.set_true(max_pinch_time)
	
	if not hand_left_grab and prev_hand_left_grab: left_hand_just_ungrabbed.set_true(max_pinch_time)
	if not hand_right_grab and prev_hand_right_grab: right_hand_just_ungrabbed.set_true(max_pinch_time)
	
	#var allow_grab: bool = left_hand_just_grabbed.value and right_hand_just_grabbed.value
	var allow_ungrab: bool = left_hand_just_ungrabbed.value and right_hand_just_ungrabbed.value
	
	# Always ctivate pinching if both hands are grabbing within max_pinch_timer
	if left_hand_just_grabbed.value and right_hand_just_grabbed.value: state = Mode.PINCH
	
	# Always return to no grab if no hands are grabbing
	if not (hand_left_grab or hand_right_grab): state = Mode.NONE
	
	match state:
		Mode.NONE:
			if not left_hand_just_grabbed.value && hand_left_grab:
				state = Mode.GRAB
			elif not right_hand_just_grabbed.value && hand_right_grab:
				state = Mode.GRAB
			
		Mode.GRAB:
			if hand_left_grab and hand_right_grab:
				state = Mode.ORBIT
			
			if hand_left_grab:
				from_pivot = prev_hand_left_transform.origin
				to_pivot = prev_hand_left_transform.origin
				
				delta_transform = _world_grab.get_grab_transform(prev_hand_left_transform, hand_left.transform)
			
			if hand_right_grab:
				from_pivot = prev_hand_right_transform.origin
				to_pivot = prev_hand_right_transform.origin
				
				delta_transform = _world_grab.get_grab_transform(prev_hand_right_transform, hand_right.transform)
			
		Mode.PINCH:
			if not (hand_left_grab and hand_right_grab) and allow_ungrab:
				state = Mode.GRAB
			
			from_pivot = (prev_hand_left_transform.origin + prev_hand_right_transform.origin)/2.0
			to_pivot = (hand_left.transform.origin + hand_right.transform.origin)/2.0
			
			delta_transform = _world_grab.get_pinch_transform(prev_hand_left_transform.origin, prev_hand_right_transform.origin, hand_left.transform.origin, hand_right.transform.origin)
			
		Mode.ORBIT:
			if not (hand_left_grab and hand_right_grab):
				state = Mode.GRAB
			
			from_pivot = prev_hand_left_transform.origin
			to_pivot = prev_hand_right_transform.origin
			
			delta_transform = _world_grab.get_orbit_transform(prev_hand_left_transform.origin, prev_hand_right_transform.origin, hand_left.transform.origin, hand_right.transform.origin)

	delta_transform = delta_transform.interpolate_with(Transform3D(), 0.5)

	# Integrate motion
	target_transform = delta_transform * target_transform
	
	# Smoothing
	transform = _world_grab.split_blend(transform, target_transform, .3, .1, .1, transform * target_transform.affine_inverse() * to_pivot, to_pivot)
	
	# Pass data required for the next frame
	prev_hand_left_transform = hand_left.transform
	prev_hand_right_transform = hand_right.transform
	prev_hand_left_grab = hand_left_grab
	prev_hand_right_grab = hand_right_grab

'''delta_transform = delta_transform.interpolate_with(Transform3D(), _delta*2.0)
	if hand_left_pressed && hand_right_pressed && both_hands_just_pressed.value:
		from_pivot = (prev_hand_left_transform.origin + prev_hand_right_transform.origin)/2.0
		to_pivot = (hand_left.transform.origin + hand_right.transform.origin)/2.0
		
		delta_transform = _world_grab.get_pinch_transform(prev_hand_left_transform.origin, prev_hand_right_transform.origin, hand_left.transform.origin, hand_right.transform.origin)

	elif hand_left_pressed:
		from_pivot = prev_hand_left_transform.origin
		to_pivot = hand_left.transform.origin
		
		delta_transform = _world_grab.get_grab_transform(prev_hand_left_transform, hand_left.transform)
		
		if not prev_hand_left_pressed: both_hands_just_pressed.set_true(max_pinch_time)
	elif hand_right_pressed:
		from_pivot = prev_hand_right_transform.origin
		to_pivot = hand_right.transform.origin
		
		delta_transform = _world_grab.get_grab_transform(prev_hand_right_transform, hand_right.transform)
		
		if not prev_hand_right_pressed: both_hands_just_pressed.set_true(max_pinch_time)
	else:
		#from_pivot = Vector3()
		#to_pivot = Vector3()
		#delta_transform = Transform3D()
		pass

	target_transform = delta_transform * target_transform
	
	grab_pivot = target_transform.affine_inverse() * to_pivot
	transform = _world_grab.split_blend(transform, target_transform, .3, .1, .1, transform * target_transform.affine_inverse() * to_pivot, to_pivot)
	#transform = target_transform'''
