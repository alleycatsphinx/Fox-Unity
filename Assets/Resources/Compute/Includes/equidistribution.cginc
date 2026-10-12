#ifndef EQUIDISTRIBUTION
    #define EQUIDISTRIBUTION

    //https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/

    #ifndef UINT6
        #define UINT6
        struct uint6
        {
            uint u; 
            uint v; 
            uint w;
            uint x;
            uint y;
            uint z;
        };
        #endif

    #ifndef UINT8
        #define UINT8
        struct uint8 
        {
            uint s; 
            uint t; 
            uint u;
            uint v;
            uint w;
            uint x;
            uint y;
            uint z;
        };
    #endif

    float equidistribute_line(uint id)
    {        
        return fmod(id * rcp(1.6180339887498948482) + .5, 1.); 
    }


    float2 equidistribute_plane(uint id)
    {
        const float g   = 1.32471795724474602596;

        float2 position = id 
                        * rcp(float2(g, g * g))
                        + float2(.5, .5); 

        return fmod(position, float2(1., 1.));
    }
    

    float3 equidistribute_cube(uint id)
    {
        const float g   = 1.22074408460575947536;
        
        float3 position = id
                        * rcp(float3(g, g * g, g * g * g))
                        + float3(.5, .5, .5);

        return fmod(position, float3(1., 1., 1.));
    }


    float3 equidistribute_cube2(uint id)
    {
        const float g   = 1.1127756842787055;
        
        float3 position = id
                        * rcp(float3(g * g, g * g * g, g * g * g * g))
                        + float3(.5, .5, .5);

        return fmod(position, float3(1., 1., 1.));
    }


    float3 equidistribute_hexeract(uint id)
    {
        float3 r        = equidistribute_cube(id);
        float3 q        = equidistribute_cube(id>>3);
        float phi       = sqrt(5.)*.5-.5;

        return q.zxy - r.zxy + (q.xyz + r.xyz) * phi;
    }


    uint equidistribute_thread(in uint x)
    {
        return (((x + 2654435761) * 2654435761) % 0xFFFFFFFF) % 262144;
    }


    uint equidistribute_n(in uint x, in uint n)
    {
        return (((x + 2654435761) * 2654435761) % 0xFFFFFFFF) % n;
    }
#endif