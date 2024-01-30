package ui

import "core:fmt"
import rl "vendor:raylib"

import "skat3d:core"

MAX_OBJECTS :: 1000

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

Object :: struct {
	name:     cstring,
	pos:      rl.Vector2,
	size:     rl.Vector2,
	is_dirty: bool,
	idx:      u32,
}

hot_object: ^Object
focus_object: ^Object

object_list: [MAX_OBJECTS]Object
object_len: u32

last_mouse_pos: rl.Vector2
curr_mouse_pos: rl.Vector2
mouse_delta: rl.Vector2
cursor_pos: rl.Vector2

mouse_button_down: bool
mouse_button_released: bool
mouse_button_pressed: bool

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
}

end :: proc() {
	for &object, index in object_list[0:object_len] {
		if rl.CheckCollisionPointRec(
			   curr_mouse_pos,
			   {object.pos.x, object.pos.y, object.size.x, object.size.y},
		   ) {
			focus_object = &object
		} else if focus_object == &object {
			focus_object = nil
		}

		rect := rl.Rectangle{object.pos.x, object.pos.y, object.size.x, object.size.y}
		if hot_object == &object {
			rl.DrawRectangleV({rect.x, rect.y}, {rect.width, rect.height}, {0, 128, 48, 255})
		} else {
			rl.DrawRectangleV({rect.x, rect.y}, {rect.width, rect.height}, {0, 228, 48, 255})
		}

		rl.DrawRectangleLinesEx(rect, 1.0, rl.BLACK)
		rl.DrawText(object.name, cast(i32)rect.x, cast(i32)rect.y, 20, rl.BLACK)
	}

	// Hot Object
	{
		rl.DrawText("HotObject:", 800 - 120, 4, 20, rl.BLACK)
		if hot_object != nil {
			rl.DrawText(hot_object.name, 800, 4, 20, rl.BLACK)
		}
	}

	// Focus Object
	{
		rl.DrawText("FocusObject:", 800 - 120, 24, 20, rl.BLACK)
		if focus_object != nil {
			rl.DrawText(focus_object.name, 824, 24, 20, rl.BLACK)
		}
	}

	object_len = 0
}

button :: proc(name: cstring, size: rl.Vector2 = {100, 30}) -> (res: bool) {
	object := &object_list[object_len]
	object.idx = object_len
	object.name = name
	object.size = size

	if cursor_pos.x != 0 || cursor_pos.y != 0 {
		object.pos = cursor_pos
	}

	// Only set hot_object if the left mouse button is pressed and the cursor is over the current object
	if rl.IsMouseButtonPressed(.LEFT) {
		if rl.CheckCollisionPointRec(
			   curr_mouse_pos,
			   {object.pos.x, object.pos.y, object.size.x, object.size.y},
		   ) {
			hot_object = object
		}
	}

	// Process button press only if hot_object matches the current object
	if hot_object == object && rl.IsMouseButtonReleased(.LEFT) {
		if focus_object == object &&
		   rl.CheckCollisionPointRec(
			   curr_mouse_pos,
			   {object.pos.x, object.pos.y, object.size.x, object.size.y},
		   ) {
			res = true
		}
		hot_object = nil
	}

	object_len += 1
	cursor_pos = {}
	return
}

set_cursor_pos :: proc(pos: rl.Vector2) {
	cursor_pos = pos
}
