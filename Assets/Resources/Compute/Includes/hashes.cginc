#ifndef HASHES
    #define HASHES

    
    #define UPHI                    2654435761          //b █——████———██—███—████——██—██———█  //h 0x9E3779B1   //u 2654435761  
    #define FLOAT_BITWISE_ENTROPY_X float(0x00001515)   //b ———————————————————█—█—█———█—█—█  //hex 0x00001515 //f 7.56280781196103773177536856101567736051957370030755562017289752815320247325558966622338630259037017822265625E-42
    #define FLOAT_BITWISE_ENTROPY_Y float(0x00000AEA)   //b ————————————————————█—█—███—█—█—  //hex 0x00000AEA //f 3.9152279093235388961609004557120256707970518656029850662892487851880762850242945205536670982837677001953125E-42
    #define FLOAT_BITWISE_ENTROPY_Z (FLOAT_BITWISE_ENTROPY_Y/FLOAT_BITWISE_ENTROPY_X)
    
    
    uint permute_address(in uint x)
    {   
        x ^= (x >> 9);
        x = (x << 7) | (x >> 11);   // rotate left 7 bits
        x ^= (x << 3) & 0x3FFFF;    // mask to 18 bits
        return x & 0x3FFFF;         // keep it within 18 bits
    }


    uint permute(uint i, uint n)
    {
    	return (i * uint(n / (sqrt(5.)*.5+.5))) % n;
    }
    
    
    uint knuth(uint x) 
    {    		
        return ((x * 2654435761) % 0xFFFFFFFF);
    } 
    
     
    float2 normalize_hash_input(float2 uv)
    {   
         return dot(uv, uv.yx) > 1. 
                ? normalize(uv + float2(FLOAT_BITWISE_ENTROPY_Y, FLOAT_BITWISE_ENTROPY_Z))
                : uv;
    }
    
    
    float hash(float x)
    {
        x = frac(x) * FLOAT_BITWISE_ENTROPY_X;   
        return frac(frac(x) * x);
    }
    
    
    float hash(float2 uv)
    {       
        return hash(hash(uv.y) + uv.x);
    }
    
    
    float3 hash(float3 uvw)
    {	
    	uvw = frac(uvw+sin(uvw.yzx)) * FLOAT_BITWISE_ENTROPY_X;	
    	return frac(float3(frac(uvw.x-frac(uvw.y-uvw.z)), frac(uvw.y-frac(uvw.z-uvw.x)), frac(uvw.z-frac(uvw.x-uvw.y))) * uvw);
    }
#endif