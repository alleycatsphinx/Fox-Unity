#ifndef SOBEL
    #define SOBEL
		
	#ifndef SPHERICAL_FIBONACCI
		#include "Includes\spherical_fibonacci.cginc"
	#endif 

	float map_sobel_force(float3 position)
	{
		float radius 		= CPU.sim.input.radius;
		float3 origin 		= float3(0., 0., 0.);
		float3 direction 	= float3(0., 0., 0.);
		
		float range 		= 0.;
		float minima 		= 0xFFFFFFFF;
		float weight 		= 0.;
		const int count 	= 32;
		for(int i = 0; i < count; i++)
		{
			direction 		= spherical_fibonacci(i, count) * .5;
			weight 			= frac(frac(i + 1. + CPU.debug.k * 1234.5678) * i + i * 1234.56789);

			range 			= projection(position, origin + direction * weight * GPU.sim.input.length, origin + direction, radius);
			minima 			= min(range, minima);
		}

		return minima;
	} 

	float3 derivative_sobel_force( in float3 position, in float epsilon)
	{
		float2 offset	= float2(epsilon, -epsilon);

		return (offset.xyy * map_sobel_force(position + offset.xyy)
			  + offset.yyx * map_sobel_force(position + offset.yyx)
			  + offset.yxy * map_sobel_force(position + offset.yxy)
			  + offset.xxx * map_sobel_force(position + offset.xxx)) * rcp(epsilon);
	}
#endif