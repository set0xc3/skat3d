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

Vertex :: struct {
	pos: glm.vec3,
	col: glm.vec4,
}

Shader :: struct {
	id:   u32,
	name: string,
	path: string,
}

Mesh :: struct {
	vertexes: Vertex,
	vertices: u32,
}

Camera :: struct {
	position, front, up: glm.vec3,
	fovy, near, far:     f32,
}

Context :: struct {
	shader: Shader,
	mesh:   Mesh,
	camera: Camera,
}

ctx: Context

shader_load :: proc() -> (shader: Shader) {
	source, source_ok := os.read_entire_file("resources/shaders/default.glsl")
	code := strings.split_n(string(source), "#split", 2)

	program, program_ok := gl.load_shaders_source(code[0], code[1])
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}

	shader.id = program

	return
}

shader_bind :: proc(shader: ^Shader) {
	gl.UseProgram(shader.id)
}

shader_set_uniform_mat4 :: proc(shader: ^Shader, location: string, value: ^glm.mat4) {
	uniforms := gl.get_uniforms_from_program(ctx.shader.id)
	gl.UniformMatrix4fv(uniforms[location].location, 1, false, &value[0, 0])
}

camera_get_view_matrix :: proc(camera: ^Camera) -> glm.mat4 {
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

	ctx.shader = shader_load()
	shader_bind(&ctx.shader)

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	vertices := []Vertex {
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
	}

	indices := []u16{0, 1, 2, 2, 3, 0}

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	ctx.camera.position = {0.0, 0.0, 3.0}
	ctx.camera.up = {0.0, 1.0, 0.0}
	ctx.camera.front = {0.0, 0.0, -1.0}
	ctx.camera.fovy = 50
	ctx.camera.near = 0.1
	ctx.camera.far = 100.0

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
				case .SIZE_CHANGED:
					WINDOW_WIDTH = auto_cast event.window.data1 * 2
					WINDOW_HEIGHT = auto_cast event.window.data2 * 2
				}
			}
		}

		// camera_bind(ctx.camera)
		// shader_bind(ctx.shader)

		model := glm.identity(glm.mat4)
		view := camera_get_view_matrix(&ctx.camera)
		proj := glm.mat4Perspective(
			glm.radians(ctx.camera.fovy),
			WINDOW_WIDTH / WINDOW_HEIGHT,
			ctx.camera.near,
			ctx.camera.far,
		)
		u_transform := proj * view * model
		shader_set_uniform_mat4(&ctx.shader, "u_transform", &u_transform)

		// fmt.println(WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.Viewport(0, 0, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

		SDL.GL_SwapWindow(window)
	}
}
