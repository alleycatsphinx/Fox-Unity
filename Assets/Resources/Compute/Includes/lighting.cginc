#ifndef LIGHTING
	#define LIGHTING

	#ifndef SPHERICAL_FIBONACCI
 		#include "/Includes/spherical_fibonacci.cginc"
	#endif

	#ifndef HASHES
 		#include "/Includes/hashes.cginc"
	#endif

	#ifndef MAP
 		#include "/Includes/map.cginc"
	#endif


	float3 sphericalharmonic(float3 n)
	{     
		float4 c[7];
		c[0] 		= float4(0.0, 0.5, 0.0, 0.4);
		c[1] 		= float4(0.0, 0.3, .05, .45);
		c[2] 		= float4(0.0, 0.3, -.3, .85);
		c[3] 		= float4(0.0, 0.2, 0.1, 0.0);
		c[4] 		= float4(0.0, 0.2, 0.1, 0.0);
		c[5] 		= float4(0.1, 0.1, 0.1, 0.0);
		c[6] 		= float4(0.0, 0.0, 0.0, 0.0);  
		
		float4 p 	= float4(n, 1.);

		float3 l1 	= float3(0., 0., 0.);
		l1.r 		= dot(c[0], p);
		l1.g 		= dot(c[1], p);
		l1.b 		= dot(c[2], p);

		float4 m2	= p.xyzz * p.yzzx;
		float3 l2 	= float3(0., 0., 0.);
		l2.r 		= dot(c[3], m2);
		l2.g 		= dot(c[4], m2);
		l2.b 		= dot(c[5], m2);

		float m3 	= p.x*p.x - p.y*p.y;
		float3 l3 	= float3(0., 0., 0.);
		l3 			= c[6].xyz * m3;

		float3 sh 	= float3(l1 + l2 + l3);

		return clamp(sh, 0., 1.);
	}


	// Fresnel-Schlick approximation
	float3 FresnelSchlick(float cosTheta, float3 F0) {
    	return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
	}


	// GGX Normal Distribution Function (Trowbridge-Reitz)
	float DistributionGGX(float3 N, float3 H, float roughness) {
	    float a = roughness * roughness;
	    float a2 = a * a;
	    float NdotH = max(dot(N, H), 0.0);
	    float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
	    return a2 / (3.14159265 * denom * denom);
	}


	// Smith's Schlick-GGX Geometry function
	float GeometrySchlickGGX(float NdotV, float roughness) {
	    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
	    return NdotV / (NdotV * (1.0 - k) + k);
	}


	// Combined geometry function for both view and light
	float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
	    float NdotV = max(dot(N, V), 0.0);
	    float NdotL = max(dot(N, L), 0.0);
	    float ggx1 = GeometrySchlickGGX(NdotV, roughness);
	    float ggx2 = GeometrySchlickGGX(NdotL, roughness);
	    return ggx1 * ggx2;
	}


	float exp2fog(float depth, float density)
	{
	  return 1.0 - clamp(exp2(pow(density * depth, 2) * -1.442695), 0.0, 1.0);
	}


	float spot_attenuation(float3 light_direction, float3 position_direction, float inner_cos, float outer_cos)
	{
	    float spot_cos 		= dot(normalize(-light_direction), normalize(position_direction));
	    return saturate((spot_cos - outer_cos) / (inner_cos - outer_cos));
	}


	// float spotlight(float3 lightDir, float3 toFragment, float innerCos, float outerCos)
	// {
	    ///flashlight
		// float3 view_direction 	= ray_direction(float2(.5, .5)); 
		// float3 light_direction2	= normalize(position - origin - view_direction * CPU.rendering.shadow.debug.w);
		// float s2 				= shadow(position, -light_direction2, epsilon, CPU.rendering.shadow.debug.x);
		// float falloff 			= clamp(CPU.rendering.shadow.debug.y - pow(depth, CPU.rendering.shadow.debug.z), 0., 1.);
		// float spot 				= spot_attenuation(light_direction2, -direction, CPU.rendering.debug.z, CPU.rendering.debug.w);
		// float3 light2 			= 10. * shade(albedo, metallic, roughness, normalize(derivative(position, .9*epsilon)), -direction, -light_direction2, float3(1., 1., 1.1), 1.);

		// color 					+= light2 * s2 * falloff * spot;
		////
	// }


	float shadow(in float3 position, in float3 light_direction, in float penumbra, in float step_size, in float min_step)
	{  
	    float exposure			= 1.; //exposure starts at one, and is gradually lowered to the smoothstepped shadow value while step size grows
	    
	    for( int i=0; i < 16; i++ ) 
	    {
	        float range 		= map(position + light_direction * step_size);
	        
	        exposure 			= lerp(min(exposure, smoothstep(0., 1., range * rcp(penumbra * step_size))), exposure, .75);

	        step_size 			+= clamp(min_step, abs(range), penumbra);
		
		  	if(exposure <= 0.) break;
	    }

	    return clamp(exposure, 0., 1.);
	}


	float ambient_occlusion( in float3 pos, in float3 nor, float depth)
	{
		float epsilon 	= CPU.rendering.occlusion.debug.x;
	    float ao 		= 0.0;
	    for( int i=0; i < 16; i++ )
	    {
	        float3 ap 	= spherical_fibonacci(i, 16.0 ) * epsilon;
	        float range = hash(float(i)) * float(1. + i * CPU.rendering.occlusion.debug.y) * epsilon;
			ap 			*= sign(dot(ap,nor)) * range; 
	        ao 			+= clamp(map(pos + nor * epsilon + ap), 0.0, 1.0 );
	    } 

		return clamp(1. - ao * CPU.rendering.occlusion.debug.z, 0., 1.);    
	}
	

	float quick_ao(float3 p, float3 n, float h) 
	{ 
		return clamp(map(p + h * n) / h, 0., 1.); 
	}


	float3 shade(float3 albedo, float roughness, float refractive_index, float3 normal, float3 view, float3 light_direction,  float3 light_color, float intensity)
	{	
	 	float3 half_view	= normalize(view + light_direction); // Half-vector
	    float3 radiance 	= light_color * intensity; // Light intensity

	    // Fresnel-Schlick for specular reflection
	    float3 F0 			= lerp(0.04, albedo, refractive_index);  // Dielectric (0.04) or metal (albedo)
	    float3 F 			= FresnelSchlick(max(dot(half_view, view), 0.0), F0);

	    // Compute BRDF components
	    float NDF 			= DistributionGGX(normal, half_view, roughness);  // GGX Normal Distribution
	    float G   			= GeometrySmith(normal, view, light_direction, roughness); // Geometry attenuation
	    float exposure 		= max(dot(normal, light_direction), 0.);
	    
	    float3 numerator   	= NDF * G * F;
	    float denominator  	= 4.0 * exposure + 0.0001;
	    float3 specular    	= numerator * rcp(denominator);

	    // Lambertian diffuse component
	    float3 kS 			= F;  						// Specular reflectance
	    float3 kD 			= 1.0 - kS; 				// Diffuse factor
	    kD 					*= 1.0 - refractive_index; 	// No diffuse for metals

	    // Final light contribution
	    return (kD * albedo / 3.14159265 + specular) * radiance * exposure;
	}


#endif

