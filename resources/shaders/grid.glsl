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
} data_out[];

void main() {
    gl_Position = u_ * vec4(a_position, 1.0);
    data_out.normal = a_normal;
    data_out.color = a_color;
    data_out.uv = a_uv;
    data_out.projection = a_normal;
}

#split

#version 460 core

out vec4 o_color;

void main() {
    o_color = vec4(1.0, 0.0, 0.0, 1.0);
}

#split

#version 460 core

layout(triangle) in;
layout(triangle_strip, max_vertices = 3) out;

out vec3 o_normal;
out vec3 o_color;
out vec3 o_uv;

in Data {
    vec3 normal;
    vec3 color;
    vec3 uv;
    vec3 projection;
} data_in[];
