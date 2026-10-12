#ifndef FRACTAL
    #define FRACTAL

    float fractal(float3 position)
    {
        float3 rotation             = CPU.field.fractal.rotation.xyz;
        float3 translation          = float3(CPU.field.fractal.translation.xyz) * CPU.field.fractal.translation.w;
        float threshold             = CPU.field.fractal.threshold;

        int iterations              = 32;

        float3x3 rotation_matrix    = rmat(rotation);

        float scale                 = CPU.field.fractal.rotation.w;
        float norm                  = pow(abs(scale), -float(iterations) - 1.);

        for(int i = 0; i < iterations; i++) 
        {
            position                = abs(mul(position, rotation_matrix)) * scale - translation;    
        }
        
        return abs(max(max(position.x, position.y), position.z)) * norm - norm * threshold;
    }


    float3 map_fractal_color(float3 position) //focus == 2
    {
        return float3(.5, .5, .5);
        // float3 rotation             = CPU.field.fractal.rotation.xyz;
        // float3 translation          = float3(CPU.field.fractal.translation.xyz) * CPU.field.fractal.translation.w;
        // float threshold             = CPU.field.fractal.threshold;

        // int iterations              = 32;

        // float3x3 rotation_matrix    = rmat(rotation);

        // float scale                 = CPU.field.fractal.rotation.w;
        // float norm                  = pow(abs(scale), -float(iterations) - 1.);
        // float3 color                = float3(0., 0., 0.);

        // for(int i = 0; i < iterations; i++) 
        // {
        //     position                = abs(mul(position, rotation_matrix)) * scale - translation;    
            
        //     color                   += cos(position * i);
        // }
        
        // return color;
    }
#endif
