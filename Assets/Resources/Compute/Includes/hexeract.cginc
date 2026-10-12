#ifndef HEXERACT
	#define HEXERACT

    #ifndef PHI
        #define PHI (sqrt(5.) * .5 + .5)
    #endif

    #ifndef RPHI
        #define RPHI (sqrt(5.) * .5 - .5)
    #endif

    #define PE (PHI*PHI)

    #define AA 3
    #define BB 2
    #define CC 1
    #define DD 0

    //        x   y   z   u   v   w
    // X = {  1,  φ,  0, -1,  φ,  0}    ->     x -  u + yφ + vφ    ->    x - u + (y + v)φ
    // Z = {  0,  1,  φ,  0, -1,  φ}    ->     y + zφ -  v + wφ    ->    y - v + (z + w)φ
    // Y = {  φ,  0,  1,  φ,  0, -1}    ->    xφ +  z + uφ -  w    ->    z - w + (x + u)φ 
    
    float3 hex_vertex_to_position(in uint v)
    {   
        float3 q = float3(uint3(v,v,v) >> uint3(0, 1, 2) & uint3(1, 1, 1));
        float3 r = float3(uint3(v,v,v) >> uint3(3, 4, 5) & uint3(1, 1, 1));   

        return q.zxy - r.zxy + (q.xyz + r.xyz) * RPHI;
    }


    float3 nearest_hex_vertex(in float3 position, in float3 target, in float scale, out uint id)
    {        
        float3 root             = float3(0., 0., 0.);
        float minima            = 0x0FFFFFFF;
        float range             = 0x0FFFFFFF;
        float3 delta            = float3(0., 0., 0.);
        float3 vertex           = float3(0., 0., 0.);
            
        target                  = (position + target) * rcp(scale);   
        id                      = 0;

        for (uint i = 0; i < 64; i++)        
        {                       
            root                = hex_vertex_to_position(i);
                    
            delta               = root - target;
            range               = dot(delta, delta);
            
            if(range < minima)
            {
                vertex          = root;   
                id              = i; 
                minima          = range;                
            }                                
        }

        return position - vertex * scale;
    }

        
    uint position_xyzuvw(in float3 target) //scale is probably wrong
    {
        uint vertex         = 0;        
        uint address        = 0;
        float3 position     = float3(0, 0, 0);                  
        
        position            = nearest_hex_vertex(position, target, pow(PE, AA), vertex);
        address             |= vertex;
        position            = nearest_hex_vertex(position, target, pow(PE, BB), vertex);
        address             = (address << 6) | vertex;
        position            = nearest_hex_vertex(position, target, pow(PE, CC), vertex);
        address             = (address << 6) | vertex;
        position            = nearest_hex_vertex(position, target, pow(PE, DD), vertex);
        address             = (address << 6) | vertex;

        return address;
    }


    float3 xyzuvw_position(in uint v)
    {     
        float3 position = hex_vertex_to_position((v >> 18) & 0x0000003F) * pow(PE, AA) 
                        + hex_vertex_to_position((v >> 12) & 0x0000003F) * pow(PE, BB)
                        + hex_vertex_to_position((v >> 6 ) & 0x0000003F) * pow(PE, CC)
                        + hex_vertex_to_position((v      ) & 0x0000003F) * pow(PE, DD);
        return position;
    }
#endif