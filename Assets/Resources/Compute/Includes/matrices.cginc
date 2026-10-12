#ifndef MATRICES 
    #define MATRICES 
    
    #ifndef TAU
        #define TAU         (8.*atan(1.))
    #endif
    

    float3x3 rmat(in float3 r)
    {
    	float3 a       = float3(cos(r.x)*cos(r.y),sin(r.y),sin(r.x)*cos(r.y));
    	
    	float c        = cos(r.z);
    	float s        = sin(r.z);
    	float3 as      = a*s;
    	float3 ac      = a*a*(1.- c);
    	float3 ad      = a.yzx*a.zxy*(1.-c);
    
    	return float3x3(
    			c    + ac.x, ad.z + as.z, ad.y - as.y,
    			ad.z - as.z, c    + ac.y, ad.x + as.x,
    			ad.y + as.y, ad.x - as.x, c    + ac.z);
    }
    
    
    float2x2 rmat(float t)
    {
    	float c = cos(t);
    	float s = sin(t);	
    	return float2x2(c, s, -s, c);
    }
    

    float4x4 hmat(float3 translation, float3 rotation, float3 scale)
    {
        float3 c        = cos(rotation);
        float3 s        = sin(rotation);

        float3 right    = float3(c.y * c.z, c.y * s.z, s.y) * scale.x;
        float3 up       = float3(s.x * s.y * c.z - c.x * s.z, s.x * s.y * s.z + c.x * c.z, -s.x * c.y) * scale.y;
        float3 forward  = float3(-(c.x * s.y * c.z + s.x * s.z), -(c.x * s.y * s.z - s.x * c.z), c.x * c.y) * scale.z;
    
        return float4x4(
                  right.x,          up.x,     forward.x, 0.0,
                  right.y,          up.y,     forward.y, 0.0,
                  right.z,          up.z,     forward.z, 0.0,
            translation.x, translation.y, translation.z, 1.0
            );
    }
    

    //this code is sus... 
    float3x3 aligned_orthonormal_basis(float3 position, float3 target, float3 direction, float3 up)
    {
        float3 forward              = direction;
        up                          = abs(dot(forward, up)) > .9999 ? float3(0., 1., 0.) : up;
        float3 right                = normalize(cross(up, forward));
        return float3x3(right, cross(forward, right), forward);
    }

#endif