#ifndef ANIMATION
    #define ANIMATION
	//This function is used to blend between different animations.
	//It uses the three variables in StructAnimation; index, interpolant, and speed. 
	//It uses both the CPU and GPU copies of the configuration, and listens for when the CPU index does not match the GPU index.
	//if a change is detected, the GPU interpolant is transitioned 
	//which then drives animation transitions. To avoid race conditions, these should only be called from single threads.
	void update_animation(in StructAnimation cpu, inout StructAnimation gpu)
	{	
		//test to see if the indices don't match or if we are in the middle of interpolating
		if(gpu.index != cpu.index)
		{
			//Test to see if the index is more than one off while in the middle of interpolating;
			//if so, skip the animation and directly set the index to match (this is for the case of the user rapidly switching indices, or directly setting one among many.)
			if(max(cpu.index, gpu.index) - min(cpu.index, gpu.index) > 1)
			{
				gpu.index 			= cpu.index;	
				gpu.interpolant		= 0.;		
			}
			else //interpolate
			{			
				float speed	= cpu.speed == 0. ? 2. : cpu.speed;
				gpu.interpolant		+= speed * CPU.status.delta_time;
				
				if(gpu.interpolant > .9999) //close enough to 1 - set the indices to match
				{
					gpu.index		= cpu.index;
					gpu.interpolant	= 0.;
				}
			}
		}
		else
		{
			gpu.interpolant	= 0.;
		}
	}
#endif