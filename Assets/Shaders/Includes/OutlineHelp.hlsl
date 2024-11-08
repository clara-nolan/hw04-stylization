SAMPLER(sampler_point_clamp);

#ifndef SOBELOUTLINES_INCLUDED
#define SOBELOUTLINES_INCLUDED

// The sobel effect runs by sampling the texture around a point to see
// if there are any large changes. Each sample is multiplied by a convolution
// matrix weight for the x and y components separately. Each value is then
// added together, and the final sobel value is the length of the resulting float2.
// Higher values mean the algorithm detected more of an edge.

// These are points to sample relative to the starting point
static float2 sobelSamplePoints[9] =
{
    float2(-1, 1), float2(0, 1), float2(1, 1),
    float2(-1, 0), float2(0, 0), float2(1, 0),
    float2(-1, -1), float2(0, -1), float2(1, -1),
};

// Weights for the x component
static float sobelXMatrix[9] =
{
    1, 0, -1,
    2, 0, -2,
    1, 0, -1
};

// Weights for the y component
static float sobelYMatrix[9] =
{
    1, 2, 1,
    0, 0, 0,
    -1, -2, -1
};

/// Random noise function
float2 RandomOffset(float2 uv, float time)
{
    float jitterAmount = 0.002; 
    float noiseX = frac(sin(dot(uv, float2(12323.212, 8821.2)) + time) * 123999.5453);
    float noiseY = frac(sin(dot(uv, float2(186452.232, 11.135)) + time) * 12731.5313);
    return float2(noiseX, noiseY) * jitterAmount;
}

// Sine wave function for smoother UV jitter
float SineWave(float time, float frequency, float amplitude)
{
    return sin(time * frequency) * amplitude;
}

void DepthSobel_float(float2 UV, float Thickness, float Time, float Frequency, out float Out)
{
    float frequency = Frequency;
    float amplitude = 0.02; 

    // Apply sine wave for smooth, oscillating UV offset
    float sineWave = SineWave(Time, frequency, amplitude);
    float2 animatedUV = UV + float2(sineWave, sineWave);

    // Add a jitter effect for sketch-like outline
    animatedUV += RandomOffset(UV, Time);

    float2 sobel = 0;

    [unroll]
    for (uint i = 0; i < 9; i++)
    {
        float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(animatedUV + sobelSamplePoints[i] * Thickness);
        sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);
    }
    Out = length(sobel);
}

// This function runs the sobel algorithm over the depth texture
void DepthSobelNoJitter_float(float2 UV, float Thickness, out float Out)
{
    float2 sobel = 0;

    // We can unroll this loop to make it more efficient
    // The compiler is also smart enough to remove the i=4 iteration, which is always zero
    [unroll]
    for (int i = 0; i < 9; i++)
    {
        float depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV + sobelSamplePoints[i] * Thickness);
        sobel += depth * float2(sobelXMatrix[i], sobelYMatrix[i]);
    }

    // Get the final sobel value
    Out = length(sobel);
}

#endif


void GetDepth_float(float2 uv, out float Depth)
{
    Depth = SHADERGRAPH_SAMPLE_SCENE_DEPTH(uv);
}


void GetNormal_float(float2 uv, out float3 Normal)
{
    Normal = SAMPLE_TEXTURE2D(_NormalsBuffer, sampler_point_clamp, uv).rgb;
}