#ifndef SIM_INPUT
	#define SIM_INPUT

	float map_input_force(float3 position)
	{
		float radius 		= CPU.sim.input.radius;
		float3 direction 	= normalize(CPU.selection.ray);
		float3 origin 		= CPU.rendering.projection.position + direction * radius;
		float3 extent  		= origin + direction * GPU.sim.input.length;

		return projection(position, origin, extent, radius);
	} 


	float3 derivative_input_force( in float3 position, in float epsilon)
	{
		float2 offset	= float2(epsilon, -epsilon);

		return (offset.xyy * map_input_force(position + offset.xyy)
			  + offset.yyx * map_input_force(position + offset.yyx)
			  + offset.yxy * map_input_force(position + offset.yxy)
			  + offset.xxx * map_input_force(position + offset.xxx)) * rcp(epsilon);
	}

	float map_input_force_ball(float3 position)
	{
		float radius 		= CPU.sim.input.radius;
		float3 direction 	= normalize(CPU.selection.ray);
		float3 origin 		= CPU.rendering.projection.position + direction * GPU.sim.input.length;
		
		return length(origin) + radius;
	} 


	float3 derivative_input_force_ball( in float3 position, in float epsilon)
	{
		float2 offset	= float2(epsilon, -epsilon);

		return (offset.xyy * map_input_force_ball(position + offset.xyy)
			  + offset.yyx * map_input_force_ball(position + offset.yyx)
			  + offset.yxy * map_input_force_ball(position + offset.yxy)
			  + offset.xxx * map_input_force_ball(position + offset.xxx)) * rcp(epsilon);
	}
#endif
