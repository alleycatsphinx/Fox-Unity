#ifndef CUBE
    #define CUBE
    //takes in input n (0-7) and outputs a unit cube using the state of each bit as the coordinate
    float3 cube_vertex(in uint n)
    {        
        return float3
                (
                       uint3(         n,          n,          n)
                    >> uint3(0x00000000, 0x00000002, 0x00000001) 
                    &  uint3(0x00000001, 0x00000001, 0x00000001)
                );
    }                                                     


    //takes in input n (0-24) and returns the corrosponding cube vertex oriented along the axes 
    float3 cube_edge(in uint n)
    {     
        return  n < 0x00000008 ? cube_vertex(n).xyz 
              : n < 0x0000000F ? cube_vertex(n).yzx
              :                  cube_vertex(n).zxy;
    }


    float3 cube_tristrip(in uint x)
    {  
        x           = 0x00000001 << (x % 0x0000000E);        //░░░░░░░░░░░░░█ << x % ░░░░░░░░░░███░  
        return float3((0x0000287A & x) == 0x00000000,        //█░█░░░░████░█░ & x) > ░░░░░░░░░░░░░░
                      (0x000002AF & x) == 0x00000000,        //░░░░█░█░█░████ & x) > ░░░░░░░░░░░░░░
                      (0x000031E3 & x) == 0x00000000) - .5;  //██░░░████░░░██ & x) > ░░░░░░░░░░░░░░
    }
#endif