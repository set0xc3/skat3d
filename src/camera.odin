package skat3d

import "core:fmt"

import glm "core:math/linalg/glsl"

Projection_Type :: enum {
	Orthographic,
	Perspective,
}

Camera_Mode :: enum {
	Camera_Flat,
	Camera_Free,
	Camera_First_Person,
	Camera_Third_Person,
	Camera_Orbit,
}

Camera_Orbit :: enum {
	On_Object_Center,
	On_Clicked_Location,
}

Camera :: struct {
	// Base
	mode:              Camera_Mode,
	projection_type:   Projection_Type,
	fovy, near, far:   f32,
	viewport:          glm.vec2,
	position:          glm.vec3,
	view_matrix:       glm.mat4,
	projection_matrix: glm.mat4,


	// Flat

	// First Person
	orientation:       glm.quat,
	target_position:   glm.vec3,
	target_distance:   f32,

	// Orbit
	orbit_mode:        Camera_Orbit,
	zoom_type:         u32,
	zoom_speed:        f32,
}

camera_update_projection :: proc(camera: ^Camera, type: Projection_Type) {
	switch type {
	case .Orthographic:
		zoom: f32 = 1.0
		aspect := camera.viewport.x / camera.viewport.y
		camera.projection_matrix = glm.mat4Ortho3d(
			-zoom * aspect,
			zoom * aspect,
			-zoom,
			zoom,
			-1.0,
			1.0,
		)
	case .Perspective:
		camera.projection_matrix = glm.mat4Perspective(
			glm.radians(camera.fovy),
			camera.viewport.x / camera.viewport.y,
			camera.near,
			camera.far,
		)
	}
}

camera_create :: proc(mode: Camera_Mode, type: Projection_Type, viewport: glm.vec2) -> ^Camera {
	camera := new(Camera)
	camera.mode = mode
	camera.projection_type = type
	camera.fovy = 45.0
	camera.near = 0.01
	camera.far = 1000.0
	camera.position = {0.0, 0.0, 2.0}
	camera.viewport = viewport

	camera_update_projection(camera, type)

	#partial switch mode {
	case .Camera_Flat:
		camera.position = {0.0, 0.0, 0.0}
		camera.view_matrix = glm.mat4Translate(-camera.position)
	case .Camera_Orbit:
		direction := glm.vec3{0.0, 0.0, -1.0}
		right := glm.vec3{1.0, 0.0, 0.0}
		camera.view_matrix = glm.mat4LookAt(
			camera.position,
			camera.position + direction,
			glm.cross(right, direction),
		)
		camera.orbit_mode = .On_Object_Center
	}

	return camera
}

camera_destroy :: proc(camera: ^Camera) {
	free(camera)
}

camera_set_viewport :: proc(camera: ^Camera, viewport: glm.vec2) {
	camera.viewport = viewport
	camera_update_projection(camera, camera.projection_type)

}

camera_get_view_matrix :: proc(camera: ^Camera) -> glm.mat4 {
	return camera.view_matrix
}

camera_get_projection_matrix :: proc(camera: ^Camera) -> glm.mat4 {
	return camera.projection_matrix
}
