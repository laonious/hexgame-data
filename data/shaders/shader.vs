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
uniform float waveTime;
uniform bool drawGrid;

uniform bool isWater;
uniform bool withOutline;

uniform mat4 gBones[MAX_BONES];
uniform bool skeletalAnimation;

out vec2 TexCoord0;
out vec3 Normal0;
out float isSurface0;
out vec3 WorldPos0;
out vec3 Tangent0;



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

struct waveInfo
{
	float amplitude;
	float length;
	float speed;

	vec2 direction;
};

const int numWaves = 15;
const float waveSteepness = 3.f;
vec3 getWaveContribution(float x, float y, float t, waveInfo Wave)
{
    vec3 C = vec3(0.f,0.f,0.f);
    float w = .1*sqrt(9.81 * 6.28 / Wave.length);
	float phase_const = Wave.speed * 6.28 / Wave.length;
	float steepness = waveSteepness/ (numWaves * w * Wave.amplitude);

	C.x += steepness*Wave.amplitude*Wave.direction.x*cos(w*dot(Wave.direction,vec2(x,y))+phase_const*t);
	C.z += steepness*Wave.amplitude*Wave.direction.y*cos(w*dot(Wave.direction,vec2(x,y))+phase_const*t);
	C.y += Wave.amplitude * sin(w * dot(Wave.direction,vec2(x,y)) + phase_const*t);

    return C;
}

vec3 getNormalContribution(float x, float y, float t, waveInfo Wave)
{
	vec3 C = vec3(0.f,0.f,0.f);
    float w = .1*sqrt(9.81 * 6.28 / Wave.length);
    float steepness = waveSteepness/ (numWaves * w * Wave.amplitude);
    float phase_const = Wave.speed * 6.28 / Wave.length;

    C.x -= Wave.amplitude * cos( ( w * dot(Wave.direction,vec2(x,y)) + phase_const*t) ) * w * Wave.direction.x;
    C.z -= Wave.direction.y * w * Wave.amplitude * cos(w*dot(Wave.direction,vec2(x,y))+phase_const*t);

    C.y += 1/numWaves- steepness * w * Wave.amplitude * sin(w * dot(Wave.direction,vec2(x,y)) + phase_const*t);

	return C;
}


void main()
{
    float gridFactor;
    isSurface0 = 0.0f;
    vec3 gridNormalModifier = vec3(0.00000001,0,0);

    waveInfo waves[15];

    waves[0] = waveInfo(.25f,   .25f, .05f, normalize(vec2(1.f,1.f)));
    waves[1] = waveInfo(.12f,  .10f, .025f,normalize(vec2(1.05f,.95f)));
    waves[2] = waveInfo(.3f,   .05f, 0.01f,normalize(vec2(.7f,1.5f)));
    waves[3] = waveInfo(.2f,   .05f,  .012f,normalize(vec2(-1.2f,.7f)));
    waves[4] = waveInfo(.25f,  .02f, .018f,normalize(vec2(-1.1f,.9f)));

    waves[5] = waveInfo(.11f,  .12f, .045f, normalize(vec2(1.2f,.8f)));
    waves[6] = waveInfo(.12f,  .08f, .015f,normalize(vec2(1.15f,.90f)));
    waves[7] = waveInfo(.25f,   .05f, 0.002f,normalize(vec2(.8f,-1.2f)));
    waves[8] = waveInfo(0.05f,  .10f, .07f,normalize(vec2(1.1f,-.8f)));
    waves[9] = waveInfo(.2f,  .07f, .028f,normalize(vec2(1.25f,-.75f)));

    waves[10]= waveInfo(.1f,   .01f, .01f, normalize(vec2(0.3f,1.f)));
    waves[11]= waveInfo(.1f,   .01f, .01f, normalize(vec2(-0.2f,1.f)));
    waves[12]= waveInfo(.1f,   .01f, .01f, normalize(vec2(0.1f,8.f)));
    waves[13]= waveInfo(.1f,   .01f, .01f, normalize(vec2(0.3f,1.f)));
    waves[14]= waveInfo(.1f,   .01f, .01f, normalize(vec2(-0.1f,1.f)));


    vec3 positionOutput = Position;
    vec3 normalOutput = Normal;

    if (skeletalAnimation)
    {
	    positionOutput = (BoneTransform() * vec4(positionOutput,1.0)).xyz;
	    normalOutput = (BoneTransform() * vec4(normalOutput, 0.0)).xyz;
    }
    Normal0 = (gObject * vec4(normalOutput, 0.0)).xyz;
    TexCoord0 = TexCoord;


//  grid stuff
    if ( drawGrid )
    {
    if ( positionOutput.y == 0 && !isWater) {
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
    float waveHeight = .25f;
    if ( isWater  && positionOutput.y >= 0.f)
    {
	isSurface0 = 1.0f;
	positionOutput.y = -waveHeight;
	for ( int i = 0; i < numWaves; i ++ )
	{
	positionOutput += 1.f/numWaves * getWaveContribution(positionOutput.x,positionOutput.z,-waveTime,waves[i]);
	Normal0 += 2.f/numWaves * getNormalContribution(positionOutput.x,positionOutput.z,-waveTime, waves[i]);
	}
    }
    if ( drawGrid && gridFactor < .9f && positionOutput.y > -.5f )
	{
	positionOutput.y -= (1-gridFactor) * .1f;
	gridNormalModifier = (1-gridFactor) * (gWorld * vec4(positionOutput.x,0,positionOutput.z,1.0)).xyz;
	}

	Normal0 = normalize(Normal0 - gridNormalModifier);
        gl_Position = gWVP * vec4(positionOutput, 1.0);



    Normal0 = (gWorld * vec4(Normal0, 0.0)).xyz;
    Tangent0 = (gWorld * gObject * vec4(Tangent, 0.0)).xyz;
    WorldPos0 = (gWorld * vec4(positionOutput, 1.0)).xyz;
}
