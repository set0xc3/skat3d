package skat3d

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

import "skat3d:core"
import "skat3d:ui"

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

main :: proc() {
	rl.SetTargetFPS(60)

	// rl.SetConfigFlags({.WINDOW_HIGHDPI})
	// rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1920, 1080, "Skat3D")

	ui.init()

	for !rl.WindowShouldClose() {
		ui.frame_begin()

		if (ui.window_begin("Window 1", {0, 0, 140, 60})) {
		  ui.window_end()
		}

		// ui.set_cursor_pos({4, 4})
		// if ui.button("New") {
		// 	fmt.println("New")
		// }
		// ui.set_cursor_pos({4, 44})
		// if ui.button("Load") {
		// 	fmt.println("Load")
		// }
		// ui.set_cursor_pos({4, 84})
		// if ui.button("Quit") {
		// 	fmt.println("Quit")
		// }

		ui.frame_end()
	}

	rl.CloseWindow()
}
