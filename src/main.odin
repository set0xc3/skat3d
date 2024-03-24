package skat3d

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
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
	id:            u32,
	name:          string,
	path:          string,
	vao, vbo, ebo: u32,
}

Mesh :: struct {
	vertices: []Vertex,
	indices:  []u16,
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
	vao, vbo, ebo: u32
	shader_ids: [3]u32

	shader_source, shaders_source_ok := os.read_entire_file("resources/shaders/default.glsl")
	shaders_source := strings.split(string(shader_source), "#split")

	vertex_shader_id := gl_compile_shader_from_source(
		shaders_source[0],
		gl.Shader_Type.VERTEX_SHADER,
	);defer gl.DeleteShader(vertex_shader_id)

	geometry_shader_id := gl_compile_shader_from_source(
		shaders_source[1],
		gl.Shader_Type.GEOMETRY_SHADER,
	);defer gl.DeleteShader(geometry_shader_id)

	fragment_shader_id := gl_compile_shader_from_source(
		shaders_source[2],
		gl.Shader_Type.FRAGMENT_SHADER,
	);defer gl.DeleteShader(fragment_shader_id)

	shader_program_id := gl_create_and_link_program(
		[]u32{vertex_shader_id, geometry_shader_id, fragment_shader_id},
		false,
	)

	gl.UseProgram(shader_program_id)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(Vertex) * MAX_OBJECTS, nil, gl.DYNAMIC_DRAW)

	gl.GenVertexArrays(1, &vao)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, normal))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u16) * 6 * MAX_OBJECTS, nil, gl.DYNAMIC_DRAW)

	shader.id = shader_program_id
	shader.vao = vao
	shader.vbo = vbo
	shader.ebo = ebo

	return
}

shader_update_data :: proc(shader: ^Shader, mesh: ^Mesh) {
	shader_use(shader)
	// gl.BufferData(
	// 	gl.ARRAY_BUFFER,
	// 	size_of(Vertex) * len(mesh.vertices),
	// 	&mesh.vertices[0],
	// 	gl.DYNAMIC_DRAW,
	// )
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		0,
		len(mesh.vertices) * size_of(mesh.vertices[0]),
		raw_data(mesh.vertices),
	)

	if len(mesh.indices) > 0 {
		// gl.BufferData(
		// 	gl.ELEMENT_ARRAY_BUFFER,
		// 	size_of(u16) * len(mesh.indices),
		// 	&mesh.indices[0],
		// 	gl.DYNAMIC_DRAW,
		// )
		gl.BufferSubData(
			gl.ELEMENT_ARRAY_BUFFER,
			0,
			len(mesh.indices) * size_of(mesh.indices[0]),
			raw_data(mesh.indices),
		)
	}
}

shader_use :: proc(shader: ^Shader) {
	gl.UseProgram(shader.id)
	gl.BindBuffer(gl.ARRAY_BUFFER, shader.vao)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, shader.ebo)
}

shader_set_uniform_mat4 :: proc(shader: ^Shader, location: string, value: ^glm.mat4) {
	uniforms := gl.get_uniforms_from_program(ctx.shader.id)
	gl.UniformMatrix4fv(uniforms[location].location, 1, false, &value[0, 0])
}

camera_init :: proc(camera_var: Camera_Variable) -> (camera_inst: Camera_Instance) {
	camera_base: Camera_Base
	camera_base.position = {0.0, 0.0, 3.0}
	camera_base.up = {0.0, 1.0, 0.0}
	camera_base.front = {0.0, 0.0, -1.0}
	camera_base.fovy = 50
	camera_base.near = 0.1
	camera_base.far = 100.0
	camera_inst.variant = camera_base


	#partial switch &camera in camera_var {
	case Camera_Base:
	case Camera_Orbit:
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
	shader_set_uniform_mat4(shader, "u_model", &model)
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
	{.RESIZABLE,  /* .FULLSCREEN, */.ALLOW_HIGHDPI, .OPENGL},
	)
	if window == nil {
		fmt.eprintln("Failed to create window")
		return
	}
	defer SDL.DestroyWindow(window)

	gl_context := SDL.GL_CreateContext(window)
	SDL.GL_MakeCurrent(window, gl_context)
	gl.load_up_to(4, 6, SDL.gl_set_proc_address)

	// OPENGL_BEGIN
	shader_source, shaders_source_ok := os.read_entire_file("resources/shaders/default.glsl")
	shaders_source := strings.split(string(shader_source), "#split")

	vertex_shader_id := gl_compile_shader_from_source(
		shaders_source[0],
		gl.Shader_Type.VERTEX_SHADER,
	);defer gl.DeleteShader(vertex_shader_id)

	geometry_shader_id := gl_compile_shader_from_source(
		shaders_source[1],
		gl.Shader_Type.GEOMETRY_SHADER,
	);defer gl.DeleteShader(geometry_shader_id)

	fragment_shader_id := gl_compile_shader_from_source(
		shaders_source[2],
		gl.Shader_Type.FRAGMENT_SHADER,
	);defer gl.DeleteShader(fragment_shader_id)

	shader_program_id := gl_create_and_link_program(
		[]u32{vertex_shader_id, geometry_shader_id, fragment_shader_id},
		false,
	)

	gl.UseProgram(shader_program_id)

	// assert(false)

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	vertices := []Vertex {
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
	}

	indices := []u16{0, 1, 2, 2, 3, 0}

	// Craete empty vertex buffer
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	// Update vertex buffer
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.DYNAMIC_DRAW,
	)
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
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)

	// Update index buffer
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.DYNAMIC_DRAW,
	)
	// gl.BufferSubData(
	// 	gl.ELEMENT_ARRAY_BUFFER,
	// 	0,
	// 	len(indices) * size_of(indices[0]),
	// 	raw_data(indices),
	// )

	uniforms := gl.get_uniforms_from_program(shader_program_id);defer delete(uniforms)
	// OPENGL_END

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
					WINDOW_WIDTH = auto_cast event.window.data1 * 2
					WINDOW_HEIGHT = auto_cast event.window.data2 * 2
				}
			}
		}

		// Native support for GLSL-like functionality
		pos := glm.vec3{glm.cos(t * 2), glm.sin(t * 2), 0}

		// array programming support
		pos *= 0.3

		// matrix support
		// model matrix which a default scale of 0.5
		model := glm.mat4{0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1}

		// matrix indexing and array short with `.x`
		model[0, 3] = -pos.x
		model[1, 3] = -pos.y
		model[2, 3] = -pos.z

		// native swizzling support for arrays
		model[3].yzx = pos.yzx

		model = model * glm.mat4Rotate({0, 1, 1}, t)

		view := glm.mat4LookAt({0, -1, +1}, {0, 0, 0}, {0, 0, 1})
		proj := glm.mat4Perspective(45, 1.3, 0.1, 100.0)

		// matrix multiplication
		u_transform := proj * view * model

		// matrix types in Odin are stored in column-major format but written as you'd normal write them
		gl.UniformMatrix4fv(uniforms["u_transform"].location, 1, false, &u_transform[0, 0])

		gl.Viewport(0, 0, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

		SDL.GL_SwapWindow(window)
	}
}

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
