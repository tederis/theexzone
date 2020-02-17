float4 L_hemi_color = float4(0.50f,	0.50f,	0.50f, 1.0f);
float3 L_sun_color = float3(1.000f,  0.6f,  0.3f);
float3 L_sun_dir_w = float3(-0.3395f, -0.4226f, -0.8403f);
float3 L_ambient = float3(0.071f,   0.07f,  	0.079f);

//Point lights
float3 PointLightPosition[5];
float3 PointLightColor[5];
float PointLightRadius[5];

//Spotlights
float3 SpotLightPosition[5];
float3 SpotLightDirection[5];
float3 SpotLightColor = float3(0.976, 1, 0.721);
float SpotLightCosAngle = 0.9263f;

//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#define GENERATE_NORMALS
#include "mta-helper.fx"


//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};


//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float4 c0	: TEXCOORD2;
    float4 c1	: COLOR1;
    float3 WorldPos : TEXCOORD3;
};


//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    //-- Calculate screen pos of vertex
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);

    PS.WorldPos = mul(float4(VS.Position, 1), gWorld);

    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;

    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );

    PS.c0		= float4 		(L_hemi_color.rgb, 1);
	PS.c1 		= float4 		(L_sun_color*0.6f, 1);

    return PS;
}


//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    //-- Get texture pixel
    float4 t_base = tex2D(Sampler0, PS.TexCoord);

    float3 l_base = 0;
    float nightFactor = 1.0f - saturate( ( L_ambient.r + L_ambient.g + L_ambient.b ) * 2.0f );
    
    //Point lights
	for(int i = 0; i < 5; i++)
	{	
		float3 Light = PointLightPosition[i] - PS.WorldPos;
		float Attenuation = saturate(1.0f - length(Light) / PointLightRadius[i]);
		
		l_base += Attenuation*Attenuation * PointLightColor[i] * nightFactor * 2.0f; 
	}

    float val = 1.0f / (1.0f - SpotLightCosAngle);

    //Spotlights
	for(int i = 0; i < 5; i++)
	{
        float3 Light = PS.WorldPos - SpotLightPosition[i];        

        // Затухание по конусу
        float fac = dot(normalize(Light), SpotLightDirection[i]);        
        float cone = saturate((fac - SpotLightCosAngle) * val);

        // Затухание по расстоянию
        float Attenuation = saturate(1.0f - length(Light) / 20.0f);

		l_base += cone * Attenuation*Attenuation * SpotLightColor * nightFactor * 2.0;
	}

    // lighting
	float3	l_hemi 	= PS.c0 * t_base.a;			// hemi
	float3 	l_sun 	= PS.c1 * 0.34f;			// sun color
	float3	light	= l_base + L_ambient + l_sun + l_hemi;

    float3	final 	= (light*t_base.rgb*3.0f)*PS.Diffuse;

    // out
	return  float4	(final.rgb, 1);
}


//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
    }
}

//-- Fallback
technique fallback
{
    pass P0
    {
        //-- Replace texture
        Texture[0] = gTexture0;

        //-- Leave the rest of the states to the default settings
    }
}