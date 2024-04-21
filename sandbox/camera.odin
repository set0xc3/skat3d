package sandbox

import "core:fmt"
import "core:log"
import "core:mem"

import skat3d "skat3d:src"

main :: proc() {
	using skat3d

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


	camera := camera_create(.Camera_Flat, .Orthographic, {800, 600})
	camera_destroy(camera)
}
