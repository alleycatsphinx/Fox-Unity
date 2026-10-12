using UnityEngine;

namespace secantastronomy
{
    using static Commands;
    using static Configuration;

    //This asset combines the commands and configuration which determine the systems state.
    //As "scriptable objects," entire configurations and command sets can be saved and loaded during runtime.
    [System.Serializable]
    public class State : ScriptableObject
    {       
        public StructCommands               commands;
        public StructConfiguration          configuration;
        public StructConfiguration          gpu;


        //PARSE_ENUM_BEGIN
        public enum Program
        {         
            System,   
            Map,
            Tree,
            Sum, 
            Mesh,
            Sim,  
            Render,
            Hud,
            Composite,          
            Diagnostic
        }
        

        public enum Kernel
        {
            Initialize,   
            Update,            
            Clear,
            Oct,
            Bitmap,
            Address,         
            Threads,
            Groups,
            Combine,
            Sum,    
            Order,
            Compact, 
            Mesh,
            Field,
            Focus,
            Curve,
            Prior,
            SDF,                   
            Tensor,
            Flow,
            Collision,
            Input,
            Cursor,
            Ray,    
            Guassian,
            Geometry,
            View,
            Vertex,
            Volume,
            Derivative,
            Target,
            Memory,
            UV
        }


        public enum Buffer
        {            
            CPU,
            GPU,
            Tensor,    
            Tensor_Map,
            Edge,     
            Guassian_Position,
            Guassian_Rotation,  
            Bitmap_Low,
            Bitmap_High,       
            Bitmap_Field_Low,
            Bitmap_Field_High,
            Bitmap_Tensor_Low,
            Bitmap_Tensor_High,
            Bitmap_Guassian_Low,
            Bitmap_Guassian_High,
            // SDF_Map,                          
            Prefix_Address,
            Prefix_Thread,
            Prefix_Group,
            Prefix_Sum,
            Compact
        }


        public enum Target
        {
            Color,
            Prior,
            Field,
            Tensor,
            Guassian,
            Geometry,
            Diagnostic
        }


