#ifndef TERRRAIN
    #define TERRAIN

////new terrain!
    float tri2(in float x)   
    { 
        float phi = sqrt(5.) * .5 + .5;
        return abs(frac(x*phi)-.5)/phi;;
    }


    // float tri1(in float x)   
    // { 
    //     // float k = abs(cos(time * .03)) * .5;
    //     return abs(frac(x + k)-.5)-k;
    // }

    float tri0(in float x)   
    { 
        return abs(frac(x)-.5);
    }


    float tri(in float x)   
    { 
        return tri0(x);//abs(frac(x)-.5);
    }

    float3 tri3(in float3 p)
    {
        return float3(tri0(p.z), tri0(p.y), tri0(p.x));
    }

    float terrain(float3 position)
    {
            const float3 rotation_euler         = float3(CPU.debug.a, CPU.debug.b, CPU.debug.c);
            const float3 position_offset        = float3(CPU.debug.d, CPU.debug.e, CPU.debug.f);
            
            const float rotation_scale          =  1.95; //CPU.debug.g;
            const float position_scale          =   .27; //CPU.debug.h;
            const float fold_scale              =  .025; //CPU.debug.i;
            const float weight_scale            =  1.69; //CPU.debug.j;
            const float radius_scale            =  5.85; //CPU.debug.k;
            const float radius_field_scale      =   .02; //CPU.debug.l;
            const float field_scale             =  3.58; //CPU.debug.m;
            const float amplitude               =  .015; //CPU.debug.n;
            const float mass_offset             = -.00899; //CPU.debug.o;

            float mass                          = length(position) * position_scale;        
            float3x3 rotation                   = rmat(rotation_euler) * rotation_scale;        

            float weight                        = 1.;
            float field                         = 0.;
            float radius                        = 0.;
            float3 fold                         = float3(0.,0.,0.); 
            const float iterations              = 16.;
            float fmax                          = 0.;
            float fmin                          = 999999999.;
            for(float i = 0.; i < iterations; i++)
            {     
                weight                          = (i+1.) * (1./iterations);

                position                        = mul(position + position_offset, rotation);
                position                        *= pow(1. + weight, weight_scale);

                fold                            += tri3(position);
                fold                            = mul(fold, rotation);

                radius                          = tri(tri(tri(fold.x)+fold.y)+fold.z) * fold_scale;
                radius                          *= radius_scale;
                radius                          += field * (1.-weight) * radius_field_scale;
            
                field                           += tri(radius) * weight;
                field                           *= field_scale;
                
                fmin                            = min(field, fmin);
                fmax                            = max(field, fmax);
            }   

            field                               = lerp(fmin, fmax, -1.19); //bleh 
            field                               = field * .0000001;

            return (mass + field * amplitude ) - mass_offset;
    } 
    //////


 //    float tri(in float x)   
 //    { 
 //        return abs(frac(x)-.5);
 //    }


 //    float3 tri3(in float3 p)
 //    {
 //        return float3(tri(p.z + tri(p.y)), tri(p.y + tri(p.x)), tri(p.x + tri(p.z)));
 //    }

 // // float3 spherical(float3 p)
 // // {
 // //    float r     = sqrt(p.x*p.x + p.y*p.y + p.z*p.z);
 // //    float theta = atan2(p.z, p.x);           // azimuth (longitude), in [-π, π]
 // //    float phi   = acos(p.y / r);
 // //    return float3(r, theta, phi);
 // // }

 //    float terrain2(in float3 position, in float frequency, in float amplitude, in float lacunarity, in float drift, in float iterations)
 //    {
 //        float n                 = 0.;
 //        float3 origin           = position;
 //        float3 t                = position * frequency;
 //        float decay             = CPU.debug.g;
 //        float3x3 rotation       = rmat(normalize(float3(CPU.debug.a,CPU.debug.b,CPU.debug.c)));
 //        float radius            = 0.;
        
 //        const float limit        = 16.;
 //        float weight            = 1.;
 //        for(float i = 0.; i < limit; i++)
 //        {       
 //            if(i < iterations)
 //            {
 //                weight          = (1 + iterations - i) * rcp(iterations);
 //                position        = mul(rotation, position);
 //                position        = lerp(position + n * CPU.debug.f * weight, position.zxy - n * CPU.debug.f * weight, drift);
                
 //                t               = position * frequency;   

 //                t               += tri3(t * CPU.debug.g) * CPU.debug.h * (1.-weight);     
 //                radius          += tri(t.z-tri(t.y-tri(t.x))) * CPU.debug.i * weight;

 //                n               = abs(radius * amplitude - amplitude - n);

 //                amplitude       *= decay;
 //                frequency       *= lacunarity;          
 //            }
 //        }

 //        return n;
 //    }


 //    //todo rewrite 
 //    float terrain(float3 position) 
 //    {   
 //        float mass          = length(position);        

 //        float frequency     = CPU.map.planet.frequency;             //2.22
 //        float amplitude     = CPU.map.planet.amplitude;             //12.3
 //        float lacunarity    = CPU.map.planet.lacunarity;            //3.27
 //        float drift         = CPU.map.planet.drift;                 //-0.1
 //        float magnitude     = CPU.map.planet.magnitude * .00001;    //5.
 //        float threshold     = CPU.map.planet.threshold * .001;      //1.
 //        float iterations    = CPU.map.planet.iterations;            //10.

 //        float field         = terrain2(position, frequency, amplitude, lacunarity, drift, iterations);
 //        float surface       = mass - .5 + field * magnitude;            
 //        surface             = (lerp(surface, surface * .99, 64.)) - threshold;
 //        return surface;
 //    }
