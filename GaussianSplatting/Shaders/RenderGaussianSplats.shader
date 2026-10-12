// SPDX-License-Identifier: MIT
Shader "Gaussian Splatting/Render Splats"
{
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            ZWrite Off
            Blend OneMinusDstAlpha One
            // Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma require compute
#pragma use_dxc

#include "GaussianSplatting.hlsl"

StructuredBuffer<uint> _OrderBuffer;

struct v2f
{
    half4 col 				: COLOR0;
    float2 pos 				: TEXCOORD0;
    float4 world 			: TEXCOORD1;    
    float4 vertex 			: SV_POSITION;    
};

StructuredBuffer<SplatViewData> _SplatViewData;
ByteAddressBuffer _SplatSelectedBits;
uint _SplatBitsValid;

v2f vert (uint vtxID : SV_VertexID, uint instID : SV_InstanceID)
{
    v2f o 						= (v2f)0;
    instID 						= _OrderBuffer[instID];
	SplatViewData view 			= _SplatViewData[instID];
	float4 centerClipPos 		= view.pos;
    
    SplatData splat 			= LoadSplatData(instID);

    uint idx 					= vtxID;
	float3 localPos 			= float3(idx&1, (idx>>1)&1, (idx>>2)&1) * 2.0 - 1.0;

    float3 centerWorldPos 		= float3(0.,0.,0.);

    float4 boxRot 				= splat.rot;
    float3 boxSize 				= splat.scale;
    // boxSize 					*= _SplatScale;

    float3x3 splatRotScaleMat 	= CalcMatrixFromRotationScale(boxRot, boxSize);
    splatRotScaleMat 			= mul((float3x3)unity_ObjectToWorld, splatRotScaleMat);

    centerWorldPos				= splat.pos;
    centerWorldPos				= mul(unity_ObjectToWorld, float4(centerWorldPos,1)).xyz;

    localPos 					= mul(splatRotScaleMat, localPos) * 2;

	float3 worldPos 			= centerWorldPos + localPos;

    o.world.xyz 				= worldPos.xyz;
    o.world.w 					= length(worldPos - _WorldSpaceCameraPos);

	bool behindCam 				= centerClipPos.w <= 0;
	if (behindCam)	
	{	
		o.vertex 				= asfloat(0x7fc00000); // NaN discards the primitive
	}	
	else	
	{	
		o.col.r 				= f16tof32(view.color.x >> 16);
		o.col.g 				= f16tof32(view.color.x);
		o.col.b 				= f16tof32(view.color.y >> 16);
		o.col.a 				= f16tof32(view.color.y);
		
		uint idx 				= vtxID;
		float2 quadPos 			= float2(idx&1, (idx>>1)&1) * 2.0 - 1.0;
		quadPos 				*= 2;

		o.pos 					= quadPos;

		float2 deltaScreenPos 	= (quadPos.x * view.axis1 + quadPos.y * view.axis2) * 2 / _ScreenParams.xy;
		o.vertex 				= centerClipPos;
		o.vertex.xy 			+= deltaScreenPos * centerClipPos.w;

		// is this splat selected?
		if (_SplatBitsValid)
		{
			uint wordIdx 		= instID / 32;
			uint bitIdx 		= instID & 31;
			uint selVal 		= _SplatSelectedBits.Load(wordIdx * 4);

			if (selVal & (1 << bitIdx))
			{
				o.col.a = -1;				
			}
		}
	}

	FlipProjectionIfBackbuffer(o.vertex);
    return o;
}

float3 uv_to_ray(float2 uv) 
{
   	float3 direction = mul(unity_CameraInvProjection, float4(uv * 2. - 1., 0., 1.0f)).xyz;
  	direction 		 = mul(unity_ObjectToWorld, float4(direction, 0.0f)).xyz;  	
    return normalize(direction);
}

inline float GammaToLinearSpaceExact (float value)
{
    return (value <= 0.04045) ?
        (value / 12.92) :
        pow((value + 0.055) / 1.055, 2.4);
}

inline float3 GammaToLinearSpace (float3 sRGB)
{
    return float3(
        GammaToLinearSpaceExact(sRGB.r),
        GammaToLinearSpaceExact(sRGB.g),
        GammaToLinearSpaceExact(sRGB.b)
    );
}

inline float LinearToGammaSpaceExact (float value)
{
    return (value <= 0.0031308) ?
        (12.92 * value) :
        (1.055 * pow(value, 1.0 / 2.4) - 0.055);
}

inline float3 LinearToGammaSpace (float3 lin)
{
    return float3(
        LinearToGammaSpaceExact(lin.r),
        LinearToGammaSpaceExact(lin.g),
        LinearToGammaSpaceExact(lin.b)
    );
}

inline float4 LinearToGammaSpace (float4 lin)
{
    return float4(LinearToGammaSpace(lin.rgb), lin.a);
}

half4 frag (v2f i) : SV_Target
{
	float power 			= -dot(i.pos, i.pos);
	half alpha 				= exp(power);
	if (i.col.a >= 0)
	{
		alpha 				= saturate(alpha * i.col.a);
	}
	else
	{		
		// "selected" splat: magenta outline, increase opacity, magenta tint
		half3 selectedColor = half3(1,0,1);
		if (alpha > 7.0/255.0)
		{
			if (alpha < 10.0/255.0)
			{
				alpha 		= 1;
				i.col.rgb 	= selectedColor;
			}
			alpha 			= saturate(alpha + 0.3);
		}

		i.col.rgb 			= lerp(i.col.rgb, selectedColor, 0.5);
	}

	
	float bound 				= .5;
    bool bounded 				=  (i.world.x < bound && i.world.x > -bound)
    							&& (i.world.y < bound && i.world.y > -bound)
    							&& (i.world.z < bound && i.world.z > -bound);

    if (alpha < 1.0/255.0)
    {
        discard;
    }

	//i.world.rgb					+= .5;
	//i.col.rgb 					= i.world.rgb * float(bounded);
	
	//i.col.rgb 					= LinearToGammaSpace(i.col.rgb / alpha);
	//i.col.rgb 					= GammaToLinearSpace(i.col.rgb);
	
    half4 res 					= half4(i.col.rgb * alpha, alpha); 

    return res;
}
ENDCG
        }
    }
}
