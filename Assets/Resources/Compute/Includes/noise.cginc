#define NOISE

#ifndef HASHES
    #include			"/Includes/hashes.cginc"
#endif


#ifndef MATRICES
    #include            "/Includes/matrices.cginc"
#endif


float3 hash3(float3 uvw) 
{
    float3x3 m = float3x3(108.0, -35.7, -93.9, -75.3, 82.0, 39.7, -67.29, 91.0, -18.7);
    return frac(sin(mul(m, frac(mul(uvw, m))*1234.5677490234375 )));    
}

float noise( in float3 x )
{ 
    // grid
    float3 p = floor(x);
    float3 w = frac(x);
    
    // quintic interpolant
    float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    // gradients
    float3 ga = hash3( p+float3(0.0,0.0,0.0) );
    float3 gb = hash3( p+float3(1.0,0.0,0.0) );
    float3 gc = hash3( p+float3(0.0,1.0,0.0) );
    float3 gd = hash3( p+float3(1.0,1.0,0.0) );
    float3 ge = hash3( p+float3(0.0,0.0,1.0) );
    float3 gf = hash3( p+float3(1.0,0.0,1.0) );
    float3 gg = hash3( p+float3(0.0,1.0,1.0) );
    float3 gh = hash3( p+float3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-float3(0.0,0.0,0.0) );
    float vb = dot( gb, w-float3(1.0,0.0,0.0) );
    float vc = dot( gc, w-float3(0.0,1.0,0.0) );
    float vd = dot( gd, w-float3(1.0,1.0,0.0) );
    float ve = dot( ge, w-float3(0.0,0.0,1.0) );
    float vf = dot( gf, w-float3(1.0,0.0,1.0) );
    float vg = dot( gg, w-float3(0.0,1.0,1.0) );
    float vh = dot( gh, w-float3(1.0,1.0,1.0) );
	
    // interpolation
    return va + 
           u.x*(vb-va) + 
           u.y*(vc-va) + 
           u.z*(ve-va) + 
           u.x*u.y*(va-vb-vc+vd) + 
           u.y*u.z*(va-vc-ve+vg) + 
           u.z*u.x*(va-vb-ve+vf) + 
           u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
}

float4 noise_gradient( in float3 x )
{
    // grid
    float3 p = floor(x);
    float3 w = frac(x);
    
    // quintic interpolant
    float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    float3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    
    // gradients
    float3 ga = hash( p+float3(0.0,0.0,0.0) );
    float3 gb = hash( p+float3(1.0,0.0,0.0) );
    float3 gc = hash( p+float3(0.0,1.0,0.0) );
    float3 gd = hash( p+float3(1.0,1.0,0.0) );
    float3 ge = hash( p+float3(0.0,0.0,1.0) );
    float3 gf = hash( p+float3(1.0,0.0,1.0) );
    float3 gg = hash( p+float3(0.0,1.0,1.0) );
    float3 gh = hash( p+float3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-float3(0.0,0.0,0.0) );
    float vb = dot( gb, w-float3(1.0,0.0,0.0) );
    float vc = dot( gc, w-float3(0.0,1.0,0.0) );
    float vd = dot( gd, w-float3(1.0,1.0,0.0) );
    float ve = dot( ge, w-float3(0.0,0.0,1.0) );
    float vf = dot( gf, w-float3(1.0,0.0,1.0) );
    float vg = dot( gg, w-float3(0.0,1.0,1.0) );
    float vh = dot( gh, w-float3(1.0,1.0,1.0) );
	
    // interpolation
    float v = va + 
              u.x*(vb-va) + 
              u.y*(vc-va) + 
              u.z*(ve-va) + 
              u.x*u.y*(va-vb-vc+vd) + 
              u.y*u.z*(va-vc-ve+vg) + 
              u.z*u.x*(va-vb-ve+vf) + 
              u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
              
    float3 d = ga + 
             u.x*(gb-ga) + 
             u.y*(gc-ga) + 
             u.z*(ge-ga) + 
             u.x*u.y*(ga-gb-gc+gd) + 
             u.y*u.z*(ga-gc-ge+gg) + 
             u.z*u.x*(ga-gb-ge+gf) + 
             u.x*u.y*u.z*(-ga+gb+gc-gd+ge-gf-gg+gh) +   
             
             du * (float3(vb-va,vc-va,ve-va) + 
                   u.yzx*float3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) + 
                   u.zxy*float3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + 
                   u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh));
                   
    return float4( v, d);                   
}


float4 fbm_gradient(in float3 x)
{
    const float scale  = 1.;

    float a         = 0.0;
    float b         = 0.5;
	float f         = 1.0;
    float3 d        = float3(0., 0., 0.);

    for(int i = 0; i < 8; i++)
    {
        float4 n    = noise_gradient(f * x * scale);
        a           += b * n.w;                 // accumulate values		
        d           += b * n.xyz * f * scale;   // accumulate derivatives
        b           *= 0.5;                     // amplitude decrease
        f           *= 1.5;                     // frequency increase
        d.xyz       = d.zyx;
    }

	return float4(d, a);
}


float4 tessnoise(float2 p) 
{ 
	float4 base         	= float4(p, 0., 0.);
	float4 rotation       	= float4(0., 0., 0., 0.);
	
	float theta     		= .25;
	float phase				= .55;
	float frequency			= .49;
		
	//yo dog, I heard you like fractals
	float4 result      		= float4(0., 0., 0., 0.);			    
	for (float i = 0.; i < 16.; i++)	
	{		
		base				+= rotation;		
		rotation			= frac(base.wxyz - base.zwxy + theta).wxyz;		
		rotation			*= (1.-rotation);
		base				*= frequency;
		base				+= base.wxyz * phase;
	}

	return rotation * 2.;
}


// float fractal(float3 position, float3 r, float3 translation)
// {
//     int iterations              = 24;
//     float rotation_scale        = 3.;
//     float3x3 rotation           = rmat(r) * rotation_scale;
//     translation                 *= 16. * rotation_scale;
//     float scale                 = pow(rotation_scale, -(float)iterations);
//     float rate                  = (16. * rotation_scale)/float(iterations);
//     float density               = .05;

//     position                    *= 32. * 12.;
    
//     float t                     = 0.;
//     for(int i = 0; i < iterations; i++)
//     {   
//             t           += rate;
//             position    = abs(mul(position, rotation)) - translation * t;
//     }

//     return (max(max(position.x, position.y), position.z) * scale - density) * .0075;
// }
