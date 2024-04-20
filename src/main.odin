package skat3d

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"

import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

WINDOW_WIDTH: f32 = 1920
WINDOW_HEIGHT: f32 = 1080

MAX_OBJECTS :: 1000

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
	indices:       []u16,
}

Camera_Base :: struct {
	position, front, up: glm.vec3,
	fovy, near, far:     f32,
}

Camera_Orbit :: struct {
	using base: Camera_Base,
	target:     glm.vec3,
	angle:      glm.vec2,
	radius:     f32,
}

Camera_Variable :: union {
	Camera_Base,
	Camera_Orbit,
}

Camera_Instance :: struct {
	variant: Camera_Variable,
}

Context :: struct {
	shader: Shader,
	mesh:   Mesh,
	camera: Camera_Base,
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

gl_init :: proc() {
	// initialization of OpenGL buffers
	vao, vbo, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	// Craete empty vertex buffer
	// gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	// gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	// Update vertex buffer
	// gl.BufferData(
	// 	gl.ARRAY_BUFFER,
	// 	len(vertices) * size_of(vertices[0]),
	// 	raw_data(vertices),
	// 	gl.DYNAMIC_DRAW,
	// )
	// gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * size_of(vertices[0]), raw_data(vertices))

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, normal))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	// Craete empty index buffer
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	// Update index buffer
	// gl.BufferData(
	// 	gl.ELEMENT_ARRAY_BUFFER,
	// 	len(indices) * size_of(indices[0]),
	// 	raw_data(indices),
	// 	gl.DYNAMIC_DRAW,
	// )
	// gl.BufferSubData(
	// 	gl.ELEMENT_ARRAY_BUFFER,
	// 	0,
	// 	len(indices) * size_of(indices[0]),
	// 	raw_data(indices),
	// )

	gl.BindVertexArray(0)
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

camera_init :: proc(camera_var: Camera_Variable) -> (camera_inst: Camera_Instance) {
	#partial switch &camera in camera_var {
	case Camera_Base:
		camera_inst.variant = camera
	case Camera_Orbit:
		camera_inst.variant = camera
	}
	return
}

camera_update :: proc(camera: ^Camera_Base, shader: ^Shader) {
	model := glm.identity(glm.mat4)
	view := camera_get_view_matrix(camera)
	projection := glm.mat4Perspective(
		glm.radians(camera.fovy),
		WINDOW_WIDTH / WINDOW_HEIGHT,
		camera.near,
		camera.far,
	)

	shader_use(shader)
	shader_set_uniform_mat4(shader, "u_view", &view)
	shader_set_uniform_mat4(shader, "u_projection", &projection)
}

camera_get_view_matrix :: proc(camera: ^Camera_Base) -> glm.mat4 {
	return glm.mat4LookAt(camera.position, camera.position + camera.front, camera.up)
}

main :: proc() {
	window := SDL.CreateWindow(
	"Skat3D",
	SDL.WINDOWPOS_UNDEFINED,
	SDL.WINDOWPOS_UNDEFINED,
	auto_cast WINDOW_WIDTH,
	auto_cast WINDOW_HEIGHT,
	{.RESIZABLE,  /* .FULLSCREEN, */ /*.ALLOW_HIGHDPI,*/.OPENGL},
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

	shader_default := shader_init("resources/shaders/default")

	test_mesh := mesh_create(
		[]Vertex {
			 {
				position = {-0.5, +0.5, 0},
				normal = {0.0, 0.0, 0.0},
				color = {1.0, 0.0, 0.0, 0.75},
				uv = {0.0, 0.0},
			},
			 {
				position = {-0.5, -0.5, 0},
				normal = {0.0, 0.0, 0.0},
				color = {1.0, 1.0, 0.0, 0.75},
				uv = {0.0, 0.0},
			},
			 {
				position = {+0.5, -0.5, 0},
				normal = {0.0, 0.0, 0.0},
				color = {0.0, 1.0, 0.0, 0.75},
				uv = {0.0, 0.0},
			},
			 {
				position = {+0.5, +0.5, 0},
				normal = {0.0, 0.0, 0.0},
				color = {0.0, 0.0, 1.0, 0.75},
				uv = {0.0, 0.0},
			},
		},
		[]u16{0, 1, 2, 2, 3, 0},
	)

	camera := camera_init(
		Camera_Base {
			position = {0.0, 0.0, 3.0},
			up = {0.0, 1.0, 0.0},
			front = {0.0, 0.0, -1.0},
			fovy = 50,
			near = 0.1,
			far = 100.0,
		},
	)

	start_tick := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		event: SDL.Event
		for SDL.PollEvent(&event) {
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					break loop
				}
			case .QUIT:
				break loop
			}

			if event.window.type == .WINDOWEVENT {
				#partial switch event.window.event {
				case .SIZE_CHANGED, .RESIZED:
					WINDOW_WIDTH = auto_cast event.window.data1
					WINDOW_HEIGHT = auto_cast event.window.data2
				}
			}
		}

		gl.Viewport(0, 0, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		shader_use(&shader_default)

		#partial switch &camera in camera.variant {
		case Camera_Base:
			// camera.position.y += 0.01
			camera_update(&camera, &shader_default)
		case Camera_Orbit:
			camera_update(&camera, &shader_default)
		}

		@(static)
		object_position: glm.vec3
		// object_position.x += 0.01
		object_model := glm.identity(glm.mat4)
		object_model = glm.mat4Translate({object_position.x, 0.0, 0.0})
		shader_set_uniform_mat4(&shader_default, "u_model", &object_model)

		gl.BindVertexArray(test_mesh.vao)
		gl.DrawElements(gl.TRIANGLES, i32(len(test_mesh.indices)), gl.UNSIGNED_SHORT, nil)

		SDL.GL_SwapWindow(window)
	}
}

// ======== Mesh ========

mesh_create :: proc(vertices: []Vertex, indices: []u16) -> (mesh: Mesh) {
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
