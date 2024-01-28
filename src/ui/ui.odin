package ui

import "core:fmt"
import rl "vendor:raylib"

import "live:core"

MAX_OBJECTS :: 1000

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

Object :: struct {
	name:     cstring,
	pos:      rl.Vector2,
	size:     rl.Vector2,
	is_dirty: bool,
}

Frame :: struct {
	using object:    Object,
	child_frames:    [MAX_OBJECTS]^Frame,
	child_frame_len: u32,
}

object_list: [MAX_OBJECTS]Object
object_len: u32

curr_object: ^Object
hot_object: ^Object
focus_object: ^Object

frame_list: [MAX_OBJECTS]Frame
frame_len: u32

is_docking: bool
is_build_docking: bool
docker_list: [MAX_OBJECTS]^Frame
docker_len: u32

total_size: rl.Vector2
last_mouse_pos: rl.Vector2
curr_mouse_pos: rl.Vector2
mouse_delta: rl.Vector2
cursor_pos: rl.Vector2

init :: proc() {
}

deinit :: proc() {

}

begin :: proc() {
	WINDOW_WIDTH = cast(f32)rl.GetScreenWidth()
	WINDOW_HEIGHT = cast(f32)rl.GetScreenHeight()

	last_mouse_pos = curr_mouse_pos
	curr_mouse_pos = rl.GetMousePosition()
	mouse_delta = curr_mouse_pos - last_mouse_pos

	if hot_object != nil {
		hot_object.pos += mouse_delta
	}
}

end :: proc() {
	for &frame, index in frame_list[0:frame_len] {
		rect := rl.Rectangle{frame.pos.x, frame.pos.y, frame.size.x, frame.size.y}
		rl.DrawRectangleV({rect.x, rect.y}, {rect.width, rect.height}, rl.RED)
		rl.DrawRectangleLinesEx(rect, 1.0, rl.BLACK)
		rl.DrawText(
			frame.name,
			cast(i32)(rect.x + rect.width / 2),
			cast(i32)(rect.y + rect.height / 2),
			20,
			rl.BLACK,
		)
	}

	frame_len = 0
}

begin_frame :: proc(name: cstring, size: rl.Vector2 = {100, 100}) {
	if is_docking == true {
		if docker_list[docker_len] == nil {
			frame_list[frame_len] = {
				name = name,
				size = size,
			}
			docker_list[docker_len] = &frame_list[frame_len]
		}
		docker_len += 1
	}

	frame_len += 1
}

end_frame :: proc() {
}

set_cursor_pos :: proc(pos: rl.Vector2) {
	cursor_pos = pos
}

begin_docker :: proc() {
	is_docking = true
}

end_docker :: proc() {
	last_size: rl.Vector2
	last_frame: ^Frame

	for &frame, index in docker_list[0:docker_len] {
		if is_build_docking == false {
			if index == 0 {
				frame.size = {WINDOW_WIDTH / cast(f32)(docker_len), WINDOW_HEIGHT}
			} else {
				frame.pos.x = last_frame.pos.x + last_frame.size.x
				frame.size.x = last_frame.size.x
				frame.size.y = WINDOW_HEIGHT
			}
		}

		if rl.IsMouseButtonDown(.LEFT) {
			if rl.CheckCollisionPointRec(
				   curr_mouse_pos,
				   rl.Rectangle{frame.pos.x, frame.pos.y, frame.size.x, frame.size.y},
			   ) ==
			   true {
				frame.size.x += mouse_delta.x
        // docker_list[index+1].pos.x = frame.size.x
        // docker_list[index+1].size.x = frame.pos.x - frame.size.x
        // docker_list[index+1].pos.x += mouse_delta.x
        // docker_list[index+1].size.x -= mouse_delta.x
				// fmt.printf("Collision\n")
        // is_build_docking = false
			}
		}

		last_size.x += frame.size.x
		last_frame = frame
	}

	is_build_docking = true
	is_docking = false
	docker_len = 0
}
