package skat3d

import "core:fmt"
import "core:unicode/utf8"
import "ui"
import rl "vendor:raylib"

state := struct {
	ui_ctx:          ui.Context,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              ui.Color,
	atlas_texture:   rl.Texture2D,
	camera:          rl.Camera2D,
} {
	bg = {90, 95, 100, 255},
}

ui_button :: proc(
	ctx: ^ui.Context,
	label: string,
	icon: ui.Icon = .NONE,
	opt: ui.Options = {.ALIGN_CENTER},
) -> (
	res: ui.Result_Set,
) {
	id := len(label) > 0 ? ui.get_id(ctx, label) : ui.get_id(ctx, uintptr(icon))
	r := ui.layout_next(ctx)
	ui.update_control(ctx, id, r, opt)
	/* handle click */
	if ctx.mouse_pressed_bits == {.LEFT} && ctx.focus_id == id {
		res += {.SUBMIT}
	}
	/* draw */
	ui.draw_box(ctx, ui.expand_rect(r, 1), ui.Color{0, 0, 0, 255})
	ui.draw_box(ctx, ui.expand_rect(r, 0), ui.Color{71, 71, 71, 255})

	if len(label) > 0 {
		ui.draw_control_text(ctx, label, r, .TEXT, opt)
	}
	if icon != .NONE {
		ui.draw_icon(ctx, icon, r, ctx.style.colors[.TEXT])
	}
	return
}

main :: proc() {
	state.camera.zoom = 1.0

	rl.SetConfigFlags({.WINDOW_RESIZABLE} | {.WINDOW_HIGHDPI})
	rl.InitWindow(1920, 1080, "Skat3D")
	defer rl.CloseWindow()

	pixels := make([][4]u8, ui.DEFAULT_ATLAS_WIDTH * ui.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in ui.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	defer delete(pixels)

	image := rl.Image {
		data    = raw_data(pixels),
		width   = ui.DEFAULT_ATLAS_WIDTH,
		height  = ui.DEFAULT_ATLAS_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	state.atlas_texture = rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(state.atlas_texture)

	ctx := &state.ui_ctx
	ui.init(ctx)

	ctx.text_width = ui.default_atlas_text_width
	ctx.text_height = ui.default_atlas_text_height

	rl.SetTargetFPS(60)
	main_loop: for !rl.WindowShouldClose() {
		{ 	// text input
			text_input: [512]byte = ---
			text_input_offset := 0
			for text_input_offset < len(text_input) {
				ch := rl.GetCharPressed()
				if ch == 0 {
					break
				}
				b, w := utf8.encode_rune(ch)
				copy(text_input[text_input_offset:], b[:w])
				text_input_offset += w
			}
			ui.input_text(ctx, string(text_input[:text_input_offset]))
		}

		// mouse coordinates
		mouse_pos := [2]i32 {
			rl.GetMouseX() / i32(state.camera.zoom),
			rl.GetMouseY() / i32(state.camera.zoom),
		}
		ui.input_mouse_move(ctx, mouse_pos.x, mouse_pos.y)
		ui.input_scroll(ctx, 0, i32(rl.GetMouseWheelMove() * -30))

		// mouse buttons
		@(static)
		buttons_to_key := [?]struct {
			rl_button: rl.MouseButton,
			ui_button: ui.Mouse,
		}{{.LEFT, .LEFT}, {.RIGHT, .RIGHT}, {.MIDDLE, .MIDDLE}}
		for button in buttons_to_key {
			if rl.IsMouseButtonPressed(button.rl_button) {
				ui.input_mouse_down(ctx, mouse_pos.x, mouse_pos.y, button.ui_button)
			} else if rl.IsMouseButtonReleased(button.rl_button) {
				ui.input_mouse_up(ctx, mouse_pos.x, mouse_pos.y, button.ui_button)
			}

		}

		// keyboard
		@(static)
		keys_to_check := [?]struct {
			rl_key: rl.KeyboardKey,
			ui_key: ui.Key,
		} {
			{.LEFT_SHIFT, .SHIFT},
			{.RIGHT_SHIFT, .SHIFT},
			{.LEFT_CONTROL, .CTRL},
			{.RIGHT_CONTROL, .CTRL},
			{.LEFT_ALT, .ALT},
			{.RIGHT_ALT, .ALT},
			{.ENTER, .RETURN},
			{.KP_ENTER, .RETURN},
			{.BACKSPACE, .BACKSPACE},
		}
		for key in keys_to_check {
			if rl.IsKeyPressed(key.rl_key) {
				ui.input_key_down(ctx, key.ui_key)
			} else if rl.IsKeyReleased(key.rl_key) {
				ui.input_key_up(ctx, key.ui_key)
			}
		}

		ui.begin(ctx)
		all_windows(ctx)
		ui.end(ctx)

		render(ctx)
	}
}

render :: proc(ctx: ^ui.Context) {
	render_texture :: proc(rect: ui.Rect, pos: [2]i32, color: ui.Color) {
		source := rl.Rectangle{f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h)}
		position := rl.Vector2{f32(pos.x), f32(pos.y)}

		rl.DrawTextureRec(state.atlas_texture, source, position, transmute(rl.Color)color)
	}

	rl.ClearBackground(transmute(rl.Color)state.bg)

	rl.BeginDrawing()
	rl.BeginMode2D(state.camera)
	defer rl.EndMode2D()
	defer rl.EndDrawing()

	rl.BeginScissorMode(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.EndScissorMode()

	command_backing: ^ui.Command
	for variant in ui.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^ui.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := ui.default_atlas[ui.DEFAULT_ATLAS_FONT + r]
				render_texture(rect, pos, cmd.color)
				pos.x += rect.w
			}
		case ^ui.Command_Rect:
			rl.DrawRectangle(
				cmd.rect.x,
				cmd.rect.y,
				cmd.rect.w,
				cmd.rect.h,
				transmute(rl.Color)cmd.color,
			)
		case ^ui.Command_Icon:
			rect := ui.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w) / 2
			y := cmd.rect.y + (cmd.rect.h - rect.h) / 2
			render_texture(rect, {x, y}, cmd.color)
		case ^ui.Command_Clip:
			rl.EndScissorMode()
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
		case ^ui.Command_Jump:
			unreachable()
		}
	}
}


