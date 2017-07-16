#version 330

const int MAX_POINT_LIGHTS = 3;
const int MAX_SPOT_LIGHTS = 3;

in vec4 gWeights;
in vec2 TexCoord;
in vec3 Normal;
in vec3 Tangent;
in vec3 WorldPos;
in float isSurface;
out vec4 FragColor;
uniform sampler2D gSampler;
uniform sampler2D gNormal;
uniform bool gPicking;
uniform vec3 cameraDirection;
uniform int gI;
uniform int gJ;
uniform int gLayer;
uniform bool isWater;
uniform bool withOutline;
uniform bool drawGrid;
uniform mat4 gBones[100];
uniform bool skeletalAnimation;
uniform bool bumpMap;

struct BaseLight
{
    vec3 Color;
    float AmbientIntensity;
    float DiffuseIntensity;

};

struct DirectionalLight
{
    BaseLight Base;
    vec3 Direction;
};
struct Attenuation
{
    float Constant;
    float Linear;
    float Exp;
};
struct PointLight
{
    BaseLight Base;
    vec3 Position;
    Attenuation Atten;
};

struct SpotLight
{
    PointLight Base;
    vec3 Direction;
    float Cutoff;
};
uniform DirectionalLight gDirectionalLight;
uniform int gNumPointLights;
uniform PointLight gPointLights[MAX_POINT_LIGHTS];
uniform int gNumSpotLights;
uniform SpotLight gSpotLights[MAX_SPOT_LIGHTS];

vec4 CalculateLighting( BaseLight Light, vec3 LightDirection, vec3 Normal )
{
    vec4 AmbientColor = vec4(Light.Color, 1.0f) * Light.AmbientIntensity;
    AmbientColor.a = 1.f;
    float diffuseFactor = dot( normalize(Normal), -LightDirection);

    vec4 diffuseColor;
    if ( diffuseFactor > 0 )
    {
        diffuseColor = diffuseFactor * Light.DiffuseIntensity * vec4(Light.Color, 1.0f);
        diffuseColor.a = 1.f;
    }
    else
    {
        diffuseColor = vec4(0, 0,0,1);
    }

    return AmbientColor + diffuseColor;
}

vec4 CalculateDirectionalLight(vec3 Normal)
{
    return CalculateLighting(gDirectionalLight.Base, gDirectionalLight.Direction, Normal);
}

vec4 CalculatePointLight(PointLight l, vec3 Normal)
{
    vec3 LightDirection = WorldPos - l.Position;
    float Distance = length(LightDirection);
    LightDirection = normalize(LightDirection);

    vec4 Color = CalculateLighting(l.Base, LightDirection, Normal);
    float Attenuation = l.Atten.Constant +
                        l.Atten.Linear * Distance +
                        l.Atten.Exp * Distance * Distance;

    return Color / Attenuation;
}

vec4 CalculateSpotLight(SpotLight l, vec3 Normal)
{
    vec3 LightToPixel = normalize(WorldPos - l.Base.Position);
    float SpotFactor = dot(LightToPixel, l.Direction);

    if (SpotFactor > l.Cutoff)
    {
        vec4 Color = CalculatePointLight(l.Base, Normal);
        return Color * (1.0f - (1.0f - SpotFactor) * 1.0f/(1.0f -l.Cutoff));
    }
    else {
        return vec4(0.f,0.f,0.f,0.f);
    }
}
vec3 CalcBumpedNormal()
{
    vec3 Normal = normalize(Normal);
    vec3 Tangent = normalize(Tangent);
    Tangent = normalize(Tangent - dot(Tangent, Normal) * Normal);
    vec3 Bitangent = cross(Tangent, Normal);
    vec3 BumpMapNormal = texture(gNormal, TexCoord).xyz;
    BumpMapNormal = 2.0 * BumpMapNormal - vec3(1.0, 1.0, 1.0);
    vec3 NewNormal;
    mat3 TBN = mat3(Tangent, Bitangent, Normal);
    NewNormal = TBN * BumpMapNormal;
    NewNormal = normalize(NewNormal);
    return NewNormal;
}


void main()
{
    if ( gPicking )
    {
        FragColor = vec4(gI/20.0, gJ/20.0, gLayer/10.0, 1.f);
    }
    else if ( withOutline )
    {
        FragColor = vec4(0.f,0.f,0.f,1.f);
    }
    else {
        float outlineFactor;
        vec3 normal;
        if ( bumpMap && Normal.y != 0)
        {
	    normal = CalcBumpedNormal();
        }
        else
        {
            normal = Normal;
        }
        vec4 totalLight = CalculateDirectionalLight(Normal);
        for (int i = 0; i < gNumPointLights; i++)
        {
            totalLight += CalculatePointLight(gPointLights[i], normal);
        }
        for (int i = 0; i < gNumSpotLights; i++)
        {
            totalLight += CalculateSpotLight(gSpotLights[i], normal);
        }

        FragColor = texture2D(gSampler, TexCoord.xy) * totalLight;
    }
}