#endif


    // float terrain2(in float3 position, in float frequency, in float amplitude, in float lacunarity, in float drift)
    // {
    //     float n                 = 3.13;//CPU.rendering.shadow.debug.z;
    //     float3 origin           = position;
    //     float3 t                = position * frequency;
    //     float decay             = rcp(lacunarity);
    //     // float2x2 rotation   = rmat(atan(1.) * CPU.rendering.shadow.debug.x);
    //     float2x2 rotation       = rmat(atan(1.) * 5.);
    //     float radius            = -15.2;//CPU.rendering.shadow.debug.w;
    //     const uint iterations   = 12;
    //     for(int i = 0; i < iterations; i++)
    //     {       
    //         if(i < CPU.rendering.occlusion.debug.w)
    //         {
    //             position        = lerp(position, -position.zxy, drift).zxy;
    //             position.xy     = mul(rotation, position.xy);
                
    //             t               = position * frequency;     
    //             t               += tri3(t * -2.18 + n * .0003) * (1. + rcp(iterations.-i) * -3.92);     
    //             radius          += tri(t.z-tri(t.y-tri(t.x))) * 5.17;
    //             n               = abs(radius * amplitude - amplitude - n);
                
    //             amplitude       *= decay;
    //             frequency       *= lacunarity;          
    //         }
    //     }

    //     return n;
    // }


    // //todo rewrite 
    // float terrain(float3 position) 
    // {   
    //     float mass          = length(position);        

    //     float frequency     = CPU.map.planet.debug.x; 
    //     float amplitude     = CPU.map.planet.debug.y;
    //     float lacunarity    = CPU.map.planet.debug.z;
    //     float drift         = CPU.map.planet.debug.w;
    //     float magnitude     = CPU.map.planet.threshold;

    //     float field         = terrain2(position, frequency, amplitude, lacunarity, drift);
    //     float surface       = mass - .5 + field * CPU.map.planet.threshold;            
    //     surface             = (lerp(surface, surface * .99, 64.)) - CPU.rendering.ray.focus.x;
    //     return surface;

/////origional
    // float tri(in float x)   
    // { 
    //     return abs(frac(x)-.5);
    // }


    // float3 tri3(in float3 p)
    // {
    //     return float3(tri(p.z + tri(p.y)), tri(p.y + tri(p.x)), tri(p.x + tri(p.z)));
    // }


    // // float3 tri3(in float3 p)
    // // {
    // //     return float3(tri(p.z + cos(p.y)), tri(p.y + sin(p.x)), tri(p.x + cos(p.z)));
    // // }


    // float triNoise3d(in float3 p, in float spd)
    // {
    //     float z         =.99;
    //     float rz        = 0.;
    //     float3 bp       = p;
    //     // for (float i=0.; i<1.; i++ )
    //     {
    //         p           += tri3(bp * 2.);
    //         bp          *= 1.200014;
    //         z           *= 1.5-rz*.025;
    //         p           *= 1.4+rz*.0000123;            
    //         rz          += (tri(p.z+tri(p.x+tri(p.y)))) * rcp(z);
    //         bp          += 0.5;
    //     }

    //     return rz;
    // }

    // float tf(in float3 p, in float spd, in float f, in float a, in float r)
    // {
    //     float n          = 0.;
    //     p                -= 1.25009;

    //     for(int i = 0; i < 12; i++)
    //     {
    //                     n = abs(a - n - triNoise3d(p * f, spd)*a);
    //                     a *= .4;
    //                     f *= 3.000015;      
    //                     p = lerp(p, p.zxy, frac(n-.5)*r*-.0005);

    //                     if(n <= 0.)
    //                     {
    //                         break;
    //                     }
    //     }
        
    //     return n;
    // }


    // //todo rewrite 
    // float terrain(float3 p) 
    // {   
    //     float mass      = length(p);        
    //     float field     = tf(p, 0., 1.25, 64., 1.);

    //     float radius    = CPU.map.planet.debug.x; 
    //     float mul_scale = CPU.map.planet.debug.y;
    //     float exp_scale = CPU.map.planet.debug.z;
    //     float sum_scale = CPU.map.planet.debug.w;

    //     float surface   = mass - radius + (field * mul_scale + pow(field, exp_scale)) * sum_scale;            
        
    //     return surface > .0125 ? surface : min(surface,  .005) * CPU.map.planet.threshold;        
    // }    