u8_slider :: proc(ctx: ^ui.Context, val: ^u8, lo, hi: u8) -> (res: ui.Result_Set) {
	ui.push_id(ctx, uintptr(val))

	@(static)
	tmp: ui.Real
	tmp = ui.Real(val^)
	res = ui.slider(ctx, &tmp, ui.Real(lo), ui.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	ui.pop_id(ctx)
	return
}

write_log :: proc(str: string) {
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], str)
	state.log_buf_len += copy(state.log_buf[state.log_buf_len:], "\n")
	state.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(state.log_buf[:state.log_buf_len])
}
reset_log :: proc() {
	state.log_buf_updated = true
	state.log_buf_len = 0
}


all_windows :: proc(ctx: ^ui.Context) {
	@(static)
	opts := ui.Options{.NO_CLOSE}

	if ui.window(ctx, "Demo Window", {40, 40, 300, 450}, opts) {
		ui_button(ctx, "MyButton")

		if .ACTIVE in ui.header(ctx, "Window Info") {
			win := ui.get_current_container(ctx)
			ui.layout_row(ctx, {54, -1}, 0)
			ui.label(ctx, "Position:")
			ui.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			ui.label(ctx, "Size:")
			ui.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}

		if .ACTIVE in ui.header(ctx, "Window Options") {
			ui.layout_row(ctx, {120, 120, 120}, 0)
			for opt in ui.Opt {
				state := opt in opts
				if .CHANGE in ui.checkbox(ctx, fmt.tprintf("%v", opt), &state) {
					if state {
						opts += {opt}
					} else {
						opts -= {opt}
					}
				}
			}
		}

		if .ACTIVE in ui.header(ctx, "Test Buttons", {.EXPANDED}) {
			ui.layout_row(ctx, {86, -110, -1})
			ui.label(ctx, "Test buttons 1:")
			if .SUBMIT in ui.button(ctx, "Button 1") {write_log("Pressed button 1")}
			if .SUBMIT in ui.button(ctx, "Button 2") {write_log("Pressed button 2")}
			ui.label(ctx, "Test buttons 2:")
			if .SUBMIT in ui.button(ctx, "Button 3") {write_log("Pressed button 3")}
			if .SUBMIT in ui.button(ctx, "Button 4") {write_log("Pressed button 4")}
		}

		if .ACTIVE in ui.header(ctx, "Tree and Text", {.EXPANDED}) {
			ui.layout_row(ctx, {140, -1})
			ui.layout_begin_column(ctx)
			if .ACTIVE in ui.treenode(ctx, "Test 1") {
				if .ACTIVE in ui.treenode(ctx, "Test 1a") {
					ui.label(ctx, "Hello")
					ui.label(ctx, "world")
				}
				if .ACTIVE in ui.treenode(ctx, "Test 1b") {
					if .SUBMIT in ui.button(ctx, "Button 1") {write_log("Pressed button 1")}
					if .SUBMIT in ui.button(ctx, "Button 2") {write_log("Pressed button 2")}
				}
			}
			if .ACTIVE in ui.treenode(ctx, "Test 2") {
				ui.layout_row(ctx, {53, 53})
				if .SUBMIT in ui.button(ctx, "Button 3") {write_log("Pressed button 3")}
				if .SUBMIT in ui.button(ctx, "Button 4") {write_log("Pressed button 4")}
				if .SUBMIT in ui.button(ctx, "Button 5") {write_log("Pressed button 5")}
				if .SUBMIT in ui.button(ctx, "Button 6") {write_log("Pressed button 6")}
			}
			if .ACTIVE in ui.treenode(ctx, "Test 3") {
				@(static)
				checks := [3]bool{true, false, true}
				ui.checkbox(ctx, "Checkbox 1", &checks[0])
				ui.checkbox(ctx, "Checkbox 2", &checks[1])
				ui.checkbox(ctx, "Checkbox 3", &checks[2])

			}
			ui.layout_end_column(ctx)

			ui.layout_begin_column(ctx)
			ui.layout_row(ctx, {-1})
			ui.text(
				ctx,
				"Lorem ipsum dolor sit amet, consectetur adipiscing " +
				"elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus " +
				"ipsum, eu varius magna felis a nulla.",
			)
			ui.layout_end_column(ctx)
		}

		if .ACTIVE in ui.header(ctx, "Background Colour", {.EXPANDED}) {
			ui.layout_row(ctx, {-78, -1}, 68)
			ui.layout_begin_column(ctx)
			{
				ui.layout_row(ctx, {46, -1}, 0)
				ui.label(ctx, "Red:");u8_slider(ctx, &state.bg.r, 0, 255)
				ui.label(ctx, "Green:");u8_slider(ctx, &state.bg.g, 0, 255)
				ui.label(ctx, "Blue:");u8_slider(ctx, &state.bg.b, 0, 255)
			}
			ui.layout_end_column(ctx)

			r := ui.layout_next(ctx)
			ui.draw_rect(ctx, r, state.bg)
			ui.draw_box(ctx, ui.expand_rect(r, 1), ctx.style.colors[.BORDER])
			ui.draw_control_text(
				ctx,
				fmt.tprintf("#%02x%02x%02x", state.bg.r, state.bg.g, state.bg.b),
				r,
				.TEXT,
				{.ALIGN_CENTER},
			)
		}
	}

	if ui.window(ctx, "Log Window", {350, 40, 300, 200}, opts) {
		ui.layout_row(ctx, {-1}, -28)
		ui.begin_panel(ctx, "Log")
		ui.layout_row(ctx, {-1}, -1)
		ui.text(ctx, read_log())
		if state.log_buf_updated {
			panel := ui.get_current_container(ctx)
			panel.scroll.y = panel.content_size.y
			state.log_buf_updated = false
		}
		ui.end_panel(ctx)

		@(static)
		buf: [128]byte
		@(static)
		buf_len: int
		submitted := false
		ui.layout_row(ctx, {-70, -1})
		if .SUBMIT in ui.textbox(ctx, buf[:], &buf_len) {
			ui.set_focus(ctx, ctx.last_id)
			submitted = true
		}
		if .SUBMIT in ui.button(ctx, "Submit") {
			submitted = true
		}
		if submitted {
			write_log(string(buf[:buf_len]))
			buf_len = 0
		}
	}

	if ui.window(ctx, "Style Window", {350, 250, 300, 240}) {
		@(static)
		colors := [ui.Color_Type]string {
			.TEXT         = "text",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
		}

		sw := i32(f32(ui.get_current_container(ctx).body.w) * 0.14)
		ui.layout_row(ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			ui.label(ctx, label)
			u8_slider(ctx, &ctx.style.colors[col].r, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].g, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].b, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].a, 0, 255)
			ui.draw_rect(ctx, ui.layout_next(ctx), ctx.style.colors[col])
		}
	}

}
