package live

import "core:fmt"
import rl "vendor:raylib"

import "live:game"

main :: proc() {
  rl.SetTargetFPS(60);
  
	rl.InitWindow(1280, 720, "Live")
  rl.SetWindowState({.WINDOW_RESIZABLE})

	game.start()

	for !rl.WindowShouldClose() {
		game.update()
	}

	game.stop()

	rl.CloseWindow()
}
