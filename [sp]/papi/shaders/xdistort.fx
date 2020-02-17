#include "mta-helper.fx"

texture Tex0;
texture Screen;
float2 ScreenSize;

float Bumpyness = 1.0f;
float RefractFactor = 0.5f;

sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};
sampler SamplerScreen = sampler_state
{
    Texture = (Screen);
};

struct VSInput
{
    float3 Position : POSITION;
	float3 Normal : NORMAL0;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse  : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float4 TexCoord2 : TEXCOORD1;
};

PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;	
 
    PS.Position = MTACalcScreenPosition ( VS.Position );

	//float4 posWorld = mul(float4(VS.Position, 1), gWorld);
	//float4 posWorldView = mul(gViewInverse, posWorld);
	//float4 tt = mul(posWorldView, gProjection);

	PS.TexCoord = VS.TexCoord;

    PS.TexCoord2 = PS.Position;
	
    PS.Diffuse = VS.Diffuse;
 
    return PS;
}
 
float4 PixelShaderExample(PSInput PS) : COLOR0
{
    float2 screenPos = PS.TexCoord2.xy / PS.TexCoord2.w;	
	float4 screenTexel = tex2D(SamplerScreen, float2(screenPos.x + 1.0f, (1.0f - screenPos.y)) / 2.0f);

    //float4 distortTexel = tex2D(Sampler0, PS.TexCoord);

	return screenTexel;// * PS.Diffuse;

	/*float3 distort=tex2D(Sampler0,PS.TexCoord).rgb;
    distort=normalize(distort*2-1)*Bumpyness;
    float dist = (distort.r*distort.g*distort.b)*(distort.r*distort.g*distort.b);




	float4 Texture = float4(1,1,1,1);
    float2 nuv = IN.Proj.xy/IN.Proj.z + dist;
    float3 Refract=tex2D(Screen,nuv).rgb;
    OUT.Color = float4(lerp(Texture.rgb,Refract,RefractFactor), Texture.a);*/
} 

technique complercated
{
    pass P0
    {
		SrcBlend = SrcAlpha; 
		DestBlend = InvSrcAlpha;
		
		ALPHAREF = 0;
		
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}