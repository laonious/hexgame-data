#version 330

out vec4 FragColor;
uniform int gI;
uniform int gJ;
uniform int gLayer;
uniform int gOmitFromPicking;

void main()
{
    FragColor = vec4(gI/20.0,gJ/20.0,gLayer/10.0, 1.f - gOmitFromPicking);
}
