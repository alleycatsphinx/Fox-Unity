#ifndef INTERSECT
    #define INTERSECT
    // The MIT License
    // Copyright © 2017 Inigo Quilez
    // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    // float cross2d( in float2 a, in float2 b ) { return a.x*b.y - a.y*b.x; }

    

    // // 0--b--3
    // // |\
    // // a c
    // // |  \
    // // 1    2
    // //

    
    // float3 intersect_quad( in float3 ro, in float3 rd, in float3 v0, in float3 v1, in float3 v2, in float3 v3 )
    // {
    //     // lets make v0 the origin
    //     float3 a = v1 - v0;
    //     float3 b = v3 - v0;
    //     float3 c = v2 - v0;
    //     float3 p = ro - v0;

    //     // intersect plane
    //     float3 nor  = cross(a,b);
    //     float t     = -dot(p,nor)/dot(rd,nor);

    //     //if( t < 0.0 ) return float3(-1., -1., -1.);
        
    //     // intersection point
    //     float3 pos = p + t*rd;

    //     // see here: https://www.shadertoy.com/view/lsBSDm
        
    //     // select projection plane
    //     float3 mor = abs(nor);
    //     int id = (mor.x>mor.y && mor.x>mor.z ) ? 0 : 
    //              (mor.y>mor.z)                 ? 1 : 
    //                                              2 ;

    //     int lut[4];
    //     lut[0] = 1;
    //     lut[1] = 2;
    //     lut[2] = 0;
    //     lut[3] = 1;

    //     int idu = lut[id  ];
    //     int idv = lut[id+1];
        
    //     // project to 2D
    //     float2 kp = float2( pos[idu], pos[idv] );
    //     float2 ka = float2( a[idu], a[idv] );
    //     float2 kb = float2( b[idu], b[idv] );
    //     float2 kc = float2( c[idu], c[idv] );
        
    //     // find barycentric coords of the quadrilateral
    //     float2 kg = kc-kb-ka;

    //     float k0 = cross2d( kp, kb );
    //     float k2 = cross2d( kc-kb, ka );        // float k2 = cross2d( kg, ka );
    //     float k1 = cross2d( kp, kg ) - nor[id]; // float k1 = cross2d( kb, ka ) + cross2d( kp, kg );
        
    //     // if edges are parallel, this is a linear equation
    //     float u, v;
    //     if( abs(k2)<0.00001 )
    //     {
    //         v = -k0/k1;
    //         u = cross2d( kp, ka )/k1;
    //     }
    //     else
    //     {
    //         // otherwise, it's a quadratic
    //         float w = k1*k1 - 4.0*k0*k2;
    //         if( w<0.0 ) return float3(-1., -1., -1.);
    //         w = sqrt( w );

    //         float ik2 = 1.0/(2.0*k2);

    //                              v = (-k1 - w)*ik2; 
    //         if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
            
    //         u = (kp.x - ka.x*v)/(kb.x + kg.x*v);
    //     }
        
    //     if( u<0.0 || u>1.0 || v<0.0 || v>1.0) return float3(-1., -1., -1.);
        
    //     return float3( t, u, v );
    // }


    // float2 intersect(float2 p11,float2 p12,float2 p21,float2 p22)
    // {   
    //     float2 n0  = (p12-p11).yx * float2(-1, 1);
    //     float2 n1  = (p22-p21).yx * float2(-1, 1);
        
    //     float d0   = dot(n0*p11, float2(1.,1.));
    //     float d1   = dot(n1*p21, float2(1.,1.));

    //     float2x2 d = float2x2(n0.x, n0.y, n1.x, n1.y); 
    //     float2x2 x = float2x2(d0, n0.y, d1, n1.y); 
    //     float2x2 y = float2x2(n0.x, d0, n1.x, d1);  
        
    //     return float2(determinant(x)*rcp(determinant(d)),determinant(y)*rcp(determinant(d)));       
    // }


    // float2 intersect2(float2 a, float2 b, float2 c, float2 d) 
    // {        
    //     float2 r    = b - a;
    //     float2 s    = d - c;
    //     float i     = 1./(r.x * s.y - r.y * s.x);
    //     float2 q    = float2((c.x - a.x) * r.y - (c.y - a.y) * r.x, (c.x - a.x) * s.y - (c.y - a.y) * s.x) * i;
    //     return a + normalize(b-a) * (clamp(q, 0., 1.) == q ? distance(a, a + r * q.y) : length(abs(a-b)+.00001));
    // }

    // // void bound_segment(inout float4 v, const in float4 b, out bool visible)
    // // {
    // //     //v = vertex, b = bounds
    // //     visible                             = true;
        
    // //     //test for zero length
    // //     if(v.x == v.z && v.y == v.w)
    // //     { 
    // //         visible                         = false;
    // //         return;
    // //     }
                
    // //     //bounds position : -1 less than, 0 within, 1 greater than
    // //     float4 p                            = float4
    // //     (
    // //         v.x >= b.x ? v.x <= b.z ? 0. : -1. : 1.,
    // //         v.y >= b.y ? v.y <= b.w ? 0. : -1. : 1.,
    // //         v.z >= b.x ? v.z <= b.z ? 0. : -1. : 1.,
    // //         v.w >= b.y ? v.w <= b.w ? 0. : -1. : 1.
    // //     );
        
    // //     if(((p.x == p.z) && p.x != 0.) || ((p.y == p.w) && p.y != 0.))
    // //     {
    // //         visible                         = false;
    // //         return;
    // //     }
    // //     else
    // //     {   
    // //         bool xy_in                      = p.x == 0. && p.y == 0.;
    // //         bool zw_in                      = p.z == 0. && p.w == 0.;   
                    
    // //         v                               = xy_in ? v : v.zwxy;
    // //         bool swap                       = xy_in;

    // //         if(!xy_in || !zw_in)        
    // //         {       
    // //             float2 intercept            = float2(0.,0.);
    // //             float2 minima               = float2(0x0FFFFFFF,0x0FFFFFFF);
    // //             float2 maxima               = float2(0xFFFFFFFF,0xFFFFFFFF);    
    // //             float4 intersection         = float4(0., 0., 0., 0.);

    // //             intersection.xy             = v.x < v.z ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
    // //             intersection.zw             = v.y < v.w ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
    // //             minima                      = min(intersection.xy, intersection.zw);
    // //             maxima                      = max(intersection.xy, intersection.zw);
                        
    // //             intercept.x                 = abs(v.x-minima.x) < abs(v.x-maxima.x) ? minima.x : maxima.x;
    // //             intercept.y                 = abs(v.y-minima.y) < abs(v.y-maxima.y) ? minima.y : maxima.y;                  
                
    // //             if(intercept.x != v.x && intercept.y != v.y)    
    // //             {
    // //                 if(!xy_in && !zw_in)        
    // //                 {           
    // //                     if(intercept.x != v.x  && intercept.y != v.y && intercept.x != v.z && intercept.y != v.w)               
    // //                     {   
    // //                         intersection.xy = v.z < intercept.x ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
    // //                         intersection.zw = v.w < intercept.y ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
    // //                         minima          = min(intersection.xy, intersection.zw);
    // //                         maxima          = max(intersection.xy, intersection.zw);
                        
    // //                         v.x             = abs(v.x-minima.x) <= abs(v.x-maxima.x) ? minima.x : maxima.x;
    // //                         v.y             = abs(v.y-minima.y) <= abs(v.y-maxima.y) ? minima.y : maxima.y;  
                            
    // //                         if((intercept.x == v.x && intercept.y == v.y) || (intercept.x == v.z && intercept.y == v.w))               
    // //                         {   
    // //                             visible     = false;
    // //                             return;
    // //                         }                           
    // //                     }   
    // //                     else
    // //                     {
    // //                         visible         = false;
    // //                         return;
    // //                     }
    // //                 }
                    
    // //                 v.zw                    = intercept;                         
    // //             }                           
    // //         }            
    // //         v                               = swap ? v.zwxy : v;
    // //     }       

    // //     if(p.x != 0. || p.y != 0. || p.z != 0. || p.w != 0.)
    // //     {
    // //         visible                         = false;
    // //         return;
    // //     }   
    // // }

    // void bound_line(inout int2 origin, inout int2 extent, in int2 minima, in int2 maxima)
    // {     
    //     bool4 o_in          = bool4(origin.x > minima.x, origin.x < maxima.x, origin.y > minima.y, origin.y < maxima.y);
    //     bool4 e_in          = bool4(extent.x > minima.x, extent.x < maxima.x, extent.y > minima.y, extent.y < maxima.y);

    //     if(o_in.x && o_in.y && o_in.z && o_in.w && e_in.x && e_in.y && e_in.z && e_in.w)
    //     {          
    //         return;
    //     }        

    //     int4 edges          = int4(minima, maxima); 
                 
    //     if(origin.x < minima.x)
    //     {
    //         origin = intersect(origin, extent, edges.xy, edges.xw); //left    
    //         extent = intersect(extent, origin, edges.xy, edges.xw); //left    
    //     }                
    //     else if(origin.x > maxima.x)
    //     {
    //         origin = intersect(origin, extent, edges.zy, edges.zw); //right    
    //         extent = intersect(extent, origin, edges.zy, edges.zw); //right    
    //     }

    //     if(origin.y < minima.y)
    //     {
    //         origin = intersect(origin, extent, edges.xy, edges.zy); //bottom    
    //         extent = intersect(extent, origin, edges.xy, edges.zy); //bottom    
    //     }
    //     else if(origin.y > maxima.y)
    //     {
    //         origin = intersect(origin, extent, edges.xw, edges.zw); //top  
    //         extent = intersect(extent, origin, edges.xw, edges.zw); //top                                        
    //     }

    //     o_in          = bool4(origin.x > minima.x, origin.x < maxima.x, origin.y > minima.y, origin.y < maxima.y);
    //     e_in          = bool4(extent.x > minima.x, extent.x < maxima.x, extent.y > minima.y, extent.y < maxima.y);

    //     if((!o_in.x && !e_in.x) || (!o_in.y && !e_in.y) || (!o_in.z && !e_in.z) || (!o_in.w && !e_in.w))
    //     {     
    //         origin = int2(-1,-1);     
    //         extent = int2(-1,-1);
    //     }      

    //     // if(origin.x < minima.x)
    //     // {
    //     //     origin = intersect(origin, extent, edges.xy, edges.xw); //left    
    //     // }                
    //     // else if(origin.x > maxima.x)
    //     // {
    //     //     origin = intersect(origin, extent, edges.zy, edges.zw); //right    
    //     // }

    //     // if(origin.y < minima.y)
    //     // {
    //     //     origin = intersect(origin, extent, edges.xy, edges.zy); //bottom    
    //     // }
    //     // else if(origin.y > maxima.y)
    //     // {
    //     //     origin = intersect(origin, extent, edges.xw, edges.zw); //top                     
    //     // }

    //     // if(extent.x < minima.x)
    //     // {
    //     //     extent = intersect(extent, origin, edges.xy, edges.xw); //left    
    //     // }                
    //     // else if(extent.x > maxima.x)
    //     // {
    //     //     extent = intersect(extent, origin, edges.zy, edges.zw); //right    
    //     // }

    //     // if(extent.y < minima.y)
    //     // {
    //     //     extent = intersect(extent, origin, edges.xy, edges.zy); //bottom    
    //     // }
    //     // else if(extent.y > maxima.y)
    //     // {
    //     //     extent = intersect(extent, origin, edges.xw, edges.zw); //top                     
    //     // }
    // }



    // void bound(inout float4 v, in float2 resolution, out bool visible)
    // {
    //     visible                             = true;

    //     if(dot(v.xy-v.zw, float2(1., 1.)) == 0.)
    //     {
    //         visible                         = true;
    //         return;
    //     }
     
    //     float3 b                            = float3(resolution, 0.);
    //     float4 p;           
    //     p.x                                 = v.x < b.x ? v.x < b.z ? -1. : 0. : 1.;
    //     p.y                                 = v.y < b.y ? v.y < b.z ? -1. : 0. : 1.;
    //     p.z                                 = v.z < b.x ? v.z < b.z ? -1. : 0. : 1.;
    //     p.w                                 = v.w < b.y ? v.w < b.z ? -1. : 0. : 1.;
                    
    //     if((p.x == p.z && p.x != 0.) || (p.y == p.w && p.y != 0.))
    //     {
    //         visible                         = false;
    //         return;
    //     }
    //     else
    //     {   
    //         bool xy_in                      = p.x == 0. && p.y == 0.;
    //         bool zw_in                      = p.z == 0. && p.w == 0.;   
                    
    //         v                               = xy_in ? v : v.zwxy;
    //         bool swap                       = xy_in;

    //         if(!xy_in || !zw_in)        
    //         {       
    //             float2 intercept            = float2(0.,0.);
    //             float2 minima               = float2(0x0FFFFFFF,0x0FFFFFFF);
    //             float2 maxima               = float2(0xFFFFFFFF,0xFFFFFFFF);    
    //             float4 intersection         = float4(0., 0., 0., 0.);

    //             intersection.xy             = v.x < v.z ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
    //             intersection.zw             = v.y < v.w ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
    //             minima                      = min(intersection.xy, intersection.zw);
    //             maxima                      = max(intersection.xy, intersection.zw);
                        
    //             intercept.x                 = abs(v.x-minima.x) < abs(v.x-maxima.x) ? minima.x : maxima.x;
    //             intercept.y                 = abs(v.y-minima.y) < abs(v.y-maxima.y) ? minima.y : maxima.y;                  
                
    //             if(intercept.x != v.x && intercept.y != v.y)    
    //             {
    //                 if(!xy_in && !zw_in)        
    //                 {           
    //                     if(intercept.x != v.x  && intercept.y != v.y && intercept.x != v.z && intercept.y != v.w)               
    //                     {   
    //                         intersection.xy = v.z < intercept.x ? intersect(v.xy, v.zw, b.xz, b.xy) : intersect(v.xy, v.zw, b.zz, b.zy);
    //                         intersection.zw = v.w < intercept.y ? intersect(v.xy, v.zw, b.zy, b.xy) : intersect(v.xy, v.zw, b.zz, b.xz);
                                
    //                         minima          = min(intersection.xy, intersection.zw);
    //                         maxima          = max(intersection.xy, intersection.zw);
                        
    //                         v.x             = abs(v.x-minima.x) <= abs(v.x-maxima.x) ? minima.x : maxima.x;
    //                         v.y             = abs(v.y-minima.y) <= abs(v.y-maxima.y) ? minima.y : maxima.y;  
                            
    //                         if((intercept.x == v.x && intercept.y == v.y) || (intercept.x == v.z && intercept.y == v.w))               
    //                         {   
    //                             visible     = false;
    //                         }                           
    //                     }   
    //                     else
    //                     {
    //                         visible         = false;
    //                         return;
    //                     }
    //                 }
                    
    //                 v.zw                    = intercept;                         
    //             }                           
    //         }            
    //         v                               = swap ? v.zwxy : v;
    //     }       

    //     b                       += float3(1., 1., -1.);
    //     p.x                     = v.x < b.x ? v.x < b.z ? -1. : 0. : 1.;
    //     p.y                     = v.y < b.y ? v.y < b.z ? -1. : 0. : 1.;
    //     p.z                     = v.z < b.x ? v.z < b.z ? -1. : 0. : 1.;
    //     p.w                     = v.w < b.y ? v.w < b.z ? -1. : 0. : 1.;
                    
    //     if(p.x != 0. || p.y != 0. || p.z != 0. || p.w != 0.)
    //     {
    //         visible                         = false;
    //         return;
    //     }   
    // }

    #endif

         



























