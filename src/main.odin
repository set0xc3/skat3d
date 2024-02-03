package skat3d

import "core:fmt"
import "core:math/linalg"
import "core:strings"
import "core:unicode/utf8"
import mu "vendor:microui"

import rl "vendor:raylib"

WINDOW_WIDTH: f32
WINDOW_HEIGHT: f32

mu_ctx: ^mu.Context

camera: rl.Camera2D

main :: proc() {
	mu_ctx = new(mu.Context)
	mu.init(mu_ctx)

	mu_ctx.text_width = mu.default_atlas_text_width
	mu_ctx.text_height = mu.default_atlas_text_height

	camera.zoom = 2.0

	rl.SetTargetFPS(60)

	// rl.SetConfigFlags({.WINDOW_HIGHDPI})
	// rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1920, 1080, "Skat3D")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.Color{25, 25, 25, 255})
		rl.BeginMode2D(camera)

		xmouse := i32(rl.GetMouseX()) / i32(camera.zoom)
		ymouse := i32(rl.GetMouseY()) / i32(camera.zoom)


		mu.input_mouse_move(mu_ctx, xmouse, ymouse)
		mu.input_scroll(mu_ctx, i32(rl.GetMouseWheelMoveV().x), i32(rl.GetMouseWheelMoveV().y))

		if rl.IsMouseButtonPressed(.LEFT) {
			mu.input_mouse_down(mu_ctx, xmouse, ymouse, .LEFT)
		}
		if rl.IsMouseButtonReleased(.LEFT) {
			mu.input_mouse_up(mu_ctx, xmouse, ymouse, .LEFT)
		}

		str: [1]rune = rl.GetCharPressed()
		mu.input_text(mu_ctx, utf8.runes_to_string(str[:]))

		// mu.input_key_down(mu_ctx, Key);
		// mu.input_key_up(mu_ctx, Key);

		mu.begin(mu_ctx)
		{
			mu.begin_window(mu_ctx, "Debug", {8, 8, 200, 400})
			mu.button(mu_ctx, "Button1")
			// mu.draw_rect(mu_ctx, mu.Rect{0, 0, 100, 100}, mu.Color{255, 0, 255, 255})
			mu.end_window(mu_ctx)
		}
		mu.end(mu_ctx)

		{
			pcm: ^mu.Command
			for variant in mu.next_command_iterator(mu_ctx, &pcm) {
				switch cmd in variant {
				case ^mu.Command_Jump:
					unreachable()
				case ^mu.Command_Clip:
					rl.EndScissorMode()
					rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
				case ^mu.Command_Rect:
					rect := rl.Rectangle {
						f32(cmd.rect.x),
						f32(cmd.rect.y),
						f32(cmd.rect.w),
						f32(cmd.rect.h),
					}
					color := rl.Color {
						u8(cmd.color.r),
						u8(cmd.color.g),
						u8(cmd.color.b),
						u8(cmd.color.a),
					}
					rl.DrawRectangleRec(rect, color)
				case ^mu.Command_Text:
					pos := rl.Vector2{f32(cmd.pos.x), f32(cmd.pos.y)}
					color := rl.Color {
						u8(cmd.color.r),
						u8(cmd.color.g),
						u8(cmd.color.b),
						u8(cmd.color.a),
					}
					rl.DrawText(
						strings.clone_to_cstring(cmd.str),
						i32(pos.x),
						i32(pos.y),
						10,
						color,
					)
				case ^mu.Command_Icon:
					// ui.DEFAULT_ATLAS_ICON_RESIZE
					rect := rl.Rectangle {
						f32(cmd.rect.x),
						f32(cmd.rect.y),
						f32(cmd.rect.w),
						f32(cmd.rect.h),
					}
					color := rl.Color {
						u8(cmd.color.r),
						u8(cmd.color.g),
						u8(cmd.color.b),
						u8(cmd.color.a),
					}
				// mu.default_atlas_alpha[0]
				}
			}
		}

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
