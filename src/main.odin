package skat3d

import "core:fmt"

import rs "resource_manager"

main :: proc() {
	fmt.println("Skat3D")

    rs.init()

    id := rs.load("fonts/proggy_clean.ttf", .Font)
    // font := rs.get(id, .Font);
    // font.data
    rs.unload(id);
}