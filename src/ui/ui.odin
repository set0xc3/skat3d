package ui

import "core:fmt"
import rl "vendor:raylib"

import "skat3d:core"

COMMAND_LIST_SIZE :: 1000
LAYOUT_LIST_SIZE :: 1000

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

Command_Rect :: struct {
	using command: Command,
	rect:          rl.Rectangle,
	color:         rl.Color,
}

Command_Variant :: union {
	^Command_Rect,
}

Command :: struct {
	variant: Command_Variant,
	size:    u32,
}

Layout :: struct {
	name:          cstring,
	rect:          rl.Rectangle,
	command_stack: [COMMAND_LIST_SIZE]^Command,
	command_len:   u32,
}

hot_id: ^Command
focus_id: ^Command

command_stack: [COMMAND_LIST_SIZE]Command
command_len: u32

layout_stack: [LAYOUT_LIST_SIZE]Layout
layout_len: u32

frame: u32

last_mouse_pos: rl.Vector2
curr_mouse_pos: rl.Vector2
mouse_delta: rl.Vector2
cursor_pos: rl.Vector2

mouse_button_down: bool
mouse_button_released: bool
mouse_button_pressed: bool

font: rl.Font
camera: rl.Camera2D

get_layout :: proc() -> ^Layout {
	return &layout_stack[layout_len - 1]
}

init :: proc() {
	font = rl.GetFontDefault()
	camera.zoom = 2.0
}

deinit :: proc() {

}

frame_begin :: proc() {
	WINDOW_WIDTH = cast(f32)rl.GetScreenWidth()
	WINDOW_HEIGHT = cast(f32)rl.GetScreenHeight()

	frame += 1

	last_mouse_pos = curr_mouse_pos
	curr_mouse_pos = rl.GetMousePosition()
	mouse_delta = curr_mouse_pos - last_mouse_pos

	rl.BeginDrawing()
	rl.ClearBackground(rl.Color{25, 25, 25, 255})
	rl.BeginMode2D(camera)
}

frame_end :: proc() {
	rl.EndMode2D()
	rl.EndDrawing()
}

window_begin :: proc(name: cstring, rect: rl.Rectangle) -> (open: bool) {
	return
}

window_end :: proc() {

}

button :: proc(name: cstring, size: rl.Vector2 = {100, 30}) -> (res: bool) {
	return
}

set_cursor_pos :: proc(pos: rl.Vector2) {
	cursor_pos = pos
}
