#ifndef ENCODING
	#define ENCODING

    #define ADDRESS_MAX 0x01249249u 		//b ———————█——█——█——█——█——█——█——█——█ //h 0x01249249 //d   19173961
    #define OCTAVE_MAX 8

    uint vertex_address_64(in uint thread)
    {
        return thread << 6u; 
    }       


    uint2 load_64(in uint thread,  RWStructuredBuffer<uint2> buffer)
    {
        return buffer[thread];
    }


    void store_64(in uint thread, in uint2 vertices, RWStructuredBuffer<uint2> buffer)
    {
        uint prior = 0u;
        InterlockedExchange(buffer[thread].x, vertices.x, prior);
        InterlockedExchange(buffer[thread].y, vertices.y, prior);
    }


    void xor_64(in uint thread, in uint2 vertices, RWStructuredBuffer<uint2> buffer)
    {
        uint prior = 0u;
        InterlockedOr(buffer[thread].x, vertices.x, prior);
        InterlockedOr(buffer[thread].y, vertices.y, prior);
    }


    void interlocked_store_64(in uint thread, in uint2 vertices, RWStructuredBuffer<uint2> buffer)
    {
        uint prior = 0u;
        InterlockedExchange(buffer[thread].x, vertices.x, prior);
        InterlockedExchange(buffer[thread].y, vertices.y, prior);
    }


    void interlocked_xor_64(in uint thread, in uint2 vertices, RWStructuredBuffer<uint2> buffer)
    {
        uint prior = 0u;
        InterlockedOr(buffer[thread].x, vertices.x, prior);
        InterlockedOr(buffer[thread].y, vertices.y, prior);
    }


    uint dilate_3(uint x)
    {
        x = (x | (x << 12u)) & 0x000003FFu; //b ——————————————————————██████████  //u      1023  //h 0x000003FF 
        x = (x | (x << 10u)) & 0x000F801Fu; //b ————————————█████——————————█████  //u   1015839  //h 0x000F801F
        x = (x | (x <<  4u)) & 0x00E181C3u; //b ————————███————██——————███————██  //u  14778819  //h 0x00E181C3
        x = (x | (x <<  2u)) & 0x03248649u; //b ——————██——█——█——█————██——█——█——█  //u  52725321  //h 0x03248649
        x = (x | (x <<  2u)) & 0x09249249u; //b ————█——█——█——█——█——█——█——█——█——█  //u 153391689  //h 0x09249249
        return x;
    }


    uint contract_3(uint x)
    {   
        x =                x & 0x09249249u; //b ————█——█——█——█——█——█——█——█——█——█  //u  153391689  //h 0x09249249
        x = (x | (x >>  2u)) & 0x03248649u; //b ——————██——█——█——█————██——█——█——█  //u   52725321  //h 0x03248649
        x = (x | (x >>  2u)) & 0x00E181C3u; //b ————————███————██——————███————██  //u   14778819  //h 0x00E181C3
        x = (x | (x >>  4u)) & 0x000F801Fu; //b ————————————█████——————————█████  //u    1015839  //h 0x000F801F
        x = (x | (x >> 10u)) & 0x000003FFu; //b ——————————————————————██████████  //u       1023  //h 0x000003FF
        return x;
    }
    

    //interlace x y z components into a single value
    uint xyz_x(uint3 p)
    {   
        return dilate_3(p.x) | dilate_3(p.y) << 1u  | dilate_3(p.z) << 2u;
    }


    //split a single value into x y z components
    uint3 x_xyz(uint x)
    {   
        return uint3(contract_3(x      ), contract_3(x >> 1u), contract_3(x >> 2u));
    }


    uint address_prefix(in uint address)
    {
        uint prefix = 0x01249248u;
        // [unroll] //register pressure - comin down on me, comin down on you, no man ask for - register pressure!
        for(uint i = 0; i < 8; i++)
        {
            if(address >= prefix) return prefix;
            prefix &= prefix << 3u;
        }
        return prefix;
    }
    

    uint address_octave(in uint address)  //register pressure warning
    {       
        return address < 0x01000000u ? 8u   //b ———————█———————————————————————— //h 0x01000000 //d 16777216
             : address < 0x01200000u ? 7u   //b ———————█——█————————————————————— //h 0x01200000 //d 18874368
             : address < 0x01240000u ? 6u   //b ———————█——█——█—————————————————— //h 0x01240000 //d 19136512
             : address < 0x01248000u ? 5u   //b ———————█——█——█——█——————————————— //h 0x01248000 //d 19169280
             : address < 0x01249000u ? 4u   //b ———————█——█——█——█——█———————————— //h 0x01249000 //d 19173376
             : address < 0x01249200u ? 3u   //b ———————█——█——█——█——█——█————————— //h 0x01249200 //d 19173888
             : address < 0x01249240u ? 2u   //b ———————█——█——█——█——█——█——█—————— //h 0x01249240 //d 19173952
             : address < 0x01249248u ? 1u   //b ———————█——█——█——█——█——█——█——█——— //h 0x01249248 //d 19173960
             :                         0u;     
    }


    uint octave_prefix(in uint octave)
    {
        return (0x01249249u << (octave * 3u)) //b ———————█——█——█——█——█——█——█——█——— //h 0x01249248 //d 19173960
              & 0x01FFFFFFu;                  //b ———————█████████████████████████ //h 0x01FFFFFF //d 33554431
    }


    uint octave_frequency(uint octave)  
    {
        return 0x00000001u << octave * 3u;
    }


    uint parent_address(in uint address)
    {
        return address >> 3u;
    }


	float spatial_frequency(uint octave)
    {    
        return rcp(pow(2., octave));
    }


	uint binary_gray(uint x)
    {
        return x ^ (x >> 0x00000001u);  
    }
    
    
    uint gray_binary(uint x)
    {
        x ^= (x >> 0x00000010u);
        x ^= (x >> 0x00000008u);
        x ^= (x >> 0x00000004u);
        x ^= (x >> 0x00000002u);
        x ^= (x >> 0x00000001u);
        return(x);
    } 


	uint3 skilling(in uint3 position, in uint octave)
    {                
        int mask = 0;
        for(uint i = 2u; i < (1u << octave); i <<= 1u)
        {
            mask = i - 1u;
            position.xz ^= (position.x & i) != 0u ? int2(   0u, mask) : (position.x ^ position.z) & mask;
            position.yz ^= (position.y & i) != 0u ? int2(   0u, mask) : (position.y ^ position.z) & mask;
            position.z  ^= (position.z & i) != 0u ?            mask  :                                0u;
        }

        return position;
    }
   
   

    //hilbert curve commented out
    uint position_address(in float3 position, in uint octave)
    {                   
        return xyz_x(position);
    }


    uint position_address_normed(in float3 position, in uint octave)
    {                   
        return position_address(floor((position) * (1u << octave) + .5), octave);
    }


    // uint position_address_normed_centered(in float3 position, in uint octave)
    // {                   
    //     return position_address_normed(position, octave)
    // }

    float3 address_position(in uint address, in uint octave)
    {
        return x_xyz(address); 
    }

    // float3 address_position(in uint address, in uint octave)
    // {
    //     return x_xyz(binary_gray(address)); 
    // }


    // uint position_address(in float3 position, in uint octave)
    // {                   
    //     return gray_binary(xyz_x(position));
    // }


    // uint position_address_normed(in float3 position, in uint octave)
    // {                   
    //     return gray_binary(xyz_x(position * (1 << octave)));
    // }


    // uint position_address_normed_centered(in float3 position, in uint octave)
    // {                   
    //     return gray_binary(xyz_x(position * (1 << octave) + .5));
    // }

    
    // float3 address_position(in uint address, in uint octave)
    // {
    //     return skilling(x_xyz(binary_gray(address)), octave); 
    // }


    float3  address_position_normed(in uint address, in uint octave)
    {            
        return address_position(address, octave) * spatial_frequency(octave) - .5;
    }


    float3 address_position_normed_centered(in uint address, in uint octave)
    {            
        return address_position_normed(address, octave) + spatial_frequency(octave + 1u);
    }

    // uint position_address(in float3 position, in uint octave)
    // {                   
    //     return gray_binary(xyz_x(skilling(uint3(position), octave)));
    // }

    // uint position_address_normed(in float3 position, in uint octave)
    // {            		
	//     return gray_binary(xyz_x(skilling(uint3(position * (1 << octave)), octave)));
    // }



    // float3 address_position_normed(in uint address, in uint octave, in float4x4 transform)
    // {            
    //     position = mul(position, transform); //may need scaling here first (or twice) - may need transpose
    //     return address_position(address, octave) * spatial_frequency(octave) - .5;
    // }


    uint tensor_embedding(float3 position)
    {
        float3 r       = GPU.encoding.rotation;
        float3 a       = float3(cos(r.x)*cos(r.y),sin(r.y),sin(r.x)*cos(r.y));
        
        float c        = cos(r.z);
        float s        = sin(r.z);
        float3 as      = a*s;
        float3 ac      = a*a*(1.- c);
        float3 ad      = a.yzx*a.zxy*(1.-c);
    
        float3x3 rotation = float3x3(
                c    + ac.x, ad.z + as.z, ad.y - as.y,
                ad.z - as.z, c    + ac.y, ad.x + as.x,
                ad.y + as.y, ad.x - as.x, c    + ac.z);

        // return position_address_normed(position * CPU.encoding.scale.x, 7) % 262144;
        return clamp(uint(position_address_normed(mul(position, rotation) * CPU.encoding.scale.x, uint(CPU.encoding.scale.z)) * uint(CPU.encoding.scale.y)), 0, Prefix_Sum_COUNT);
    }
#endif