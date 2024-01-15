package resource_manager

import sa "core:container/small_array"
import "core:fmt"
import "core:strings"
import "core:os"

import "skat3d:core"

MAX_PATH_LENGTH :: 256

ResourceID :: u32

Error :: enum {
	Ok,
	No_Found,
	Conflict,
	Access_Failed,
	Allocation_Failed,
}

Resource_Type :: enum {
	Image,
	Font,
	Audio,
}

Resource_Base :: struct {
	id:   core.UUID4,
	path: string,
}

Font :: struct {
    data: rawptr,
}

Context :: struct {
	basepath: string,
	resorces: sa.Small_Array(1024, Resource_Base),
}

ctx: ^Context

init :: proc(path: string = "res://") -> (err: Error) {
	ctx = new(Context)
	ctx.basepath = path
	return
}

load :: proc(path: string) -> (id: ResourceID, err: Error) {
    data, ok := os.read_entire_file_from_filename("assets/fonts/proggy_clean.ttf");
	return
}

unload :: proc(id: ResourceID) -> (err: Error) {
	return
}

delete :: proc() -> (err: Error) {
	return
}

get :: proc(id: ResourceID, type: Resource_Type) -> (err: Error) {
    return
}

print :: proc() {

}
