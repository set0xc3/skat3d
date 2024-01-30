package skat3d

import "core:fmt"
import "core:math/linalg"

import rl "vendor:raylib"

import "skat3d:core"
import "skat3d:ui"

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

camera: rl.Camera2D

main :: proc() {
	rl.SetTargetFPS(60)

	rl.InitWindow(1280, 720, "Skat3D")
	rl.SetWindowState({.WINDOW_RESIZABLE})

	WINDOW_WIDTH = cast(f32)rl.GetScreenWidth()
	WINDOW_HEIGHT = cast(f32)rl.GetScreenHeight()

	camera.zoom = 1.0

	ui.init()

	for !rl.WindowShouldClose() {
		WINDOW_WIDTH = cast(f32)rl.GetScreenWidth()
		WINDOW_HEIGHT = cast(f32)rl.GetScreenHeight()

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		rl.BeginMode2D(camera)

		ui.begin()

		ui.set_cursor_pos({0, 0})
		if ui.button("New") {
			fmt.println("New")
		}

		ui.set_cursor_pos({20, 20})
		if ui.button("Load") {
			fmt.println("Load")
		}

		ui.set_cursor_pos({40, 40})
		if ui.button("Quit") {
			fmt.println("Quit")
			rl.CloseWindow()
		}

		ui.end()

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
