package ui

import "core:fmt"
import rl "vendor:raylib"

import "live:core"

Element :: struct {
	pos:  core.Vector2,
	size: core.Vector2,
}

Frame :: struct {
	name:              cstring,
	pos:               core.Vector2,
	size:              core.Vector2,
	child_elements:    [1000]^Element,
	child_element_idx: u32,
}

frame_stack: [1000]Frame
curr_frame: ^Frame

frame_points: [1000]^Frame

frame_count: u32
frame_idx: u32

hot_frame: ^Frame
focus_frame: ^Frame

element_stack: [1000]Element
element_count: u32
element_idx: u32

frame_inner_padding: f32 = 4.0
total_size: core.Vector2

last_mouse_pos: core.Vector2
curr_mouse_pos: core.Vector2
mouse_delta: core.Vector2

init :: proc() {
	for i in 0 ..< 1000 {
		frame_points[i] = &frame_stack[i]
	}
}

deinit :: proc() {

}

begin :: proc() {
	last_mouse_pos = curr_mouse_pos
	curr_mouse_pos = rl.GetMousePosition()
	mouse_delta = curr_mouse_pos - last_mouse_pos

	if hot_frame != nil {
		hot_frame.pos += mouse_delta
	}
}

end :: proc() {
	if rl.IsKeyReleased(.SPACE) {
		if frame_points[frame_count - 1] != focus_frame {
			tmp := frame_points[0]
			frame_points[0] = frame_points[1]
			frame_points[1] = tmp
		}
	}

	for &frame, index in frame_points[0:frame_count] {
		if rl.CheckCollisionPointRec(
			   curr_mouse_pos,
			   rl.Rectangle{frame.pos.x, frame.pos.y, frame.size.x, frame.size.y},
		   ) {
			focus_frame = frame
			if rl.IsMouseButtonPressed(.LEFT) {
				hot_frame = frame
			}
		}

		if rl.IsMouseButtonReleased(.LEFT) {
			hot_frame = nil
		}

		rect := rl.Rectangle{frame.pos.x, frame.pos.y, frame.size.x, frame.size.y}

		rl.DrawRectangleV({rect.x, rect.y}, {rect.width, rect.height}, rl.RED)
		rl.DrawRectangleLinesEx(rect, 1.0, rl.BLACK)
		rl.DrawText(frame.name, cast(i32)rect.x, cast(i32)(rect.y + rect.height), 20, rl.BLACK)

		for element, index in frame.child_elements[0:frame.child_element_idx] {
			rect := rl.Rectangle{element.pos.x, element.pos.y, element.size.x, element.size.y}

			rl.DrawRectangleV({rect.x, rect.y}, {rect.width, rect.height}, rl.BLUE)
			rl.DrawRectangleLinesEx(rect, 1.0, rl.BLACK)
		}

		frame.child_element_idx = 0
	}

	if hot_frame != nil {
		rl.DrawText(
			hot_frame.name,
			(1280 / 2) - cast(i32)frame_inner_padding,
			cast(i32)frame_inner_padding,
			20,
			rl.BLACK,
		)
	}

	if frame_points[frame_count - 1] != nil {
		rl.DrawText(
			frame_points[frame_count - 1].name,
			(1280 / 2) - cast(i32)frame_inner_padding,
			cast(i32)(20 + frame_inner_padding),
			20,
			rl.BLACK,
		)
	}

	if focus_frame != nil {
		rl.DrawText(
			focus_frame.name,
			(1280 / 2) - cast(i32)frame_inner_padding,
			cast(i32)(40 + frame_inner_padding),
			20,
			rl.BLACK,
		)
	}

	frame_count = 0
	frame_idx = 0
	element_count = 0
	element_idx = 0
	total_size = {}
}

begin_frame :: proc(name: cstring, pos: core.Vector2 = {}, size: core.Vector2 = {20, 20}) {
	frame := &frame_stack[frame_idx]
	frame.name = name
	// frame.pos = pos + frame_inner_padding
	frame.size = size
	curr_frame = frame
	frame_count += 1
}

end_frame :: proc() {
	curr_frame = nil
	frame_idx += 1
}

button :: proc(name: cstring) {
	if (curr_frame == nil) {
		return
	}

	frame := &frame_stack[frame_idx]
	element := &element_stack[element_idx]

	element.pos = (frame.pos + {0, total_size.y + cast(f32)(2.0 * element_idx)}) + frame_inner_padding
	element.size = core.Vector2{100, 20}

	frame.child_elements[frame.child_element_idx] = element
	frame.child_element_idx += 1

	total_size += element.size

	element_count += 1
	element_idx += 1
}
