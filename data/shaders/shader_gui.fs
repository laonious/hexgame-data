#version 330

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D gSampler;

void main()
{	
    FragColor = texture2D(gSampler, TexCoord.xy);
}
