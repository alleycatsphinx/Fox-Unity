#ifndef MADOPS
    #define MADOPS    
    //emulation of fused addition multiplication for hardware that doesnt support it
    float madfrac(float a, float b) 
    { 
    	return a*b - floor(a*b); 
    }
    
    float2 madfrac(float2 a, float b) 
    { 
    	return a*b - floor(a*b); 
    }
#endif