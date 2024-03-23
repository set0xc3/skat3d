#version 460 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec4 a_color;
layout(location = 3) in vec2 a_uv;

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

out Data {
    vec3 normal;
    vec3 color;
    vec3 uv;
    vec3 projection;
} data_out;

void main() {
    gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
    data_out.normal = a_normal;
    data_out.color = a_color;
    data_out.uv = a_uv;
    data_out.projection = a_normal;
}

#split

#version 460 core

out vec4 o_color;

void main() {
    o_color = vec4(1.0, 1.0, 1.0, 1.0);
}

#split

#version 460 core

layout(triangle) in;
layout(line_strip, max_vertices = 6) out;

in Data {
    vec3 normal;
    vec3 color;
    vec3 uv;
    vec3 projection;
} data_in[];

void main() {
    gl_Position = data_in[0].projection * gl_in[0].gl_Position;
    EmitVertex();
    gl_Position = data_in[0].projection * (gl_in[0].gl_Position + 0.01 * vec4(data_in[0].normal, 0.0));
    EmitVertex();
}
