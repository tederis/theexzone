//-----------------------------------------------------------------------
//-- Settings
//-----------------------------------------------------------------------
texture TexLMap;   //-- Replacement texture
texture TexBase;   //-- Replacement texture
texture TexDet;

texture Tex1;
texture Tex2;
texture Tex3;
texture Tex4;

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
sampler Sampler1 = sampler_state
{
    Texture = (Tex1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
};
sampler Sampler2 = sampler_state
{
    Texture = (Tex2);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
};
sampler Sampler3 = sampler_state
{
    Texture = (Tex3);
     MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
};
sampler Sampler4 = sampler_state
{
    Texture = (Tex4);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
};

sampler SamplerLMap = sampler_state
{
    Texture = (TexLMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
};
sampler SamplerBase = sampler_state
{
    Texture = (TexBase);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
}; 
sampler SamplerDet = sampler_state
{
    Texture = (TexDet);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
    AddressU = MIRROR; 
    AddressV = MIRROR;
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
    float2 TexCoord2 : TEXCOORD1;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
    float4 c0	: TEXCOORD2;
    float4 c1	: COLOR1;
    float3 WorldPos : TEXCOORD3;
};

//float3 	v_sun 		(float3 n)		{	return L_sun_color*max(0,dot(n,-L_sun_dir_w));		}
float2 	calc_detail 	(float3 w_pos)	{ 
	float  	dtl	= distance(w_pos,gCameraPosition)*0;
	dtl	= min(dtl*dtl, 1);
	float  	dt_mul	= 1  - dtl;	// dt*  [1 ..  0 ]
	float  	dt_add	= .5 * dtl;	// dt+	[0 .. 0.5]
	return	float2	(dt_mul,dt_add);
}
 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
    
    MTAFixUpNormal( VS.Normal );
 
    float2 	dt 	= calc_detail		(VS.Position);
 
    //-- Calculate screen pos of vertex
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
    PS.TexCoord2 = VS.TexCoord;
 
    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );

    PS.WorldPos = mul(float4(VS.Position, 1), gWorld);
    //--
    //-- NOTE: The above line is for GTA buildings.
    //-- If you are replacing a vehicle texture, do this instead:
    //--
    //--      // Calculate GTA lighting for vehicles
    //--      float3 WorldNormal = MTACalcWorldNormal( VS.Normal );
    //--      PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal, VS.Diffuse );
    
    PS.c0		= float4 		(L_hemi_color.rgb,dt.x);		// c0=hemi+v-lights, 	c0.a = dt*
	PS.c1 		= float4 		(L_sun_color*0.6f,dt.y);		// c1=sun, 		c1.a = dt+
 
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
    float4	t_base 	= tex2D		(SamplerBase, PS.TexCoord);
	float4	t_lmap 	= tex2D		(SamplerLMap, PS.TexCoord2);

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
	float3 	l_sun 	= PS.c1 * t_lmap.a;			// sun color
	float3	light	= l_base + L_ambient + l_sun + l_hemi;

	// calc D-texture
	float4	t_dt 	= tex2D(SamplerDet, PS.TexCoord);

    float4 texel1 = tex2D(Sampler1, PS.TexCoord * 99);
    float4 texel2 = tex2D(Sampler2, PS.TexCoord * 99);
    float4 texel3 = tex2D(Sampler3, PS.TexCoord * 99);
    float4 texel4 = tex2D(Sampler4, PS.TexCoord * 199);
    
    float w = 0.25f;
    
    float4 det = lerp(0, texel1, clamp( 1 - (0.5 - t_dt.r)/w, 0, 1));
    det = lerp(det, texel2, clamp( 1 - (0.5 - t_dt.g)/w, 0, 1));
    det = lerp(det, texel3, clamp( 1 - (0.5 - t_dt.b)/w, 0, 1));
    det = lerp(det, texel4, clamp( 1 - (0.5 - t_dt.a)/w, 0, 1));
    
    float3 	detail	= det*PS.c0.a + PS.c1.a;
	
	// final-color
	float3	final 	= (light*t_base.rgb)*detail*8*PS.Diffuse;

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