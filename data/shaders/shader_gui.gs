#version 330

layout(triangles) in;
layout(triangle_strip, max_vertices=3) out;

in vec2 TexCoord0[];



out vec2 TexCoord;


void main()
{
	for (int i = 0; i < 3; i++)
	{
		TexCoord = TexCoord0[i];
		gl_Position = gl_in[i].gl_Position;
		EmitVertex();
	}
	EndPrimitive();
}
