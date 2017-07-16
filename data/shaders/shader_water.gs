#version 330

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in vec2 TexCoord0[];
in vec3 Normal0[];
in float isSurface0[];
in vec3 WorldPos0[];
in vec3 Tangent0[];

out vec2 TexCoord;
out vec3 Normal;
out float isSurface;
out vec3 WorldPos;
out vec3 Tangent;


void main()
{
    for (int i = 0; i < 3; i++)
    {
        TexCoord = TexCoord0[i];
        Normal = Normal0[i];
        isSurface = isSurface0[i];
        WorldPos = WorldPos0[i];
        Tangent = Tangent0[i];
        gl_Position = gl_in[i].gl_Position;
        EmitVertex();
    }
    EndPrimitive();
}
