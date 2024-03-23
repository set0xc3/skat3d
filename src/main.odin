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

shader_ini :: proc(path: string) -> (shader: Shader) {
	vao, vbo, ebo: u32

	shader_source, shader_source_ok := os.read_entire_file(path)
	if !shader_source_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}

	shaders_source := strings.split_n(string(shader_source), "#split", 3)

	vertex_shader_id, vertex_shader_ok := gl_compile_shader_from_source(
		shaders_source[0],
		gl.Shader_Type.VERTEX_SHADER,
	);defer gl.DeleteShader(vertex_shader_id)

	fragment_shader_id, fragment_shader_ok := gl_compile_shader_from_source(
		shaders_source[1],
		gl.Shader_Type.FRAGMENT_SHADER,
	);defer gl.DeleteShader(fragment_shader_id)

	geometry_shader_id, geometry_shader_ok := gl_compile_shader_from_source(
		shaders_source[2],
		gl.Shader_Type.GEOMETRY_SHADER,
	);defer gl.DeleteShader(geometry_shader_id)

	shader_program_id, shader_program_ok := gl_create_and_link_program(
		[]u32{vertex_shader_id, fragment_shader_id, geometry_shader_id},
	)

	gl.UseProgram(shader_program_id)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, 0, nil, gl.DYNAMIC_DRAW)

	gl.GenVertexArrays(1, &vao)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, normal))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.VertexAttribPointer(3, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, uv))

	gl.UseProgram(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	shader.id = shader_program_id
	shader.vao = vao
	shader.vbo = vbo
	shader.ebo = ebo

	return
}

shader_update_data :: proc(shader: ^Shader, mesh: ^Mesh) {
	shader_use(shader)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(Vertex) * len(mesh.vertices),
		&mesh.vertices[0],
		gl.DYNAMIC_DRAW,
	)
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(Vertex) * len(mesh.vertices), &mesh.vertices[0])

	if len(mesh.indices) > 0 {
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			size_of(u16) * len(mesh.indices),
			&mesh.indices[0],
			gl.DYNAMIC_DRAW,
		)
		gl.BufferSubData(
			gl.ELEMENT_ARRAY_BUFFER,
			0,
			size_of(u16) * len(mesh.indices),
			&mesh.indices[0],
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

camera_use :: proc(camera: ^Camera_Base, shader: ^Shader) {
	model := glm.identity(glm.mat4)
	view := camera_get_view_matrix(camera)
	projection := glm.mat4Perspective(
		glm.radians(camera.fovy),
		WINDOW_WIDTH / WINDOW_HEIGHT,
		camera.near,
		camera.far,
	)
	shader_set_uniform_mat4(shader, "u_model", &model)
	shader_set_uniform_mat4(shader, "u_view", &view)
	shader_set_uniform_mat4(shader, "u_projection", &projection)
}

camera_get_view_matrix :: proc(camera: ^Camera_Base) -> glm.mat4 {
	return glm.mat4LookAt(camera.position, camera.position + camera.front, camera.up)
}

main :: proc() {
	window := SDL.CreateWindow(
	"Odin SDL2 Demo",
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
	// load the OpenGL procedures once an OpenGL context has been established
	gl.load_up_to(4, 6, SDL.gl_set_proc_address)

	camera_orbit: Camera_Orbit
	camera_inst := camera_init(camera_orbit)

	// quad_mesh: Mesh
	// quad_mesh.vertices = []Vertex {
	// 	{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 1.0}, {0.0, 0.0}},
	// 	{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 1.0}, {0.0, 0.0}},
	// 	{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 1.0}, {0.0, 0.0}},
	// 	{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 1.0}, {0.0, 0.0}},
	// }
	// quad_mesh.indices = []u16{0, 1, 2, 2, 3, 0}

	// ctx.shader = shader_init("resources/shaders/default.glsl")
	// shader_use(&ctx.shader)
	// shader_update_data(&ctx.shader, &quad_mesh)

	grid_mesh: Mesh
	grid_mesh.vertices = []Vertex {
		 {
			position = {-0.5, +0.5, 0},
			normal = {0.0, 0.0, 0.0},
			color = {1.0, 0.0, 0.0, 1.0},
			uv = {0.0, 0.0},
		},
		 {
			position = {-0.5, -0.5, 0},
			normal = {0.0, 0.0, 0.0},
			color = {1.0, 1.0, 0.0, 1.0},
			uv = {0.0, 0.0},
		},
		 {
			position = {+0.5, -0.5, 0},
			normal = {0.0, 0.0, 0.0},
			color = {0.0, 1.0, 0.0, 1.0},
			uv = {0.0, 0.0},
		},
		 {
			position = {+0.5, +0.5, 0},
			normal = {0.0, 0.0, 0.0},
			color = {0.0, 0.0, 1.0, 1.0},
			uv = {0.0, 0.0},
		},
	}
	shader_grid := shader_ini("resources/shaders/grid.glsl")
	shader_update_data(&shader_grid, &grid_mesh)

	// high precision timer
	start_tick := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// event polling
		event: SDL.Event
		for SDL.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				}
			case .QUIT:
				// labelled control flow
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

		// shader_use(&ctx.shader)
		// camera_use(&ctx.camera, &ctx.shader)

		// camera_use(&ctx.camera, &shader_grid)
		// shader_use(&shader_grid)
		// gl.DrawArrays(gl.POINTS, 0, 4)

		pre_draw()
		// draw(&quad_mesh)
		present(window)
	}
}

gl_compile_shader_from_source :: proc(
	shader_data: string,
	shader_type: gl.Shader_Type,
) -> (
	shader_id: u32,
	ok: bool,
) {
	shader_id = gl.CreateShader(cast(u32)shader_type)
	length := i32(len(shader_data))
	shader_data_copy := cstring(raw_data(shader_data))
	gl.ShaderSource(shader_id, 1, &shader_data_copy, &length)
	gl.CompileShader(shader_id)

	// gl.check_error(shader_id, shader_type, COMPILE_STATUS, GetShaderiv, GetShaderInfoLog) or_return
	ok = true
	return
}

gl_create_and_link_program :: proc(
	shader_ids: []u32,
	binary_retrievable := false,
) -> (
	program_id: u32,
	ok: bool,
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

	// check_error(
	// 	program_id,
	// 	Shader_Type.SHADER_LINK,
	// 	LINK_STATUS,
	// 	GetProgramiv,
	// 	GetProgramInfoLog,
	// ) or_return
	ok = true
	return
}
