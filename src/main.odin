package skat3d

import "core:fmt"

import rs "resource_manager"

main :: proc() {
	fmt.println("Skat3D")

    rs.init()

    id, err := rs.load("fonts/proggy_clean.ttf")
    rs.get(id, .Font);
    rs.unload(id);
}