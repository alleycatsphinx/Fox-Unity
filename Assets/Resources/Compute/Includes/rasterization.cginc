#ifndef RASTERIZATION
	#define RASTERIZATION
	
	#include "Includes\matrices.cginc"
	#include "Includes\cube.cginc"
	#include "Includes\bitmaps.cginc"
	#include "Includes\bitwise.cginc"
	#include "Includes\equidistribution.cginc"

	//built in unity rendering data
	float4 unity_CameraWorldClipPlanes[6];
	float4 _WorldSpaceCameraPos;
	float4 _ScreenParams;
	float4x4 unity_MatrixVP;
	//

	bool in_screen(in int2 coordinate)
	{
		return coordinate.x >= 0 && coordinate.y >= 0 && coordinate.x < _ScreenParams.x && coordinate.y < _ScreenParams.y;		
	}


	float3 uv_to_ray(float2 uv) 
	{
	   	float3 direction = mul(CPU.rendering.projection.inverse, float4(uv * 2. - 1., 0., 1.0f)).xyz;
	  	direction 		 = mul(CPU.rendering.projection.to_world, float4(direction, 0.0f)).xyz;  	
	    return normalize(direction);
	}

	bool in_frustrum(in float3 position)
	{
		//view pyramid clip plane positions offset from origin with sign (not including front and back)
		float4 left		= unity_CameraWorldClipPlanes[0];
		float4 right 	= unity_CameraWorldClipPlanes[1];
		float4 bottom 	= unity_CameraWorldClipPlanes[2];
		float4 top 		= unity_CameraWorldClipPlanes[3];
		float4 near 	= unity_CameraWorldClipPlanes[4];
		float4 far 		= unity_CameraWorldClipPlanes[5];
		return (dot(float4(position, 1.),   left) >= 0.)
			&& (dot(float4(position, 1.),  right) >= 0.)
			&& (dot(float4(position, 1.), bottom) >= 0.)
			&& (dot(float4(position, 1.),    top) >= 0.)
			&& (dot(float4(position, 1.),   near) >= 0.);
			// && (dot(float4(position, 1.),    far) < 0.);	
	}


	float2 intersect(float2 p11,float2 p12,float2 p21,float2 p22)
    {   
    	float2 n0  = (p12-p11).yx * float2(-1, 1);
        float2 n1  = (p22-p21).yx * float2(-1, 1);
        
        float d0   = dot(n0*p11, float2(1.,1.));
        float d1   = dot(n1*p21, float2(1.,1.));

        float2x2 d = float2x2(n0.x, n0.y, n1.x, n1.y); 
        float2x2 x = float2x2(d0, n0.y, d1, n1.y); 
        float2x2 y = float2x2(n0.x, d0, n1.x, d1);  
        
        return float2(determinant(x)*rcp(determinant(d)),determinant(y)*rcp(determinant(d)));       
    }


	void bound_segment(inout float4 v, in float2 resolution, out bool visible)
    {
        visible                             = true;

        if(v.x == v.z && v.y == v.w)
        {
            visible                         = true;
            return;
        }
     
        float3 b                            = float3(resolution, -1.);
        float4 p;           
        p.x                                 = v.x < b.x ? v.x < b.z ? -1. : 0. : 1.;
        p.y                                 = v.y < b.y ? v.y < b.z ? -1. : 0. : 1.;
        p.z                                 = v.z < b.x ? v.z < b.z ? -1. : 0. : 1.;
        p.w                                 = v.w < b.y ? v.w < b.z ? -1. : 0. : 1.;
                    
        if((p.x == p.z && p.x != 0.) || (p.y == p.w && p.y != 0.))
        {
            visible                         = false;
            return;
        }
        else
        {   
            bool xy_in                      = p.x == 0. && p.y == 0.;
            bool zw_in                      = p.z == 0. && p.w == 0.;   
                    
            v                               = xy_in ? v : v.zwxy;
            bool swap                       = xy_in;

            if(!xy_in || !zw_in)        
            {       
                float2 intercept            = float2(0.,0.);
                float2 minima               = float2(0x0FFFFFFF,0x0FFFFFFF);
                float2 maxima               = float2(0xFFFFFFFF,0xFFFFFFFF);    
                float4 intersection         = float4(0., 0., 0., 0.);

                intersection.xy             = v.x < v.z ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
                intersection.zw             = v.y < v.w ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
                minima                      = min(intersection.xy, intersection.zw);
                maxima                      = max(intersection.xy, intersection.zw);
                        
                intercept.x                 = abs(v.x-minima.x) < abs(v.x-maxima.x) ? minima.x : maxima.x;
                intercept.y                 = abs(v.y-minima.y) < abs(v.y-maxima.y) ? minima.y : maxima.y;                  
                
                if(intercept.x != v.x && intercept.y != v.y)    
                {
                    if(!xy_in && !zw_in)        
                    {           
                        if(intercept.x != v.x  && intercept.y != v.y && intercept.x != v.z && intercept.y != v.w)               
                        {   
                            intersection.xy = v.z < intercept.x ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
                            intersection.zw = v.w < intercept.y ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
                            minima          = min(intersection.xy, intersection.zw);
                            maxima          = max(intersection.xy, intersection.zw);
                        
                            v.x             = abs(v.x-minima.x) <= abs(v.x-maxima.x) ? minima.x : maxima.x;
                            v.y             = abs(v.y-minima.y) <= abs(v.y-maxima.y) ? minima.y : maxima.y;  
                            
                            if((intercept.x == v.x && intercept.y == v.y) || (intercept.x == v.z && intercept.y == v.w))               
                            {   
                                visible     = false;
                            }                           
                        }   
                        else
                        {
                            visible         = false;
                            return;
                        }
                    }
                    
                    v.zw                    = intercept;                         
                }                           
            }            
            v                               = swap ? v.zwxy : v;
        }       

        b                       += float3(1., 1., -1.);
        p.x                     = v.x < b.x ? v.x < b.z ? -1. : 0. : 1.;
        p.y                     = v.y < b.y ? v.y < b.z ? -1. : 0. : 1.;
        p.z                     = v.z < b.x ? v.z < b.z ? -1. : 0. : 1.;
        p.w                     = v.w < b.y ? v.w < b.z ? -1. : 0. : 1.;
                    
        if(p.x != 0. || p.y != 0. || p.z != 0. || p.w != 0.)
        {
            visible                         = false;
            return;
        }   
    }


	float distance_to_view(in float3 position)
	{
		return length(position.xyz - _WorldSpaceCameraPos.xyz);
	}


	float3 direction_to_view(in float3 position)
	{
		return normalize(_WorldSpaceCameraPos.xyz - position.xyz);
	}


	int2 view_projection_coordinate(in float3 position) 
	{	
		float4 projection = mul(unity_MatrixVP, float4(position.xyz, 1.));
		return int2(0, _ScreenParams.y) + int2((projection.xy * rcp(projection.w) * _ScreenParams.xy) + _ScreenParams.xy) * float2(.5, -.5);
	}


    void raster_bitmap(uint bitmap, float size, float4 color, int2 coordinate, RWTexture2D<float4> target)
    {    
       	uint i              = 0;
    	uint j              = 0;
  	    	
        for(float y = 0.; y < 5. * size; y++)
        {                   
            for(float x = 0.; x < 3. * size; x++)
            {               
                if(read_32(bitmap, i + j))
                {        
					target[coordinate + float2(x,y)] += color;                   
                }           
                j 	+= (x % size) >= (size - 1.) ? 1 : 0;     
            }   
            j 		= 0;        
            i 		+= (y % size) >= (size - 1.) ? 3 : 0; 
        }	
    }


    void raster_digit(uint digit, float size, float4 color, int2 coordinate, RWTexture2D<float4> target)
    {      
        uint i              = 0;
        uint j              = 0;

        uint bitmap   		= digit == 1 ? _1
                            : digit == 2 ? _2
                            : digit == 3 ? _3
                            : digit == 4 ? _4
                            : digit == 5 ? _5
                            : digit == 6 ? _6
                            : digit == 7 ? _7
                            : digit == 8 ? _8
                            : digit == 9 ? _9
                            :              _0;

        raster_bitmap(bitmap, size, color, coordinate, target);
    }


    void raster_uint(float n, float size, float4 color, bool center, int2 coordinate, RWTexture2D<float4> target)
    {
    	size = min(size, 8.);

    	if(center)
    	{
        	coordinate.x  += (n == 0. ? 2. : 4. * floor(log10(max(n, 1.))) * .5 + 2.) * size;
        }

		float place = 1.;            
        for(float i = 0.; i < 24.; i++)
        {                   
            if(n >= place || i == 0.)
            {
                coordinate.x  -= size * 4;
                raster_digit((n * rcp(place)) % 10, size, color, coordinate, target);                            
                place *= 10.;
            }
            else
            {
            	break;
            }
        }
    }


 	void raster_string(uint characters[32], uint length, float size, float4 color, int2 coordinate, RWTexture2D<float4> target)
    {    
    	uint bitmap 		= 0;

    	for(uint i = 0; i < min(length, 32); i++)
    	{
	     	bitmap 			= characters[i];

	     	if(bitmap && 0x0000FFFF != 0)
	     	{
	     		raster_bitmap(bitmap, size, color, coordinate, target);	
	     	}
	     	
	     	coordinate.x 	+= 4 * size;

	     	if(bitmap && 0xFFFF0000 != 0)
	     	{
	     		bitmap 		>>= 16;
	     		raster_bitmap(bitmap, size, color, coordinate, target);	
	     	}

	     	coordinate.x 	+= 4 * size;
    	}
    }
    

	void raster_box(float size, float4 color, int2 coordinate, RWTexture2D<float4> target)
	{
		uint offset 			= max(size / 2, 1);
		uint2 coordinate_min 	= coordinate - offset;
		uint2 coordinate_max 	= coordinate + offset - 1;
		for(float i = 0.; i < size; i++)
		{						
			target[coordinate_min + uint2(i,0)]		+= color;
			target[coordinate_max - uint2(i,0)]		+= color;

			if(i > 0 && i < size - 1)
			{
				target[coordinate_min + uint2(0,i)]	+= color;
				target[coordinate_max - uint2(0,i)]	+= color;
			}
		}
	}


	void raster_vertex_address(uint vertex, uint size, float4 color, int2 coordinate, RWTexture2D<float4> target)
	{
		uint i 		= 0;
		uint j 		= 0;
					
		for(uint y = 0; y < 9 * size; y++)
		{					
			for(uint x = 0; x < 3 * size; x++)
			{				
				if(read_32(vertex, i + j))
				{			
					target[coordinate + uint2(x,y)] += color;
				}	
				else
				{
					target[coordinate + uint2(x,y)] += color * .125;
				}		
				j += (x + 1) % size == 0 ? 1 : 0;		
			}	
			j = 0;		
			i += (y + 1) % size == 0 ? 3 : 0;	
		}
	}


	void raster_line(float3 position_origin, float3 position_extent, uint limit, float4 color, RWTexture2D<float4> target)
	{				
		float depth 								= 0xFFFFFFFF;

		bool visible 								=  in_frustrum(position_origin) || in_frustrum(position_extent);
													// && dot(direction_to_view(position_origin), direction_to_view(position_extent)) > .85;
		if(visible)
		{		
			int2 coordinate_origin					= view_projection_coordinate(position_origin);
			int2 coordinate_extent		 			= view_projection_coordinate(position_extent);
			
			int2 minima 							= int2(0,0);
			float2 maxima 							= _ScreenParams.xy;
			
			float4 coordinate_pair 					= float4(coordinate_origin, coordinate_extent);			
			
			bound_segment(coordinate_pair, maxima, visible); 
			
			coordinate_origin 						= coordinate_pair.xy;
			coordinate_extent 						= coordinate_pair.zw;
			
			bool4 o_in          					= bool4(coordinate_origin.x >= minima.x, coordinate_origin.x < maxima.x, coordinate_origin.y >= minima.y, coordinate_origin.y < maxima.y);
        	bool4 e_in          					= bool4(coordinate_extent.x >= minima.x, coordinate_extent.x < maxima.x, coordinate_extent.y >= minima.y, coordinate_extent.y < maxima.y);
     		
     		visible 								= any(o_in) || any(e_in);
			
			float4 color_out	 					= float4(0., 0., 0., 0.);
			uint halt 								= 24;//min((uint)CPU.debug.o, 64);
			uint collision 							= 0;
			if((in_screen(coordinate_origin) || in_screen(coordinate_extent)) && visible)
			{						
				float depth_origin					= distance_to_view(position_origin);
				float depth_extent					= distance_to_view(position_extent);				
				depth 								= min(depth_origin, depth_extent);
				
				if(depth_origin < depth_extent)
				{
					float temp 						= depth_origin;
					depth_origin 					= depth_extent;
					depth_extent 					= temp;

					coordinate_pair.xy 				= coordinate_origin;
					coordinate_origin 				= coordinate_extent;
					coordinate_extent 				= coordinate_pair.xy;
				}

				int coordinate_span					= min(ceil(length(coordinate_origin-coordinate_extent)) , min(limit, 2048.));
				
				int2 coordinate 					= int2(0,0); 
				int2 coordinate_prior				= int2(0,0);
				
				float frequency 					= rcp(coordinate_span);
				
				float interpolant					= 0.;	
				
				bool parity  						= true;
				for(float n = 0.; n < coordinate_span; n++)
				{							
					// interpolant						= (n * frequency);
					interpolant						= equidistribute_line(n);
	
					interpolant 					= parity ? interpolant : 1. - interpolant;
						
					coordinate_prior 	 			= coordinate;
					coordinate 						= lerp(coordinate_origin, coordinate_extent, interpolant);							
						
					float4 prior_target 			= target[coordinate];
 					
					depth							= lerp(depth_origin, depth_extent, interpolant);									

					if(depth < prior_target.w || prior_target.w == 0.)// && (coordinate_prior.x != coordinate.x) || (coordinate_prior.y != coordinate.y))
					{ 
						coordinate_prior			= coordinate;
						color_out.w 				= depth;
						color_out.xyz				= clamp(target[coordinate].xyz + color.xyz * clamp(pow(rcp(1. + depth), 12.) * 255., .0125, 1.), 0., 1.);
						
						target[coordinate] 			= color_out;
					}
					else if(collision < halt)
					{
						collision++;
						parity 						= !parity;
					}
					else
					{
						break;
					}
				}			
			}	
		}					
	}		
	
	void raster_circle(float3 position, float scale, uint limit, float4 color, RWTexture2D<float4> target)
	{
		float depth 								= 0xFFFFFFFF;

		bool visible 								= in_frustrum(position);

		if(visible)
		{		
			int2 coordinate			= view_projection_coordinate(position);

			float prior_depth		= target[coordinate].w;
			float depth 			= distance_to_view(position);

			if(prior_depth > depth)
			{
				color.w  				= depth;
				//target[coordinate] 		= float4(clamp(color.xyz + target[coordinate].xyz, 0., 1.), depth); 

				float2 offset 			= float2(0.,0.);
				float interpolant 		= 0.;
				float circumference 	= scale * 6.28;
				float arc				= rcp(circumference);
				
				for(float i = 0.; i < circumference; i++)
				{		
					
					offset						= mul(float2(scale, 0.), rmat(6.28 * i * arc));	
					target[coordinate + offset]	= float4(target[coordinate + offset].xyz + color.xyz, color.w);
				}
			}
		}
	}

	void raster_line(float3 position_origin, float3 position_extent, uint limit, float4 color, float4x4 transform, RWTexture2D<float4> target)
	{				
		position_origin = mul(transform, float4(position_origin, 1.)).xyz;
		position_extent = mul(transform, float4(position_extent, 1.)).xyz;
		
		raster_line(position_origin, position_extent, limit, color, target);
	}

	
	void rasters_quad(float3 position, float scale, uint limit, float4 color, RWTexture2D<float4> target)
	{									
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(1) * scale, limit, color, target);
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(2) * scale, limit, color, target);				
		raster_line(position + cube_vertex(1) * scale, position + cube_vertex(3) * scale, limit, color, target);				
		raster_line(position + cube_vertex(2) * scale, position + cube_vertex(3) * scale, limit, color, target);				
	}


	void raster_cube(float3 position, float scale, uint limit, float4 color, RWTexture2D<float4> target)
	{										
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(1) * scale, limit, color, target);
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(2) * scale, limit, color, target);
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(4) * scale, limit, color, target);
		raster_line(position + cube_vertex(1) * scale, position + cube_vertex(3) * scale, limit, color, target);
		raster_line(position + cube_vertex(1) * scale, position + cube_vertex(5) * scale, limit, color, target);
		raster_line(position + cube_vertex(2) * scale, position + cube_vertex(3) * scale, limit, color, target);
		raster_line(position + cube_vertex(2) * scale, position + cube_vertex(6) * scale, limit, color, target);
		raster_line(position + cube_vertex(3) * scale, position + cube_vertex(7) * scale, limit, color, target);
		raster_line(position + cube_vertex(4) * scale, position + cube_vertex(5) * scale, limit, color, target);
		raster_line(position + cube_vertex(4) * scale, position + cube_vertex(6) * scale, limit, color, target);
		raster_line(position + cube_vertex(5) * scale, position + cube_vertex(7) * scale, limit, color, target);
		raster_line(position + cube_vertex(6) * scale, position + cube_vertex(7) * scale, limit, color, target);	
	}


	void raster_cube(float3 position, float scale, uint limit, float4 color, float4x4 transform, RWTexture2D<float4> target)
	{
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(1) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(2) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(0) * scale, position + cube_vertex(4) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(1) * scale, position + cube_vertex(3) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(1) * scale, position + cube_vertex(5) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(2) * scale, position + cube_vertex(3) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(2) * scale, position + cube_vertex(6) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(3) * scale, position + cube_vertex(7) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(4) * scale, position + cube_vertex(5) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(4) * scale, position + cube_vertex(6) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(5) * scale, position + cube_vertex(7) * scale, limit, color, transform, target);
		raster_line(position + cube_vertex(6) * scale, position + cube_vertex(7) * scale, limit, color, transform, target);	
	}				


	void raster_debug_line(float4 color, int2 coordinate_origin, int2 coordinate_extent, RWTexture2D<float4> target)
	{	
		float span 				= min(length(coordinate_origin-coordinate_extent), 2048);
		float division  		= rcp(span);

		int2 coordinate 		= int2(0,0);
		for(float i = 0.; i < span; i++)
		{		
			coordinate    		= lerp(coordinate_origin,coordinate_extent, i * division);			
			if(in_screen(coordinate))
			{
				target[coordinate] 	+= color;		
			}			
		}
	}
#endif