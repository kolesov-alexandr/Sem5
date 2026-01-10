// EdgeDetectionSimple.hlsl - максимально простой

cbuffer cbSettings : register(b0)
{
    float2 gTexelSize; // 1.0 / width, 1.0 / height
    float gEdgeThreshold; // Порог обнаружения границ
    float gPadding;
};

Texture2D gInputTex : register(t0);
SamplerState gsamPointClamp : register(s1);

struct VertexOut
{
    float4 PosH : SV_POSITION;
    float2 TexC : TEXCOORD;
};

VertexOut VS(uint vid : SV_VertexID)
{
    VertexOut vout;
    
    float2 texCoord = float2((vid << 1) & 2, vid & 2);
    vout.PosH = float4(texCoord * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f), 0.0f, 1.0f);
    vout.TexC = texCoord;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    float2 texCoord = pin.TexC;
    
    // Центральный пиксель
    float3 centerColor = gInputTex.Sample(gsamPointClamp, texCoord).rgb;
    
    // 4 соседних пикселя
    float3 upColor = gInputTex.Sample(gsamPointClamp, texCoord + float2(0, gTexelSize.y)).rgb;
    float3 downColor = gInputTex.Sample(gsamPointClamp, texCoord - float2(0, gTexelSize.y)).rgb;
    float3 leftColor = gInputTex.Sample(gsamPointClamp, texCoord - float2(gTexelSize.x, 0)).rgb;
    float3 rightColor = gInputTex.Sample(gsamPointClamp, texCoord + float2(gTexelSize.x, 0)).rgb;
    
    // Вычисляем разницу в яркости
    float centerLum = dot(centerColor, float3(0.299, 0.587, 0.114));
    float upLum = dot(upColor, float3(0.299, 0.587, 0.114));
    float downLum = dot(downColor, float3(0.299, 0.587, 0.114));
    float leftLum = dot(leftColor, float3(0.299, 0.587, 0.114));
    float rightLum = dot(rightColor, float3(0.299, 0.587, 0.114));
    
    // Вычисляем градиенты
    float gradientX = (rightLum - leftLum);
    float gradientY = (downLum - upLum);
    
    // Магнитуда градиента
    float edgeMagnitude = sqrt(gradientX * gradientX + gradientY * gradientY);
    
    // Пороговая обработка
    float edge = edgeMagnitude > gEdgeThreshold ? 1.0 : 0.0;
    
    return float4(edge, 0, 0, 1.0);
}