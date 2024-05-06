package sandbox

import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:time"

/* GFX */
MAX_DRAWING :: 1000

Flat_Vertex :: struct {
	position: glm.vec2,
	color:    glm.vec4,
}

vertices: sa.Small_Array(MAX_DRAWING, []Flat_Vertex)

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
	};defer reset_tracking_allocator(&tracking_allocator)


	sa.push_back(&vertices, []Flat_Vertex{{position = {0.0, 0.0}, color = {1.0, 0.0, 1.0, 1.0}}})
	sa.push_back(&vertices, []Flat_Vertex{{position = {1.0, 1.0}, color = {1.0, 0.0, 1.0, 1.0}}})

	fmt.println(&vertices)
}
