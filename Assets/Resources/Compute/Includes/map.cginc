#ifndef MAP
    #define MAP

	#ifndef MATRICES
		#include "Includes\matrices.cginc"
	#endif

	#ifndef TERRAIN
		#include "Includes\terrain.cginc"
	#endif


	#ifndef FIELDS
		#include "Includes\fields.cginc"
	#endif


	#ifndef FRACTAL
		#include "Includes\fractal.cginc"
	#endif

	#ifndef BUNNY
		#include "Includes\bunny.cginc"
	#endif


	#ifdef DEBUG_STEP_COUNT
		uint debug_step = 0;
	#endif


	float map(float3 position) 
	{
		#ifdef DEBUG_STEP_COUNT
		debug_step++;
		#endif

		position = mul(float4(position.xyz, 1.), CPU.field.transform).xyz;

		// return bunny(position);//	fractal(position);
		return	CPU.field.function == 1 ? 		   sphere(position, CPU.field.sphere.radius)	
			  : CPU.field.function == 2 ? 		  fractal(position)			 
			  : CPU.field.function == 3 ? 		  terrain(position)	
			  :									    bunny(position);
		// 	  :									 		0x0000FFFF;
	}


	float3 derivative( in float3 position, in float epsilon)
	{
		float2 offset	= float2(epsilon, -epsilon);

		return (offset.xyy * map(position + offset.xyy)
			  + offset.yyx * map(position + offset.yyx)
			  + offset.yxy * map(position + offset.yxy)
			  + offset.xxx * map(position + offset.xxx)) * rcp(epsilon);
	}


	//5 taps total, returns both normal and curvature - nimitz
	float3 curv2(in float3 p, in float epsilon, out float curv)
	{
	    float2 e = float2(-1., 1.) * epsilon;   
	    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
	    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);

	    curv = .25/e.y*(t1 + t2 + t3 + t4 - 4.0*map(p));
	    return normalize(e.yxx*t1 + e.xxy*t2 + e.xyx*t3 + e.yyy*t4);
	}


	//Curvature only, 5 taps, with epsilon width as input - nimitz
	float norcurv(in float3 p, in float w)
	{
	    float2 e = float2(-1., 1.)*w;   
	    
	    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
	    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
	    
	    return .25/e.y*(t1 + t2 + t3 + t4 - 4.0*map(p));
	}


	//Curvature in 7-tap (more accurate) - nimitz
	float curvature(in float3 p, in float w)
	{
	    float3 e = float3(w, 0, 0);
	    
	    float t1 = map(p + e.xyy), t2 = map(p - e.xyy);
	    float t3 = map(p + e.yxy), t4 = map(p - e.yxy);
	    float t5 = map(p + e.yyx), t6 = map(p - e.yyx);
	    
	    return .25/e.x*(t1 + t2 + t3 + t4 + t5 + t6 - 6.0*map(p));
	}
#endif