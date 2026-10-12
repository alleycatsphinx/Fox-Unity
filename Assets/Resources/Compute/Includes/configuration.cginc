#ifndef CONFIGURATION
	#define CONFIGURATION

		//Definitions		
        #define TENSOR_COUNT                262144
        #define GUASSIAN_COUNT              2097152        
        #define EDGE_COUNT                  16        
        #define THREAD_GROUP_SIZE           64
        #define THREAD_GROUP_SIZE_X         8
        #define THREAD_GROUP_SIZE_Y         8
        #define DISPATCH_LEAF_SIZE          262144/THREAD_GROUP_SIZE //262144 * 64bit u#define2  16777216 bits  8^8 leaf nodes
        #define DISPATCH_TREE_SIZE          299648/THREAD_GROUP_SIZE //262144 + 4096 + 512 + 64 + 8 + 1 u#define2
        #define DISPATCH_TENSOR_SIZE        TENSOR_COUNT/THREAD_GROUP_SIZE
        #define DISPATCH_GUASSIAN_SIZE      GUASSIAN_COUNT/THREAD_GROUP_SIZE        
                
        
        struct StructStatus
        { 
            uint                             frame;
            float                            fps;
            float                            time;
            float                            delta_time;
        };


        
        struct StructMouse
        {
            float2                           position;
            float2                           delta;
            float3                           wheels;
            uint                             buttons;
        };


               
        struct StructProjection
        { 
            float3                           position;
            float3                           direction;
            float                            fov;
            float                            near;
            float                            far;
            float4x4                         to_view;
            float4x4                         to_world;   
            float4x4                         view; 
            float4x4                         inverse; 
        };


        
        struct StructFractal
        {            
            float4                           rotation;
            float4                           translation;
            float                            threshold;  
        };


        
        struct StructPlanet
        {                        
            float                            frequency;                 
            float                            amplitude;                 
            float                            lacunarity;                
            float                            drift;                     
            float                            iterations;                
            float                            magnitude;               
            float                            threshold;
        };


        
        struct StructCollision
        {   
            float4                           origin;         
            float4                           position;          
            float4                           direction;         
        };


        
        struct StructSelection
        {     
            float3                           ray;
            float3                           position;               
            float                            radius;                
            uint                             address;
        };
        
    
        
        struct StructSphere
        {
            float                            radius;
        };


        
        struct StructField
        {   
            uint                             function; 
            StructSphere                     sphere;          
            StructFractal                    fractal;          
            StructPlanet                     planet; 
            StructCollision                  collision;
            float4x4                         transform;        
        };

        
        
        struct StructEncoding
        {   
            uint                             octave;
            float4x4                         transform;
            float3                           translation;          
            float3                           rotation;          
            float3                           scale;          
        };


        
        struct StructLight
        {            
            float3                           position;
            float4                           color;     
            float                            intensity;               
        };

        
        
        struct StructAtmosphere
        {   
            float                            ambient;   
            float                            haze;
            float                            horizon;
            float                            density;
        };


        
        struct StructMaterial
        {      
            float4                           tint;
            float                            scattering;
            float                            index; 
            float                            saturation;          
            float                            normal;
            float                            map; 
            float                            edges;
        };        
 

        
        struct StructShadow
        {            
            float4                           debug;            
        };


        
        struct StructOcclusion
        {            
            float4                           debug;
        };



        
        struct StructRenderingDiagnostic
        {            
            uint                              step_count;
            float4                           debug;
        };

        
        
        struct StructRay
        {            
            float                            threshold;
            float4                           focus;
            float                            epsilon;
        };


        
        struct StructComposition
        {            
            float                            prior;
            float                            geometry;
            float                            diagnostic;
        };

        


        
        struct StructRendering
        {            
            StructProjection                 projection;
            StructRay                        ray;
            StructMaterial                   material;            
            StructLight                      light;
            StructShadow                     shadow;
            StructOcclusion                  occlusion;
            StructAtmosphere                 atmosphere;
            StructRenderingDiagnostic        diagnostic;
            StructComposition                composition;
            float                            brightness;
            float                            gamma;
            uint2                            resolution;
            float4                           debug;
        };


        
        struct StructSimFlow
        {
            float                            cohesion;
            float                            alignment;
            float                            avoidance;
            float                            temperature;
            float                            convection;
            float                            dispersion;
            float                            velocity;
            float                            decelleration;
            float                            threshold;
        };


        
        struct StructSimColor
        {
            float                            type;
            float                            density;            
            float                            direction;
            float                            temperature;
            float                            temperature_delta;
            float                            density_delta;
            float                            brightness;
            float                            gamma;
            float                            interpolant;
        };


        
        struct StructSimField
        {
            float                            threshold;
            float                            restitution;
            float                            force;
            float                            gravity;
        };


        
        struct StructSimInput
        {
            float                            length;
            float                            radius;
            float                            amplitude;
            float                            temperature;
            float                            velocity;
        };


        
        struct StructSimBounds
        {
            uint                             function;
            float                            radius;
            float                            restitution;
            float                            force;
        };


        
        struct StructSimBitmap
        {
            float                            restitution;
            float                            radius;
        };


        
        struct StructTensor
        {
            float4                           position; 
            float4                           velocity;
            float4                           state;
            float4                           color;
            float4                           prior;
            float4                           prior1;
            float4                           prior2;
            float                            temperature;
            uint                             temp;
            uint                             count;
            uint                             address;
        };


        
        struct StructEdge
        {
            uint                             address[EDGE_COUNT];
        };


        
        struct StructSim
        {
            StructSimFlow                    flow;
            StructSimInput                   input;
            StructSimField                   field;
            StructSimBounds                  bounds;
            StructSimBitmap                  bitmap;
            StructSimColor                   color;
        };

        
        struct StructGuassian
        {
            float4x4                         transform;
        };


        
        struct StructDebug
        {
            float                            a;
            float                            b;
            float                            c;
            float                            d;
            float                            e;
            float                            f;
            float                            g;
            float                            h;
            float                            i;
            float                            j;
            float                            k;
            float                            l;
            float                            m;
            float                            n;
            float                            o;
            float                            p;
        };


        
        struct StructConfiguration
        {
            StructStatus                     status;
            StructMouse                      mouse;
            StructSelection                  selection;
            StructEncoding                   encoding;
            StructRendering                  rendering;
            StructField                      field;
            StructSim                        sim;
            StructGuassian                   guassian;
            StructDebug                      debug;
        };
        

		//Buffers
		RWStructuredBuffer<StructConfiguration>	_CPU;
		#define CPU	_CPU[0]
		#define CPU_COUNT 1
		#define CPU_STRIDE 2048

		RWStructuredBuffer<StructConfiguration>	_GPU;
		#define GPU	_GPU[0]
		#define GPU_COUNT 1
		#define GPU_STRIDE 2048

		RWStructuredBuffer<StructTensor>	_Tensor;
		#define Tensor_COUNT 262144
		#define Tensor_STRIDE 128

		RWStructuredBuffer<uint>	_Tensor_Map;
		#define Tensor_Map_COUNT 262144
		#define Tensor_Map_STRIDE 4

		RWStructuredBuffer<StructEdge>	_Edge;
		#define Edge_COUNT 262144
		#define Edge_STRIDE 64

		RWByteAddressBuffer	_Guassian_Position;
		#define Guassian_Position_COUNT 2097152
		#define Guassian_Position_STRIDE 16

		RWByteAddressBuffer	_Guassian_Rotation;
		#define Guassian_Rotation_COUNT 2097152
		#define Guassian_Rotation_STRIDE 16

		RWStructuredBuffer<uint2>	_Bitmap_Low;
		#define Bitmap_Low_COUNT 299648
		#define Bitmap_Low_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_High;
		#define Bitmap_High_COUNT 299648
		#define Bitmap_High_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Field_Low;
		#define Bitmap_Field_Low_COUNT 262144
		#define Bitmap_Field_Low_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Field_High;
		#define Bitmap_Field_High_COUNT 262144
		#define Bitmap_Field_High_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Tensor_Low;
		#define Bitmap_Tensor_Low_COUNT 262144
		#define Bitmap_Tensor_Low_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Tensor_High;
		#define Bitmap_Tensor_High_COUNT 262144
		#define Bitmap_Tensor_High_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Guassian_Low;
		#define Bitmap_Guassian_Low_COUNT 262144
		#define Bitmap_Guassian_Low_STRIDE 8

		RWStructuredBuffer<uint2>	_Bitmap_Guassian_High;
		#define Bitmap_Guassian_High_COUNT 262144
		#define Bitmap_Guassian_High_STRIDE 8

		RWStructuredBuffer<uint>	_Prefix_Address;
		#define Prefix_Address_COUNT 262144
		#define Prefix_Address_STRIDE 4

		RWStructuredBuffer<uint>	_Prefix_Thread;
		#define Prefix_Thread_COUNT 262144
		#define Prefix_Thread_STRIDE 4

		RWStructuredBuffer<uint>	_Prefix_Group;
		#define Prefix_Group_COUNT 512
		#define Prefix_Group_STRIDE 4

		RWStructuredBuffer<uint>	_Prefix_Sum;
		#define Prefix_Sum_COUNT 262144
		#define Prefix_Sum_STRIDE 4

		RWStructuredBuffer<uint>	_Compact;
		#define Compact_COUNT 16777216
		#define Compact_STRIDE 4


		//Targets
		RWTexture2D<float4>	_ColorTarget;
		RWTexture2D<float4>	_PriorTarget;
		RWTexture2D<float4>	_FieldTarget;
		RWTexture2D<float4>	_TensorTarget;
		RWTexture2D<float4>	_GuassianTarget;
		RWTexture2D<float4>	_GeometryTarget;
		RWTexture2D<float4>	_DiagnosticTarget;

#endif