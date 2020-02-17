#include "tex_matrix.fx"

texture Tex;

float2 gUVPrePosition = float2( 0, 0 );
float2 gUVScale = float( 1 );                     // UV scale
float2 gUVScaleCenter = float2( 0.5, 0.5 );
float gUVRotAngle = -1.57f;                   // UV Rotation
float2 gUVRotCenter = float2( 0.5, 0.5 );
float2 gUVPosition = float2( 0, 0 );              // UV position

float3x3 getTextureTransform()
{
    return makeTextureTransform( gUVPrePosition, gUVScale, gUVScaleCenter, gUVRotAngle, gUVRotCenter, gUVPosition );
}

technique tec0
{
	pass P0
    {
		Texture[0] = Tex;
		
		TextureTransform[0] = getTextureTransform();
		
		TextureTransformFlags[0] = Count2;
	}
}

technique fallback
{
    pass P0
    {
        
    }
}