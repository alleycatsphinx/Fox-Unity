#ifndef SPHERICAL_FIBONACCI
    #define SPHERICAL_FIBONACCI

    #ifndef MADOPS
        #include "/Includes/madops.cginc"
    #endif

    #ifndef PI
        #define PI			(4.*atan(1.))
    #endif

    #ifndef TAU
        #define TAU			(8.*atan(1.))
    #endif

    #ifndef PHI
        #define PHI         ((sqrt(5.)+1.)/2.)
    #endif
     
    float inverse_spherical_fibonacci(float3 p, float n) 
    {
        float phi 	= min(atan2(p.y, p.x), PI), cosTheta = p.z;
        
        float k  	= max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI*PHI)));
        float Fk 	= pow(PHI, k)/sqrt(5.0);
        
        float2 F 	= float2( round(Fk), round(Fk * PHI) );

        float2 ka 	= -2.0*F/n;
        float2 kb 	= TAU * madfrac(F+1.0, PHI-1.0) - 2.0*PI*(PHI-1.0);    
        float2x2 iB = float2x2( ka.y, -ka.x, -kb.y, kb.x );
    	iB 			/= (ka.y*kb.x - ka.x*kb.y);

        float2 c 	= floor(mul(iB, float2(phi, cosTheta - (1.0-1.0/n))));
        float d 	= 8.0;
        float j 	= 0.0;
        for(int s=0; s<4; s++) 
        {
            float2 uv				= float2(float(s-2*(s/2)), float(s/2) );
            
            float cosTheta			= dot(ka, uv + c) + (1.0-1.0/n);
            
            cosTheta 				= clamp(cosTheta, -1.0, 1.0)*2.0 - cosTheta;
            float i					= floor(n*0.5 - cosTheta*n*0.5);
            float phi				= 2.0*PI*madfrac(i, PHI-1.0);
            cosTheta				= 1.0 - (2.0*i + 1.0)/n;
            float sinTheta 			= sqrt(1.0 - cosTheta*cosTheta);
            
            float3 q 				= float3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta);
           
    		float squaredDistance 	= dot(q-p, q-p);
            if (squaredDistance < d) 
            {
                d = squaredDistance;
                j = i;
            }
        }

        return j;
    } 

    float3 spherical_fibonacci_highp(uint i, uint n) 
    {	
        n               -= 1;
        float phi 		= TAU * frac(fmod(float(i*2654435769)*rcp(n*0xFFFFFFFF), PHI));    
        float zi 		= 1. - (2. * i + PHI) * rcp(n);
        float sinTheta 	= sqrt(1. - zi * zi);
        return float3(cos(phi) * sinTheta, sin(phi) * sinTheta, zi);
    }


    float3 spherical_fibonacci(float i, float n) 
    {  	
        float phi 		= TAU * madfrac(i,PHI);
        float zi 		= 1.0 - (2. * i + 1.) * rcp(n);
        float sinTheta 	= sqrt(1. - zi * zi);
        return float3(cos(phi) * sinTheta, sin(phi) * sinTheta, zi);
    }
#endif