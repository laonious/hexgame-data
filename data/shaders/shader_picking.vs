#version 330
#define M_PI 3.1415926535897932384626433832795
const int MAX_BONES = 100;

layout (location = 0) in vec3 Position;                                             
layout (location = 1) in vec2 TexCoord;                                             
layout (location = 2) in vec3 Normal;

layout (location = 3) in vec3 Tangent;

layout (location = 4) in ivec4 BoneIDs;

layout (location = 5) in vec4 Weights;

uniform mat4 gWVP;
uniform mat4 gWorld;
uniform mat4 gObject;
uniform bool isWater;
uniform bool withOutline;
uniform float waveTime;
uniform bool drawGrid;

uniform mat4 gBones[MAX_BONES];
uniform bool skeletalAnimation;

out vec2 TexCoord0;
out vec3 Normal0;
out float isSurface0;
out vec3 WorldPos0;
out vec3 Tangent0;

struct waveInfo
{
	float waveSpeed;
	float waveHeight;
	float waveLength;
	vec2 waveDirection;
	float offset;
};

vec3 getWaveContribution(float x, float y, float t, waveInfo Wave)
{
    vec3 Contribution = vec3(0.f,0.f,0.f);
    float parameter = -dot( normalize(Wave.waveDirection) , vec2( x, y) ) + Wave.offset;

    Contribution.y += Wave.waveHeight *  sin( parameter/Wave.waveLength + t * Wave.waveSpeed );

    return Contribution;
}

vec3 getNormalContribution(float x, float y, float t, waveInfo Wave)
{
	vec3 C = vec3(0.f,0.f,0.f);
        float parameter = -dot( normalize(Wave.waveDirection) , vec2( x, y) ) + Wave.offset;

	C.z += Wave.waveHeight * cos( parameter/Wave.waveLength + t * Wave.waveSpeed ) / Wave.waveLength * Wave.waveDirection.y; 

	C.x += Wave.waveHeight * cos( parameter/Wave.waveLength + t * Wave.waveSpeed ) / Wave.waveLength * Wave.waveDirection.x; 
	return C;
}

bool isInteger( float x )
{
	float epsilon = 0.05f;
	if ( abs( round(x) - x ) < epsilon ) { return true; }

	return false;
}

float hexagonEquation(float x, float y)
{
	float value = 1.f;
	if ( isInteger((y + x/sqrt(3.0f)-1.f)/2.f) ) { value = .1f; }
	else if ( isInteger((y - x/sqrt(3.0f)-1.f)/2.f) ) { value =  0.1f; }
	else if ( isInteger( x * x - 3.f/4.f ) ) { value = 0.1f; }
	return value;
	
}

mat4 BoneTransform()
{
	mat4 T = gBones[BoneIDs[0]] * Weights[0];
	 T += gBones[BoneIDs[1]] * Weights[1];
	 T += gBones[BoneIDs[2]] * Weights[2];
	 T += gBones[BoneIDs[3]] * Weights[3];
	return T;
}

void main()
{
    float gridFactor;
    isSurface0 = 0.0f;
    vec3 gridNormalModifier = vec3(0.00000001,0,0);
    int numWaves = 10;
    waveInfo waves[10];
    //                 speed,   amp, length, direction, offset
    waves[0] = waveInfo(1.f,   .25f, .5f, normalize(vec2(1.f,1.f)),0.f);
    waves[1] = waveInfo(1.2f,  .10f, .25f,normalize(vec2(1.05f,.95f)),0.f);
    waves[2] = waveInfo(3.f,   .05f, 0.1f,normalize(vec2(.7f,1.5f)),0.f);
    waves[3] = waveInfo(4.f,   .05f,  .12f,normalize(vec2(1.2f,.7f)),.7f);
    waves[4] = waveInfo(2.5f,  .02f, .18f,normalize(vec2(1.1f,.9f)), 2.f);

    waves[5] = waveInfo(1.1f,  .12f, .45f, normalize(vec2(1.2f,.8f)),0.f);
    waves[6] = waveInfo(1.2f,  .08f, .15f,normalize(vec2(1.15f,.90f)),0.f);
    waves[7] = waveInfo(2.f,   .05f, 0.2f,normalize(vec2(.8f,1.2f)),0.f);
    waves[8] = waveInfo(0.5f,  .10f, .7f,normalize(vec2(1.1f,.8f)),.7f);
    waves[9] = waveInfo(1.5f,  .15f, .28f,normalize(vec2(1.25f,.75f)), 2.f);

    vec3 positionOutput = Position;
    vec3 normalOutput = Normal;

    if (skeletalAnimation)
    {
	    positionOutput = (BoneTransform() * vec4(positionOutput,1.0)).xyz;
	    normalOutput = (BoneTransform() * vec4(normalOutput, 0.0)).xyz;
    }
	

//  grid stuff
    if ( drawGrid )
    {
    if ( positionOutput.y == 0 ) {
	    gridFactor = hexagonEquation( Position.x, Position.z );
    }
    else
    {
	    gridFactor = 1.f;
    }
    }
//-----------

    positionOutput = (gObject * vec4(positionOutput + 0.02f * int(withOutline) * normalOutput, 1.0)).xyz;

    float waveWidth = 2.f;
    float waveHeight = .15f;
    if ( isWater  && positionOutput.y >= 0.f)
    {
	isSurface0 = 1.0f;
	positionOutput.y = -waveHeight;
	for ( int i = 0; i < numWaves; i ++ )
	{
	positionOutput += 1.0f/numWaves * getWaveContribution(positionOutput.x,positionOutput.z,waveTime, waves[i]);
	}
    }
    if ( drawGrid && gridFactor < .9f && positionOutput.y > -.5f )
	{
	positionOutput.y -= (1-gridFactor) * .1f;
	}
	
	Normal0 = normalize(Normal0 - gridNormalModifier);
    gl_Position = gWVP * vec4(positionOutput, 1.0);
	
}
