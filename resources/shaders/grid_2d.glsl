#version 460 core

layout(location = 0) in vec3 a_position;

uniform mat4 u_transform;
uniform vec4 u_color;

void main() {
    gl_Position = u_transform * vec4(a_position, 1.0);
}

#split

#version 460 core
// #extension GL_EXT_geometry_shader4 : enable

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

void main() {
    // Создаем четырехугольник из одной точки
    gl_Position = gl_in[0].gl_Position + vec4(-0.5, -0.5, 0.0, 0.0); // Нижняя левая вершина
    EmitVertex();

    gl_Position = gl_in[0].gl_Position + vec4(0.5, -0.5, 0.0, 0.0); // Нижняя правая вершина
    EmitVertex();

    gl_Position = gl_in[0].gl_Position + vec4(-0.5, 0.5, 0.0, 0.0); // Верхняя левая вершина
    EmitVertex();

    gl_Position = gl_in[0].gl_Position + vec4(0.5, 0.5, 0.0, 0.0); // Верхняя правая вершина
    EmitVertex();

    EndPrimitive();
}

#split

#version 460 core

layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(1.0, 0.0, 1.0, 1.0);
}
