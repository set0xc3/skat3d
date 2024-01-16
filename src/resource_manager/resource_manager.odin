// resources [...]
// audio_buf [...]
// fonts_buf [...]
// images_buf [...]

package resource_manager

import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:strings"

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

Image :: struct {}

Font :: struct {
}

Audio :: struct {}

Resource_Type :: enum {
	Image,
	Font,
	Audio,
}

Resource_Base :: struct {
	id:   core.UUID4,
	path: string,
}

Context :: struct {
	resorces: sa.Small_Array(1024, Resource_Base),
}

ctx: ^Context

init :: proc() {
	ctx = new(Context)
}

load :: proc(path: string, type: Resource_Type) -> (id: ResourceID) {
	switch type {
	case .Image:
	case .Font:
		data, ok := os.read_entire_file_from_filename(path)
	case .Audio:
	}

	return
}

unload :: proc(id: ResourceID) {
}

delete :: proc() {
}

get :: proc(id: ResourceID, type: Resource_Type) {
	switch type {
	case .Image:
	case .Font:
	case .Audio:
	}
}

print :: proc() {

}
