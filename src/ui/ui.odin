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

font: rl.Font
camera: rl.Camera2D

viewport: rl.Rectangle
viewport_padding: rl.Vector2 = {4.0, 4.0}

init :: proc() {
	font = rl.GetFontDefault()
	camera.zoom = 2.0
}

deinit :: proc() {

}

frame_begin :: proc() {
	WINDOW_WIDTH = cast(f32)rl.GetScreenWidth()
	WINDOW_HEIGHT = cast(f32)rl.GetScreenHeight()

	viewport = rl.Rectangle {
		viewport_padding.x,
		viewport_padding.y,
		WINDOW_WIDTH - viewport_padding.x,
		WINDOW_HEIGHT + viewport_padding.y,
	}

	last_mouse_pos = curr_mouse_pos
	curr_mouse_pos = rl.GetMousePosition()
	mouse_delta = curr_mouse_pos - last_mouse_pos

	rl.BeginDrawing()
	rl.ClearBackground(rl.Color{25, 25, 25, 255})
	rl.BeginMode2D(camera)
}

frame_end :: proc() {
	for &object, index in object_list[0:object_len] {
		pos: rl.Rectangle =  {
			(object.pos.x) * camera.zoom,
			(object.pos.y) * camera.zoom,
			(object.size.x) * camera.zoom,
			(object.size.y) * camera.zoom,
		}

		if rl.CheckCollisionPointRec(curr_mouse_pos, pos) {
			focus_object = &object
		} else if focus_object == &object {
			focus_object = nil
		}

		// TODO: Использовать "Командный шаблон"
		{
			rect: rl.Rectangle

			rect = rl.Rectangle{object.pos.x, object.pos.y, object.size.x, object.size.y}
			rl.DrawRectangleLinesEx(rect, 1.0, rl.BLACK)

			rect = rl.Rectangle {
				object.pos.x + 1,
				object.pos.y + 1,
				object.size.x - 2,
				object.size.y - 2,
			}
			rl.DrawRectangleLinesEx(rect, 1.0, rl.Color{71, 71, 71, 255})

			padding: f32 = 8.0
			font_size: f32 = 16.0
			spacing: f32 = 2.0
			size: rl.Vector2 = rl.MeasureTextEx(font, object.name, font_size, spacing)
			pos: rl.Vector2 =  {
				rect.x + rect.width / 2 - size.x / 2,
				rect.y + rect.height / 2 - size.y / 2,
			}
			rl.DrawTextEx(font, object.name, pos, font_size, spacing, rl.Color{225, 227, 230, 255})
		}
	}

	// Debug
	{
		// Hot Object
		rl.DrawText("HotObject:", 800 - 120, 4, 20, rl.BLACK)
		if hot_object != nil {
			rl.DrawText(hot_object.name, 800, 4, 20, rl.BLACK)
		}

		// Focus Object
		rl.DrawText("FocusObject:", 800 - 120, 24, 20, rl.BLACK)
		if focus_object != nil {
			rl.DrawText(focus_object.name, 824, 24, 20, rl.BLACK)
		}
	}

	rl.EndMode2D()
	rl.EndDrawing()

	object_len = 0
}

window_begin :: proc(name: cstring, rect: rl.Rectangle) -> (open: bool) {
	return
}

window_end :: proc() {

}

button :: proc(name: cstring, size: rl.Vector2 = {100, 30}) -> (res: bool) {
	object := &object_list[object_len]
	object.name = name
	object.size = size

	if cursor_pos.x != 0 || cursor_pos.y != 0 {
		object.pos = cursor_pos
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		if object == focus_object {
			hot_object = object
		}
	} else if rl.IsMouseButtonReleased(.LEFT) {
		if object == focus_object && object == hot_object {
			res = true
			hot_object = nil
		} else if object != focus_object && object == hot_object {
			hot_object = nil
		}
	}

	object_len += 1
	cursor_pos = {}

	return
}

set_cursor_pos :: proc(pos: rl.Vector2) {
	cursor_pos = pos
}
