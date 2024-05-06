package skat3d

import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"

import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

WINDOW_WIDTH: f32 = 1920
WINDOW_HEIGHT: f32 = 1080

Vertex :: struct {
	position: glm.vec3,
	normal:   glm.vec3,
	color:    glm.vec4,
	uv:       glm.vec2,
}

Shader :: struct {
	id:   u32,
	name: string,
	path: string,
}

Transform :: struct {
	is_dirty: bool,
	position: glm.vec3,
	rotation: glm.vec3,
	size:     glm.vec3,
}

World_Object :: struct {
	id:        UUID4,
	name:      string,
	transform: Transform,
	mesh:      Mesh,
}

Mesh :: struct {
	vao, vbo, ebo: u32,
	vertices:      []Vertex,
	indices:       []u32,
}

Context :: struct {
	shader: Shader,
	mesh:   Mesh,
	mouse:  struct {
		position: glm.vec2,
		delta:    glm.vec2,
		wheel:    glm.vec2,
	},
}

ctx: Context

pre_draw :: proc() {
	gl.Viewport(0, 0, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
	gl.ClearColor(0.5, 0.7, 1.0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

draw :: proc(mesh: ^Mesh) {
	gl.DrawElements(gl.TRIANGLES, i32(len(mesh.indices)), gl.UNSIGNED_SHORT, nil)
}

present :: proc(window: ^SDL.Window) {
	SDL.GL_SwapWindow(window)
}

shader_init :: proc(path: string) -> (shader: Shader) {
	shaders_id: [dynamic]u32;defer delete(shaders_id)

	vertex_shader_source, vertex_shader_ok := os.read_entire_file(
		strings.join({path, "vs.glsl"}, "/"),
	)
	if !vertex_shader_ok do panic("File not found")
	{
		shader_id := gl_compile_shader_from_source(
			string(vertex_shader_source),
			gl.Shader_Type.VERTEX_SHADER,
		)
		append(&shaders_id, shader_id)
	}
	// fmt.println(string(vertex_shader_source))

	geometry_shader_source, geometry_shader_ok := os.read_entire_file(
		strings.join({path, "gs.glsl"}, "/"),
	)
	if geometry_shader_ok {
		shader_id := gl_compile_shader_from_source(
			string(geometry_shader_source),
			gl.Shader_Type.GEOMETRY_SHADER,
		)
		append(&shaders_id, shader_id)
		// fmt.println(string(geometry_shader_source))
	}

	fragment_shader_source, fragment_shader_ok := os.read_entire_file(
		strings.join({path, "fs.glsl"}, "/"),
	)
	if !fragment_shader_ok do panic("File not found")
	{
		shader_id := gl_compile_shader_from_source(
			string(fragment_shader_source),
			gl.Shader_Type.FRAGMENT_SHADER,
		)
		append(&shaders_id, shader_id)
	}
	// fmt.println(string(fragment_shader_source))

	shader.id = gl_create_and_link_program(shaders_id[:], false)

	for id, i in shaders_id {
		gl.DeleteShader(id)
	}

	return
}

shader_use :: proc(shader: ^Shader) {
	gl.UseProgram(shader.id)
}

shader_set_uniform_mat4 :: proc(shader: ^Shader, location: string, value: ^glm.mat4) {
	uniforms := gl.get_uniforms_from_program(shader.id)
	gl.UniformMatrix4fv(uniforms[location].location, 1, false, &value[0, 0])
}

shader_set_uniform_vec2 :: proc(shader: ^Shader, location: string, value: ^glm.vec2) {
	uniforms := gl.get_uniforms_from_program(shader.id)
	gl.Uniform2fv(uniforms[location].location, 1, &value[0])
}

shader_set_uniform_vec3 :: proc(shader: ^Shader, location: string, value: ^glm.vec3) {
	uniforms := gl.get_uniforms_from_program(shader.id)
	gl.Uniform3fv(uniforms[location].location, 1, &value[0])
}

/* GFX */
MAX_DRAWING :: 1000

Flat_Vertex :: struct {
	position: glm.vec2,
	color:    glm.vec4,
}

GFX_Context :: struct {
	vao, vbo:       u32,
	idx:            u32,
	idx_vertex_len: [MAX_DRAWING]u32,
	vertices:       sa.Small_Array(MAX_DRAWING, Flat_Vertex),
}
gfx_ctx: ^GFX_Context


/*
	// Line 1
	// idx: 0
	0 - 0:[position, color]
	1 - 1:[position, color]

	// Line 2
	// idx: 1
	2 - 0:[position, color]
	3 - 1:[position, color]

	// Quad
	// idx: 2
	4 - 0:[position, color]
	5 - 1:[position, color]
	6 - 2:[position, color]
	7 - 3:[position, color]
	8 - 4:[position, color]
	9 - 5:[position, color]

	// Point
	// idx: 3
	10 - 0:[position, color]

	// Shape?
	// idx: 4
	11 - 0:[position, color]
	12 - 1:[position, color]
	13 - 2:[position, color]
*/

gfx_init :: proc() {
	using gfx_ctx

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		MAX_DRAWING * size_of(Flat_Vertex),
		&gfx_ctx.vertices.data[0],
		gl.DYNAMIC_DRAW,
	)
	fmt.println(&gfx_ctx.vertices.data[0])

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(
		0,
		2,
		gl.FLOAT,
		false,
		size_of(Flat_Vertex),
		offset_of(Flat_Vertex, position),
	)
	gl.VertexAttribPointer(
		1,
		4,
		gl.FLOAT,
		false,
		size_of(Flat_Vertex),
		offset_of(Flat_Vertex, color),
	)
}

main :: proc() {
	when false {
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
	}

	window := SDL.CreateWindow(
		"Skat3D",
		SDL.WINDOWPOS_UNDEFINED,
		SDL.WINDOWPOS_UNDEFINED,
		auto_cast WINDOW_WIDTH,
		auto_cast WINDOW_HEIGHT,
		{.RESIZABLE, .ALLOW_HIGHDPI, .OPENGL},
	)
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)

	gl_context := SDL.GL_CreateContext(window)
	SDL.GL_MakeCurrent(window, gl_context)
	gl.load_up_to(4, 6, SDL.gl_set_proc_address)

	gl.Enable(gl.DEPTH_TEST)

	gfx_ctx = new(GFX_Context)
	gfx_ctx.idx_vertex_len[gfx_ctx.idx] = 6
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {-0.5, 0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {0.5, 0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {-0.5, -0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {0.5, 0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {-0.5, -0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	sa.push_back(
		&gfx_ctx.vertices,
		Flat_Vertex{position = {0.5, -0.5}, color = {1.0, 0.0, 1.0, 1.0}},
	)
	gfx_init()

	shader_default := shader_init("resources/shaders/default")
	shader_flat := shader_init("resources/shaders/flat")

	quad := mesh_create(
		[]Vertex {
			{position = {-1.0, 1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
			{position = {1.0, 1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
			{position = {-1.0, -1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
			{position = {1.0, 1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
			{position = {-1.0, -1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
			{position = {1.0, -1.0, 0.0}, color = {1.0, 1.0, 1.0, 1.0}},
		},
		nil,
	)

	test_mesh := mesh_create(
		[]Vertex {
			{position = {0.5, 0.0, 0.5}, normal = {0.0, 0.0, 0.0}, color = {1.0, 0.0, 0.0, 1.0}},
			{position = {-0.5, 0.0, 0.5}, normal = {0.0, 0.0, 0.0}, color = {1.0, 1.0, 0.0, 1.0}},
			{position = {-0.5, 0.0, -0.5}, normal = {0.0, 0.0, 0.0}, color = {0.0, 1.0, 0.0, 1.0}},
			{position = {0.5, 0.0, -0.5}, normal = {0.0, 0.0, 0.0}, color = {0.0, 0.0, 1.0, 1.0}},
			{position = {0.0, 1.0, 0.0}, normal = {0.0, 0.0, 0.0}, color = {0.0, 0.0, 1.0, 1.0}},
			{position = {0.0, -1.0, 0.0}, normal = {0.0, 0.0, 0.0}, color = {0.0, 0.0, 1.0, 1.0}},
		},
		[]u32{0, 4, 1, 1, 4, 2, 2, 4, 3, 3, 4, 0, 0, 5, 1, 1, 5, 2, 2, 5, 3, 3, 5, 0},
	)

	flat_camera := camera_create(.Camera_Flat, .Orthographic, {WINDOW_WIDTH, WINDOW_HEIGHT})

	camera := camera_create(.Camera_Orbit, .Perspective, {WINDOW_WIDTH, WINDOW_HEIGHT})
	camera.position.y = 1.0

	object_position: glm.vec3
	object_rotation: glm.vec3
	object_model := glm.identity(glm.mat4)

	start_tick := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		event: SDL.Event
		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .MOUSEWHEEL:
				ctx.mouse.wheel.y = f32(event.wheel.y)
				camera.radius += -ctx.mouse.wheel.y * 0.1
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					break loop
				}
			case .QUIT:
				break loop
			}

			if event.motion.type == .MOUSEMOTION {
				ctx.mouse.position = {auto_cast event.motion.x, auto_cast event.motion.y}
				ctx.mouse.delta = {auto_cast event.motion.xrel, auto_cast event.motion.yrel}
			}

			if event.window.type == .WINDOWEVENT {
				#partial switch event.window.event {
				case .SIZE_CHANGED, .RESIZED:
					WINDOW_WIDTH = auto_cast event.window.data1 * 2
					WINDOW_HEIGHT = auto_cast event.window.data2 * 2
					camera_set_viewport(camera, {WINDOW_WIDTH, WINDOW_HEIGHT})
					camera_set_viewport(flat_camera, {WINDOW_WIDTH, WINDOW_HEIGHT})
				}
			}
		}

		gl.Viewport(0, 0, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		/* Drawing lines */
		camera_update(flat_camera)
		shader_use(&shader_flat)
		{
			object_model := glm.identity(glm.mat4)
			shader_set_uniform_mat4(&shader_flat, "u_model", &object_model)
			shader_set_uniform_mat4(&shader_flat, "u_projection", &flat_camera.projection_matrix)
			shader_set_uniform_mat4(&shader_flat, "u_view", &flat_camera.view_matrix)

			gl.BindVertexArray(gfx_ctx.vao)

			if gfx_ctx.idx_vertex_len[gfx_ctx.idx] == 2 {
				gl.DrawArrays(gl.LINES, 0, 2)
			} else if gfx_ctx.idx_vertex_len[gfx_ctx.idx] % 3 == 0 {
				gl.DrawArrays(gl.TRIANGLES, 0, i32(gfx_ctx.idx_vertex_len[gfx_ctx.idx]))
			}
		}

		/* Drawing 3d models */
		camera_update(camera)
		shader_use(&shader_default)
		{
			shader_set_uniform_mat4(&shader_default, "u_projection", &camera.projection_matrix)
			shader_set_uniform_mat4(&shader_default, "u_view", &camera.view_matrix)

			object_model *= glm.mat4Rotate({0.0, 1.0, 0.0}, glm.radians_f32(1.0))
			shader_set_uniform_mat4(&shader_default, "u_model", &object_model)

			gl.BindVertexArray(test_mesh.vao)
			gl.DrawElements(gl.TRIANGLES, i32(len(test_mesh.indices)), gl.UNSIGNED_INT, nil)
		}

		SDL.GL_SwapWindow(window)
	}
}

// ======== Mesh ========

mesh_create :: proc(vertices: []Vertex, indices: []u32) -> (mesh: Mesh) {
	vao, vbo, ebo: u32

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.DYNAMIC_DRAW,
	)

	// Setup only after array buffer
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, normal))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.DYNAMIC_DRAW,
	)

	mesh.vao, vbo, ebo = vao, vbo, ebo
	mesh.vertices = vertices
	mesh.indices = indices

	return
}

mesh_destroy :: proc(mesh: ^Mesh) {
	gl.DeleteVertexArrays(1, &mesh.vao)
	gl.DeleteBuffers(1, &mesh.vbo)
	gl.DeleteBuffers(1, &mesh.ebo)
}

// ======== Mesh ========

// Compiling shaders are identical for any shader (vertex, geometry, fragment, tesselation, (maybe compute too))
@(private)
gl_compile_shader_from_source :: proc(
	shader_data: string,
	shader_type: gl.Shader_Type,
) -> (
	shader_id: u32,
) {
	shader_id = gl.CreateShader(cast(u32)shader_type)
	length := i32(len(shader_data))
	shader_data_copy := cstring(raw_data(shader_data))
	gl.ShaderSource(shader_id, 1, &shader_data_copy, &length)
	gl.CompileShader(shader_id)

	return
}

// only used once, but I'd just make a subprocedure(?) for consistency
@(private)
gl_create_and_link_program :: proc(
	shader_ids: []u32,
	binary_retrievable := false,
) -> (
	program_id: u32,
) {
	program_id = gl.CreateProgram()
	for id in shader_ids {
		gl.AttachShader(program_id, id)
	}
	if binary_retrievable {
		gl.ProgramParameteri(
			program_id,
			gl.PROGRAM_BINARY_RETRIEVABLE_HINT,
			1,
			/*true*/
		)
	}
	gl.LinkProgram(program_id)

	return
}
