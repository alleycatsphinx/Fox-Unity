using UnityEngine;
using Unity.Mathematics;

namespace secantastronomy
{
    using static State;

    using float2    = Vector2;
    using float3    = Vector3;
    using float4    = Vector4;
    using int2      = Vector2Int;
    using int3      = Vector3Int;    
    using float4x4  = Matrix4x4;

    //This configuration is used to communicate and control programs within the GPU.
    //"CodeGeneration.cs" automatically generates a matching configuration.cginc which is communicated to the GPU via "Marshal.cs"

    [System.Serializable]
    public class Configuration : ScriptableObject
    {
        //PARSE_CONFIGURATION_BEGIN        
        [System.Serializable]
        public struct StructStatus
        { 
            public uint                             frame;
            public float                            fps;
            public float                            time;
            public float                            delta_time;
        };


        [System.Serializable]
        public struct StructMouse
        {
            public float2                           position;
            public float2                           delta;
            public float3                           wheels;
            public uint                             buttons;
        };


        [System.Serializable]       
        public struct StructProjection
        { 
            public float3                           position;
            public float3                           direction;
            public float                            fov;
            public float                            near;
            public float                            far;
            public float4x4                         to_view;
            public float4x4                         to_world;   
            public float4x4                         view; 
            public float4x4                         inverse; 
        };


        [System.Serializable]
        public struct StructFractal
        {            
            public float4                           rotation;
            public float4                           translation;
            public float                            threshold;  
        };


        [System.Serializable]
        public struct StructPlanet
        {                        
            public float                            frequency;                 
            public float                            amplitude;                 
            public float                            lacunarity;                
            public float                            drift;                     
            public float                            iterations;                
            public float                            magnitude;               
            public float                            threshold;
        };


        [System.Serializable]
        public struct StructCollision
        {   
            public float4                           origin;         
            public float4                           position;          
            public float4                           direction;         
        };


        [System.Serializable]
        public struct StructSelection
        {     
            public float3                           ray;
            public float3                           position;               
            public float                            radius;                
            public uint                             address;
        };
        
    
        [System.Serializable]
        public struct StructSphere
        {
            public float                            radius;
        };


        [System.Serializable]
        public struct StructField
        {   
            public uint                             function; 
            public StructSphere                     sphere;          
            public StructFractal                    fractal;          
            public StructPlanet                     planet; 
            public StructCollision                  collision;
            public float4x4                         transform;        
        };

        
        [System.Serializable]
        public struct StructEncoding
        {   
            public uint                             octave;
            public float4x4                         transform;
            public float3                           translation;          
            public float3                           rotation;          
            public float3                           scale;          
        };


        [System.Serializable]
        public struct StructLight
        {            
            public float3                           position;
            public float4                           color;     
            public float                            intensity;               
        };

        
        [System.Serializable]
        public struct StructAtmosphere
        {   
            public float                            ambient;   
            public float                            haze;
            public float                            horizon;
            public float                            density;
        };


        [System.Serializable]
        public struct StructMaterial
        {      
            public float4                           tint;
            public float                            scattering;
            public float                            index; 
            public float                            saturation;          
            public float                            normal;
            public float                            map; 
            public float                            edges;
        };        
 

        [System.Serializable]
        public struct StructShadow
        {            
            public float4                           debug;            
        };


        [System.Serializable]
        public struct StructOcclusion
        {            
            public float4                           debug;
        };



        [System.Serializable]
        public struct StructRenderingDiagnostic
        {            
            public bool                             step_count;
            public float4                           debug;
        };

        
        [System.Serializable]
        public struct StructRay
        {            
            public float                            threshold;
            public float4                           focus;
            public float                            epsilon;
        };


        [System.Serializable]
        public struct StructComposition
        {            
            public float                            prior;
            public float                            geometry;
            public float                            diagnostic;
        };

        


        [System.Serializable]
        public struct StructRendering
        {            
            public StructProjection                 projection;
            public StructRay                        ray;
            public StructMaterial                   material;            
            public StructLight                      light;
            public StructShadow                     shadow;
            public StructOcclusion                  occlusion;
            public StructAtmosphere                 atmosphere;
            public StructRenderingDiagnostic        diagnostic;
            public StructComposition                composition;
            public float                            brightness;
            public float                            gamma;
            public uint2                            resolution;
            public float4                           debug;
        };


        [System.Serializable]
        public struct StructSimFlow
        {
            public float                            cohesion;
            public float                            alignment;
            public float                            avoidance;
            public float                            temperature;
            public float                            convection;
            public float                            dispersion;
            public float                            velocity;
            public float                            decelleration;
            public float                            threshold;
        };


        [System.Serializable]
        public struct StructSimColor
        {
            public float                            type;
            public float                            density;            
            public float                            direction;
            public float                            temperature;
            public float                            temperature_delta;
            public float                            density_delta;
            public float                            brightness;
            public float                            gamma;
            public float                            interpolant;
        };


        [System.Serializable]
        public struct StructSimField
        {
            public float                            threshold;
            public float                            restitution;
            public float                            force;
            public float                            gravity;
        };


        [System.Serializable]
        public struct StructSimInput
        {
            public float                            length;
            public float                            radius;
            public float                            amplitude;
            public float                            temperature;
            public float                            velocity;
        };


        [System.Serializable]
        public struct StructSimBounds
        {
            public uint                             function;
            public float                            radius;
            public float                            restitution;
            public float                            force;
        };


        [System.Serializable]
        public struct StructSimBitmap
        {
            public float                            restitution;
            public float                            radius;
        };


        [System.Serializable]
        struct StructTensor
        {
            public float4                           position; 
            public float4                           velocity;
            public float4                           state;
            public float4                           color;
            public float4                           prior;
            public float4                           prior1;
            public float4                           prior2;
            public float                            temperature;
            public uint                             temp;
            public uint                             count;
            public uint                             address;
        };


        [System.Serializable]
        public struct StructEdge
        {
            public uint                             address_OPEN_BRACKET_EDGE_COUNT_CLOSE_BRACKET_;
        };


        [System.Serializable]
        public struct StructSim
        {
            public StructSimFlow                    flow;
            public StructSimInput                   input;
            public StructSimField                   field;
            public StructSimBounds                  bounds;
            public StructSimBitmap                  bitmap;
            public StructSimColor                   color;
        };

        [System.Serializable]
        public struct StructGuassian
        {
            public float4x4                         transform;
        };


        [System.Serializable]
        public struct StructDebug
        {
            public float                            a;
            public float                            b;
            public float                            c;
            public float                            d;
            public float                            e;
            public float                            f;
            public float                            g;
            public float                            h;
            public float                            i;
            public float                            j;
            public float                            k;
            public float                            l;
            public float                            m;
            public float                            n;
            public float                            o;
            public float                            p;
        };


        [System.Serializable]
        public struct StructConfiguration
        {
            public StructStatus                     status;
            public StructMouse                      mouse;
            public StructSelection                  selection;
            public StructEncoding                   encoding;
            public StructRendering                  rendering;
            public StructField                      field;
            public StructSim                        sim;
            public StructGuassian                   guassian;
            public StructDebug                      debug;
        };
        //PARSE_CONFIGURATION_END
    }
}

