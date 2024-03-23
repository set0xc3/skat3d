#version 460 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec4 a_color;
layout(location = 2) in vec2 a_uv;

out vec4 v_color;
uniform mat4 u_mvp;

void main() {
    gl_Position = u_mvp * vec4(a_position, 1.0);
    v_color = a_color;
}

#split

#version 460 core

in vec4 v_color;
out vec4 o_color;

void main() {
    o_color = v_color;
}