        public enum Pass //in progress - right now it's 1 program/kernel per buffer configuration - this will allow multiple passes with different memory using the same buffer
        {
            Map_Field_Low,
            Map_Field_Mid,
            Map_Field_High,
            Map_Tensor_Low,
            Map_Tensor_Mid,
            Map_Tensor_High,
            Map_Guassian_Low,
        }
        //PARSE_ENUM_END

        
        //PARSE_DEFINITIONS_BEGIN
        public const int TENSOR_COUNT               = 262144;
        public const int GUASSIAN_COUNT             = 2097152;        
        public const int EDGE_COUNT                 = 16;        
        public const int THREAD_GROUP_SIZE          = 64;
        public const int THREAD_GROUP_SIZE_X        = 8;
        public const int THREAD_GROUP_SIZE_Y        = 8;
        public const int DISPATCH_LEAF_SIZE         = 262144/THREAD_GROUP_SIZE; //262144 * 64bit uint2 = 16777216 bits = 8^8 leaf nodes
        public const int DISPATCH_TREE_SIZE         = 299648/THREAD_GROUP_SIZE; //262144 + 4096 + 512 + 64 + 8 + 1 uint2
        public const int DISPATCH_TENSOR_SIZE       = TENSOR_COUNT/THREAD_GROUP_SIZE;
        public const int DISPATCH_GUASSIAN_SIZE     = GUASSIAN_COUNT/THREAD_GROUP_SIZE;        
        //PARSE_DEFINITIONS_END

        
        //GPU Memory Buffers (note, these must be in the same order as their corrosponding enum Buffer name above) 
        public static ComputeBufferConfiguration[] buffer_configuration =
        {
            //All in one configuration structs for simplicity's sake, one copy for the CPU and one for the GPU. The CPU one is uploaded every frame, while the GPU resides in memory (or read back for IO)
            new ComputeBufferConfiguration(              1,           2048,   ComputeBufferType.Structured,   "RWStructuredBuffer<StructConfiguration>"), //CPU Configuration        
            new ComputeBufferConfiguration(              1,           2048,   ComputeBufferType.Structured,   "RWStructuredBuffer<StructConfiguration>"), //GPU Configuration      

            //Tensors - 256 bit entities currently used in a simple particle swarm simulation
            // Each has and a list of N edges in the aligned Edges buffer, and a corrosponding address somewhere in the TensorMap buffer used to solve nearest neighbor lookup prefix sum and groupshare memory
            new ComputeBufferConfiguration(   TENSOR_COUNT,            128,   ComputeBufferType.Structured,          "RWStructuredBuffer<StructTensor>"), //Particle Tensor                 - 128 bytes ready to be cast into whatever struct you like 
            new ComputeBufferConfiguration(   TENSOR_COUNT,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>"), //Particle Tensor Map             - Pointers used to sort tensors into local bins for local neighbor lookup via prefix sum
            new ComputeBufferConfiguration(   TENSOR_COUNT, 4 * EDGE_COUNT,   ComputeBufferType.Structured,            "RWStructuredBuffer<StructEdge>"), //Particle Tensor Edges           - Per tensor edge list

            //Guassian Splat Data - These buffers duplicate the data from Aras's Guassian Splat Implementation Package (temporarialy)
            new ComputeBufferConfiguration( GUASSIAN_COUNT,             16,   ComputeBufferType.Structured,                       "RWByteAddressBuffer"), //Guassian Splat Positions        - Guassian Splat Position Data - see https://www.aras-p.info/blog/2023/09/05/Gaussian-Splatting-is-pretty-cool/
            new ComputeBufferConfiguration( GUASSIAN_COUNT,             16,   ComputeBufferType.Structured,                       "RWByteAddressBuffer"), //Guassian Splat Scale Rotations  - Guassian Splat "Other" Data
            
            //"Bitmaps" are 1D space filling curve maps of 3D space using bits to representing occupancy 
            //The first 16777216 bits (8^8) are leaf nodes
            //The next 262144 (8^7) are their parent nodes, etc up to the last 8 bits (the root nodes) - I'm tempted to split them into two buffers, one for the tree and one with just leaves...
            //Various input sources each get their own map, which are then combined into the global bitmap for rendering, tree building, and comparisons
            new ComputeBufferConfiguration(         299648,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Tree Low Frequency       - Octave 0 - 8
            new ComputeBufferConfiguration(         299648,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Tree High Frequency      - Octave 8 - 16
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Field Low Frequency      
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Field High Frequency
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Tensor Low
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Tensor High
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Guassian Low
            new ComputeBufferConfiguration(         262144,              8,   ComputeBufferType.Structured,                 "RWStructuredBuffer<uint2>"), //Bitmap Guassian High   

            //A discretized signed distance field          
            // new ComputeBufferConfiguration(    1048576,    4,   ComputeBufferType.Raw,                              "RWByteAddressBuffer"), //SDF Map       - Discrete Signed Distance Field from Bitmap, 8 frequencies, 8 bits per - requires tree kernel

            //Prefix Sum Buffers
            new ComputeBufferConfiguration(         262144,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>"), //Prefix_Address
            new ComputeBufferConfiguration(         262144,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>"), //Prefix_Thread
            new ComputeBufferConfiguration(            512,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>"), //Prefix_Group
            new ComputeBufferConfiguration(         262144,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>"), //Prefix_Sum
            new ComputeBufferConfiguration(       16777216,              4,   ComputeBufferType.Structured,                  "RWStructuredBuffer<uint>")  //Compact Stream Buffer
        };


        //Render Targets (note, these must be in the same order as their corrosponding Target enum above) 
        public static RenderTargetConfiguration[] target_configuration =
        {
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear),
            new RenderTargetConfiguration(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)            
        };


        //CPU side byte arrays for reading back compute buffers
        public byte[][] compute_buffer_data = new byte[Buffer.GetValues(typeof(Buffer)).Length][];


        //Compute Buffer Definition
        [System.Serializable]
        public struct ComputeBufferConfiguration 
        { 
            public int count;
            public int stride;             
            public ComputeBufferType type; 
            public string structure; 
            
            public ComputeBufferConfiguration(int c, int v, ComputeBufferType t, string s)
            {
                count     = c;
                stride    = v;
                type      = t;
                structure = s;                
            }
        }


        [System.Serializable]
        public struct RenderTargetConfiguration 
        { 
            public int                      width;
            public int                      height;
            public RenderTextureFormat      format;
            public RenderTextureReadWrite   mode;
            
            public RenderTargetConfiguration(int w, int h, RenderTextureFormat f, RenderTextureReadWrite m)
            {
                width   = w;
                height  = h;
                format  = f;
                mode    = m;                
            }
        }


        //Command Buffer Definition
        [System.Serializable]
        public struct CommandBufferConfiguration 
        { 
            public Program program;                 //.compute File
            public Kernel kernel;                   //Name of kernel within said compute file
            public Buffer[] buffer_source;          //Enum used to access the buffer
            public Buffer[] buffer_destination;     //Enum used to bind the buffer - if this is empty it will be populated with the buffer_source enums, making a 1:1 binding
            public Target[] target_source;          //Enum used to access the target
            public Target[] target_destination;     //Enum used to bind the target - same as buffers if empty

            //Compute group dimensions - can be 1D, 2D or 3D - usually 64 threads per group
            public int x;   
            public int y;
            public int z;

            public CommandBufferConfiguration(Program p, Kernel k, Buffer[] bs, Buffer[] bd, Target[] ts, Target[] td, int dx, int dy, int dz)
            {
                program             = p;
                kernel              = k;
                buffer_source       = bs;
                buffer_destination  = bd;               
                target_source       = ts;
                target_destination  = td;
                x                   = dx;
                y                   = dy;
                z                   = dz;
            }
        }

        //GPU Commands 
        //This list defines the dispatchs which the GPU can executed
        //It defines which Kernels from within ".compute" Programs run using which memory Buffers and Render Targets
        //The xyz threadgroup sizes are specified at the end
        public static CommandBufferConfiguration[] command_configuration =     
        {
            new CommandBufferConfiguration
            (
                Program.System, 
                Kernel.Update, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),     
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Clear, 
                new Buffer[] { Buffer.Bitmap_Low, Buffer.Bitmap_High, Buffer.Bitmap_Field_Low, Buffer.Bitmap_Field_High, Buffer.Bitmap_Tensor_Low, Buffer.Bitmap_Tensor_High, Buffer.Bitmap_Guassian_Low, Buffer.Bitmap_Guassian_High },  
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_TREE_SIZE, 1, 1 //use tree size and clear tree too?
            ),  
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Combine, 
                new Buffer[] { Buffer.Bitmap_Low, Buffer.Bitmap_High, Buffer.Bitmap_Field_Low, Buffer.Bitmap_Field_High, Buffer.Bitmap_Tensor_Low, Buffer.Bitmap_Tensor_High, Buffer.Bitmap_Guassian_Low, Buffer.Bitmap_Guassian_High },  
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1 
            ),                
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Field,
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Field_Low },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),           
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Focus,
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Field_High },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),   
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Tensor, 
                new Buffer[] { Buffer.CPU,  Buffer.Tensor, Buffer.Bitmap_Tensor_Low },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),   
            new CommandBufferConfiguration
            (
                //used to set the position for the high frequency bitmap used by the field encoder - mostly just a test/stub for later
                Program.Map, 
                Kernel.Collision, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                1, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.Guassian,
                new Buffer[] { Buffer.CPU, Buffer.Bitmap_Guassian_Low, Buffer.Bitmap_Guassian_High, Buffer.Guassian_Position, Buffer.Guassian_Rotation },  
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_GUASSIAN_SIZE, 1, 1
            ),      
            new CommandBufferConfiguration
            (
                Program.Map, 
                Kernel.View,    //reads the guassian xyz integral from the rendertarget and bitmaps the result
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Guassian_Low, Buffer.Bitmap_Guassian_High },  
                new Buffer[] { },  
                new Target[] { Target.Geometry},
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1 
            ),                            
            new CommandBufferConfiguration
            (
                Program.Tree, 
                Kernel.Oct,     //transforms the bitmap into a linear tree - next step will convert it to a compressed octree, sdf, etc
                new Buffer[] { Buffer.CPU, Buffer.Bitmap_Low, Buffer.Bitmap_High },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TREE_SIZE, 1, 1
            ),                     
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Threads, 
                new Buffer[] { Buffer.CPU, Buffer.Prefix_Address, Buffer.Prefix_Thread, Buffer.Prefix_Group },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                512, 1, 1
            ),     
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Groups, 
                new Buffer[] { Buffer.CPU, Buffer.Prefix_Thread, Buffer.Prefix_Group },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                1, 1, 1
            ),     
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Combine, 
                new Buffer[] { Buffer.CPU, Buffer.Prefix_Thread, Buffer.Prefix_Group, Buffer.Prefix_Sum, Buffer.Prefix_Address },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                512, 1, 1
            ),                 
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Bitmap, //reads bitmap for compacting the stream
                new Buffer[] { Buffer.CPU, Buffer.Prefix_Address, Buffer.Bitmap_Low },
                new Buffer[] { },  
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),    
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Compact, //outputs the compacted list of occupied positions
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Prefix_Address, Buffer.Prefix_Sum, Buffer.Compact },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Tensor, //reads in the tensor positions
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Prefix_Address, Buffer.Prefix_Sum, Buffer.Tensor, Buffer.Tensor_Map },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),         
            new CommandBufferConfiguration
            (
                Program.Sum, 
                Kernel.Order, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Prefix_Address, Buffer.Prefix_Sum },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),    
            new CommandBufferConfiguration
            (
                Program.Mesh, 
                Kernel.Tensor, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),       
            new CommandBufferConfiguration
            (
                Program.Sim, 
                Kernel.Initialize, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),      
            new CommandBufferConfiguration
            (
                Program.Sim, 
                Kernel.Update, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),          
            new CommandBufferConfiguration
            (
                Program.Sim, 
                Kernel.Flow, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),  
            new CommandBufferConfiguration
            (
                Program.Sim, 
                Kernel.Field, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),        
            new CommandBufferConfiguration
            (
                Program.Sim, 
                Kernel.Bitmap, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Edge, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),                                                                      
            new CommandBufferConfiguration
            (
                Program.Render, 
                Kernel.Field, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Geometry, Target.Prior, Target.Field, Target.Diagnostic },
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1
            ),   
            new CommandBufferConfiguration
            (
                Program.Render, 
                Kernel.Tensor, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Edge },  
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Geometry, Target.Prior, Target.Tensor, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),   
            new CommandBufferConfiguration
            (
                Program.Hud, 
                Kernel.Cursor, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },  
                new Target[] { Target.Color },
                new Target[] { },
                1, 1, 1
            ), 
            new CommandBufferConfiguration
            (
                Program.Composite, 
                Kernel.Geometry,        //used for all compositing - should be split into color etc
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Prior, Target.Field, Target.Tensor, Target.Guassian, Target.Geometry, Target.Diagnostic },           
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1 
            ),             
            new CommandBufferConfiguration
            (
                Program.Composite, 
                Kernel.Prior,        //used for all compositing - should be split into color etc
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Prior, Target.Field, Target.Tensor, Target.Guassian, Target.Geometry, Target.Diagnostic },           
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1 
            ),                               
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Vertex, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),                         
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Volume, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Low },
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TREE_SIZE, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Focus, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_High },
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TREE_SIZE, 1, 1
            ),
             new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Derivative, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Tensor, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Address, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Edge, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),      
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Curve, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Mesh, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Edge },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),                       
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Vertex, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),    
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Collision, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                1, 1, 1
            ),         
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Input, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },  
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1
            ),     
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Bitmap, 
                new Buffer[] { Buffer.CPU, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_LEAF_SIZE, 1, 1
            ),    
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Memory, 
                new Buffer[] { Buffer.CPU, Buffer.GPU, Buffer.Tensor, Buffer.Tensor_Map, Buffer.Bitmap_Low },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_TENSOR_SIZE, 1, 1
            ),    
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.Target, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Prior, Target.Field, Target.Tensor, Target.Guassian, Target.Geometry, Target.Diagnostic },             
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1
            ),
            new CommandBufferConfiguration
            (
                Program.Diagnostic, 
                Kernel.UV, 
                new Buffer[] { Buffer.CPU, Buffer.GPU },  
                new Buffer[] { },
                new Target[] { Target.Color, Target.Diagnostic },
                new Target[] { },
                DISPATCH_WIDTH, DISPATCH_HEIGHT, 1
            )
        };


        //GPU Command variable size buffer flags
        const int DISPATCH_WIDTH         = 0; 
        const int DISPATCH_HEIGHT        = 0;
        const int DISPATCH_RENDERTARGET  = 0;


        //GPU Type Emulation
        [System.Serializable]
        public struct int4  { public int x; public int y; public int z; public int w;       }


        [System.Serializable]
        public struct uint2 { public uint x; public uint y;                                 }


        [System.Serializable]
        public struct uint3 { public uint x; public uint y; public uint z;                  }


        [System.Serializable]
        public struct uint4 { public uint x; public uint y; public uint z; public uint w;   }
    }
}
