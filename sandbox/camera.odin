package tests

import "core:fmt"
import "core:log"
import "core:mem"

import glm "core:math/linalg/glsl"

Camera_Mode :: enum {
	Orthographic,
	Perspective,
}

Camera_Base :: struct {
	is_dirty:          bool,
	mode:              Camera_Mode,
	viewport:          glm.vec2,
	position:          glm.vec3,
	view_matrix:       glm.mat4,
	projection_matrix: glm.mat4,
}

Camera_Flat :: struct {
	using _: Camera_Base,
}

Camera_First_Person :: struct {
	using _: Camera_Base,
}

Camera_Orbit :: struct {
	using _: Camera_Base,
}

Camera_Variant :: union {
	Camera_Flat,
	Camera_First_Person,
	Camera_Orbit,
}

Camera_Instance :: struct {
	variant: Camera_Variant,
}

camera_create :: proc($T: typeid) -> ^Camera_Instance {
	camera_inst := new(Camera_Instance)
	camera_inst.variant = T{}

	#partial switch var in camera_inst.variant {
	case Camera_Flat:
	case Camera_First_Person:
	case Camera_Orbit:
	}

	return camera_inst
}

camera_destroy :: proc(camera_inst: ^Camera_Instance) {
	free(camera_inst)
}

camera_set_viewport :: proc(camera: ^Camera_Base, viewport: glm.vec2) {
	camera.viewport = viewport
	camera.is_dirty = true
}

camera_get_view_matrix :: proc(camera: ^Camera_Base) -> glm.mat4 {
	return camera.view_matrix
}

camera_get_projection_matrix :: proc(camera: ^Camera_Base) -> glm.mat4 {
	return camera.projection_matrix
}

main :: proc() {
	context.logger = log.create_console_logger()

	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		leaks := false

		for key, value in a.allocation_map {
			fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
			leaks = true
		}

		mem.tracking_allocator_clear(a)
		return leaks
	}

	camera_inst := camera_create(Camera_Flat)
	camera_destroy(camera_inst)

	reset_tracking_allocator(&tracking_allocator)
}
