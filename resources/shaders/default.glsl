#version 460 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec4 a_color;

out Data {
    vec4 color;
} data_out;

uniform mat4 u_transform;

void main() {
    gl_Position = u_transform * vec4(a_position, 1.0);

    data_out.color = a_color;
}

#split

#version 460 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

// From Vertex Shader
in Data {
    vec4 color;
} data_in[];

// Out Fragment Shader
out vec4 color;

void main() {
    gl_Position = gl_in[0].gl_Position;
    color = data_in[0].color;
    EmitVertex();

    gl_Position = gl_in[1].gl_Position;
    color = data_in[1].color;
    EmitVertex();

    gl_Position = gl_in[2].gl_Position;
    color = data_in[2].color;
    EmitVertex();

    EndPrimitive();
}

#split

#version 460 core

in vec4 color;

out vec4 o_color;

void main() {
    o_color = color;
}
