#vertex
#version 460 core

layout(location = 0) in vec3 a_position;

uniform mat4 u_transform;
uniform vec4 u_color;

void main() {
    gl_Position = u_transform * vec4(a_position, 1.0);
}

#geometry
#version 460 core

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

void main() {
    gl_Position = gl_in[0].gl_Position + vec4(-0.5, -0.5, 0.0, 0.0);
    EmitVertex();
    gl_Position = gl_in[0].gl_Position + vec4(0.5, -0.5, 0.0, 0.0);
    EmitVertex();
    gl_Position = gl_in[0].gl_Position + vec4(-0.5, 0.5, 0.0, 0.0);
    EmitVertex();
    gl_Position = gl_in[0].gl_Position + vec4(0.5, 0.5, 0.0, 0.0);
    EmitVertex();
    EndPrimitive();
}

#fragment
#version 460 core

layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(1.0, 0.0, 1.0, 1.0);
}
