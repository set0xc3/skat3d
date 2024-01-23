// (TODO) ResourceManager

// (TODO) GameObjects:
// - [] Player
// - [] Enemies

package game

import "core:math/linalg"

import rl "vendor:raylib"

MAX_FRAME_SPEED :: 15
MIN_FRAME_SPEED :: 1

Vector2 :: linalg.Vector2f32
Quaternion :: linalg.Quaternionf32

Player :: struct {
	position: Vector2,
	size:     Vector2,
	speed:    f32,
	texture:  rl.Texture2D,
}

player: ^Player
camera: rl.Camera2D

player_create :: proc() -> (player: ^Player) {
	player = new(Player)
	player.size = 100
	player.speed = 400
	return
}

player_destroy :: proc(player: ^Player) {

}

player_update :: proc(player: ^Player) {
	dt := rl.GetFrameTime()

	if rl.IsKeyDown(.A) {
		player.position.x -= player.speed * dt
	}
	if rl.IsKeyDown(.D) {
		player.position.x += player.speed * dt
	}
	if rl.IsKeyDown(.W) {
		player.position.y -= player.speed * dt
	}
	if rl.IsKeyDown(.S) {
		player.position.y += player.speed * dt
	}
}

player_draw :: proc(player: ^Player) {
	frameWidth := cast(f32)player.texture.width / 6
	frameHeight := cast(f32)player.texture.height

	sourceRec := rl.Rectangle{0.0, 0.0, frameWidth, frameHeight}
	destRec := rl.Rectangle {
		player.position.x,
		player.position.y,
		frameWidth * 2.0,
		frameHeight * 2.0,
	}
	origin := Vector2{frameWidth, frameHeight}

  rl.DrawTexturePro(player.texture, sourceRec, destRec, origin, 0, rl.WHITE)

  rl.DrawRectangleLinesEx({player.position.x, player.position.y, player.size.x, player.size.y}, 1, rl.GREEN)
	// rl.DrawRectangleV(player.position, player.size, rl.RED)
}

start :: proc() {
	player = player_create()

	camera.offset = {1280 / 2, 720 / 2}
	camera.zoom = 1.0

	player.texture = rl.LoadTexture("resources/player/player.png")
}

update :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.WHITE)
	rl.BeginMode2D(camera)

	{
		interpolation_factor := Vector2{0.1, 0.1}
		res := linalg.lerp(camera.target, player.position, interpolation_factor)
		camera.target = res
	}

	player_update(player)
	player_draw(player)

	rl.DrawText("Congrats! You created your first window!", 0, 0, 20, rl.BLACK)

	rl.EndMode2D()
	rl.EndDrawing()
}

stop :: proc() {

}
