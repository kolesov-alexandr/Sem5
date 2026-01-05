Texture2D gInput : register(t0);
SamplerState gsamLinearClamp : register(s3);

cbuffer cbEdgeDetection : register(b0)
{
    float2 gTexelSize;
    float gEdgeThreshold;
    float gPadding;
};

struct VertexOut
{
    float4 PosH : SV_POSITION;
    float2 TexC : TEXCOORD;
};

VertexOut VS(uint vid : SV_VertexID)
{
    VertexOut vout;
    
    vout.TexC = float2(vid & 1, (vid & 2) >> 1);
    vout.PosH = float4(vout.TexC * float2(4, -4) + float2(-1, 1), 0, 1);
    
    return vout;
}

float GetLuminance(float3 color)
{
    return dot(color, float3(0.299f, 0.587f, 0.114f));
}

float4 PS(VertexOut pin) : SV_Target
{
    float2 texCoord = pin.TexC;
    
    float3x3 Gx = float3x3(
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    );
    
    float3x3 Gy = float3x3(
        1, 2, 1,
        0, 0, 0,
        -1, -2, -1
    );
    
    float luminance[9];
    float2 offsets[9] =
    {
        float2(-1, -1), float2(0, -1), float2(1, -1),
        float2(-1, 0), float2(0, 0), float2(1, 0),
        float2(-1, 1), float2(0, 1), float2(1, 1)
    };
    
    for (int i = 0; i < 9; i++)
    {
        float2 sampleUV = texCoord + offsets[i] * gTexelSize;
        float3 color = gInput.Sample(gsamLinearClamp, sampleUV).rgb;
        luminance[i] = GetLuminance(color);
    }
    
    float edgeX = 0.0f;
    float edgeY = 0.0f;
    
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            int idx = i * 3 + j;
            edgeX += luminance[idx] * Gx[i][j];
            edgeY += luminance[idx] * Gy[i][j];
        }
    }
    
    float edgeMagnitude = sqrt(edgeX * edgeX + edgeY * edgeY);
    
    float edge = edgeMagnitude > gEdgeThreshold ? 1.0f : 0.0f;
    
    float3 originalColor = gInput.Sample(gsamLinearClamp, texCoord).rgb;
    float3 edgeColor = float3(1.0f, 0.0f, 0.0f);
    
    float3 result = lerp(originalColor, edgeColor, edge);
    
    return float4(result, 1.0f);
}