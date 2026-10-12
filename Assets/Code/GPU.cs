using UnityEngine;
using UnityEngine.Rendering;

namespace secantastronomy
{
    using static State;

    public static class GPU
    {
        public static bool initialized                  = false;

        public static CommandBuffer[] command_buffer    { get { return _command_buffer; } }
        private static CommandBuffer[] _command_buffer  = _command_buffer ?? new CommandBuffer[Program.GetValues(typeof(Program)).Length * Kernel.GetValues(typeof(Kernel)).Length];

        public static ComputeShader[] compute           { get { return _compute; } }  
        private static ComputeShader[] _compute         = _compute ?? new ComputeShader[Program.GetValues(typeof(Program)).Length];
       
        public static ComputeBuffer[] buffer            { get { return _buffer; } }  
        private static ComputeBuffer[] _buffer          = _buffer ?? new ComputeBuffer[Buffer.GetValues(typeof(Buffer)).Length];

        public static RenderTexture[] target            { get { return _target; } set { _target = value; } }
        private static RenderTexture[] _target          = _target ?? new RenderTexture[Target.GetValues(typeof(Target)).Length];

        private static int[] _command_index             = new int[command_configuration.Length];

        private static int _screen_dispatch_x           = 0;
        private static int _screen_dispatch_y           = 0;
        private static int _screen_dispatch_i           = 0;

        public static Resolution resolution             { get { return _resolution; } }
        private static Resolution _resolution;

        public static void Initialize()
        {         
            Release();
            
            InitializeTargets();

            InitializeBuffers();

            InitializePrograms();

            InitializeCommandBuffers();

            initialized                                 = true;               
        }


        private static void InitializeCommandBuffers()
        {                           
            for(int i = 0; i < command_configuration.Length; i++)
            {           
                _command_index[i] = (command_configuration[i].program.ToString() + command_configuration[i].kernel.ToString()).GetHashCode();                     

                InitializeCommand(command_configuration[i]);
            }
        }


        private static void InitializeCommand(CommandBufferConfiguration command)
        {
            CreateCommandBuffer(command.program, command.kernel);

            SetName(command.program, command.kernel);            

            command.buffer_destination = command.buffer_destination.Length == command.buffer_source.Length ? command.buffer_destination : command.buffer_source;
            command.target_destination = command.target_destination.Length == command.target_source.Length ? command.target_destination : command.target_source;
            
            for(int j = 0; j < command.buffer_source.Length; j++) { SetBuffer(command.program, command.kernel, command.buffer_source[j], command.buffer_destination[j]); }            
            for(int j = 0; j < command.target_source.Length; j++) { SetTarget(command.program, command.kernel, command.target_source[j], command.target_destination[j]); }                            
                      
            command.x = command.x == 0 ? (command.y == 0 ? _screen_dispatch_i : _screen_dispatch_x) : command.x;
            command.y = command.y == 0 ? _screen_dispatch_y : command.y;

            SetDispatch(command.program, command.kernel, command.x, command.y, command.z);

            // Debug.Log(command_buffer[GetIndex(command.program, command.kernel)].name + " " + command.x + ", " + command.y + ", " + command.z);
        }      


        public static void InitializePrograms()
        {         
            for(int i = 0; i < Program.GetValues(typeof(Program)).Length; i++)
            {
                compute[i] = (ComputeShader)Resources.Load("Compute/" + ((Program)i).ToString()); 
            }            
        }

        
        private static ComputeBuffer InitializeBuffer(ComputeBufferConfiguration configuration)
        {
            return new ComputeBuffer(configuration.count, configuration.stride, configuration.type);
        }


        public static void InitializeBuffers()
        {         
            for(int i = 0; i < Buffer.GetValues(typeof(Buffer)).Length; i++)
            {
                buffer[i] = InitializeBuffer(buffer_configuration[i]);
            }    
        }

        private static RenderTexture InitializeTarget(RenderTargetConfiguration configuration)
        {
            return new RenderTexture(Screen.width, Screen.height, 0, configuration.format, configuration.mode);
        }


        public static void InitializeTargets()
        {
            _resolution.width                               = Screen.width;
            _resolution.height                              = Screen.height;

            for(int i = 0; i < target_configuration.Length; i++)
            {
                if (target[i] != null)          
                { 
                    target[i].Release(); 
                }

                target[i] = InitializeTarget(target_configuration[i]);
                
                target[i].enableRandomWrite = true;
                target[i].Create();       
            }                      

            _screen_dispatch_i  = (int)Mathf.Min(( _resolution.width * _resolution.height + (THREAD_GROUP_SIZE - (_resolution.width * _resolution.height) % THREAD_GROUP_SIZE))/THREAD_GROUP_SIZE, 65535);            
            _screen_dispatch_x  = (int)Mathf.Min((_resolution.width  + (THREAD_GROUP_SIZE_X -  _resolution.width % THREAD_GROUP_SIZE_X))/THREAD_GROUP_SIZE_X, 65535/THREAD_GROUP_SIZE_X);
            _screen_dispatch_y  = (int)Mathf.Min((_resolution.height + (THREAD_GROUP_SIZE_Y - _resolution.height % THREAD_GROUP_SIZE_Y))/THREAD_GROUP_SIZE_Y, 65535/THREAD_GROUP_SIZE_Y);
        }


        private static int GetIndex(Program program, Kernel kernel)
        {
            for(int i = 0; i < _command_index.Length; i++)
            {
                if((program.ToString() + kernel.ToString()).GetHashCode() == _command_index[i]) 
                {
                    return i;
                }
            }
           
            Debug.LogWarning("Warning : Command Buffer " + program.ToString() + " " + kernel.ToString() + "not found.");

            return 0;
        }


        private static void CreateCommandBuffer(Program program, Kernel kernel)
        {
            command_buffer[GetIndex(program, kernel)] = new CommandBuffer();
        }


        private static void SetName(Program program, Kernel kernel)
        {
            command_buffer[GetIndex(program, kernel)].name = program.ToString() + " " + kernel.ToString();
        }


        private static void SetBuffer(Program program, Kernel kernel, Buffer source, Buffer destination)
        {           
            command_buffer[GetIndex(program, kernel)].SetComputeBufferParam(compute[(int)program], compute[(int)program].FindKernel(kernel.ToString()), "_" + destination.ToString(), buffer[(int)source]);
        }


        private static void SetGlobalBuffer(Program program, Kernel kernel,  Buffer source, Buffer destination)
        {           
            command_buffer[GetIndex(program, kernel)].SetGlobalBuffer("_" + source.ToString(), buffer[(int)destination]);
        }


        private static void SetTarget(Program program, Kernel kernel, Target source, Target destination)
        {
            command_buffer[GetIndex(program, kernel)].SetComputeTextureParam(compute[(int)program], compute[(int)program].FindKernel(kernel.ToString()), "_" + destination.ToString() + "Target", target[(int)source]);
        }


        private static void SetExecutionFlags(Program program, Kernel kernel, CommandBufferExecutionFlags flag)
        {
            command_buffer[GetIndex(program, kernel)].SetExecutionFlags(flag);
        }


        private static void SetDispatch(Program program, Kernel kernel, int x, int y, int z)
        {
            command_buffer[GetIndex(program, kernel)].DispatchCompute(compute[(int)program], compute[(int)program].FindKernel(kernel.ToString()), x, y, z);
        }


        private static void DispatchIndirect(Program program, Kernel kernel, Buffer argument_buffer, uint offset)
        {
            command_buffer[GetIndex(program, kernel)].DispatchCompute(compute[(int)program], compute[(int)program].FindKernel(kernel.ToString()), buffer[(int)argument_buffer], offset);
        }


        public static void Dispatch(Program program, Kernel kernel)
        {
            if(initialized)
            {                          
                Graphics.ExecuteCommandBuffer(command_buffer[GetIndex(program, kernel)]);  
            }
        }


        public static bool TargetNotInitialized()
        {
            for(int i = 0; i < GPU.target.Length; i++)
            {
                if(!GPU.target[i].isReadable)
                {
                    return true;
                }
            }

            return false;
        }


        public static bool ResolutionChanged()
        {
            if(_resolution.width != Screen.width || _resolution.height != Screen.height)
            {
                InitializeTargets();
                
                InitializeCommandBuffers();

                return true;
            }
            else
            {
                return false;
            }
        }


        public static int SizeOfMemoryAllocations()
        {
            int size = 0; 
           
            for(int i = 0; i < buffer.Length; i++)
            {                
                size    += buffer[i].stride * buffer[i].count;
            }

            size += (int)Texture.currentTextureMemory;

            // for(int i = 0; i < target.Length; i++)
            // {                
            //     size    += target[i].count
            //     sizeof(target[i]);
            // }

            return size / 1000000;            
        }


        public static void GetBuffers(ref State state)
        {                              
            for (int i = 0; i < buffer_configuration.Length; i++)
            {
                state.compute_buffer_data[i] = new byte[buffer[i].count * buffer[i].stride];

                buffer[i].GetData(state.compute_buffer_data[i]);
            }
        }


        public static void SetBuffers(ref State state)
        {                   
            for (int i = 0; i < buffer_configuration.Length; i++)
            {
                buffer[i].SetData(state.compute_buffer_data[i]);    
            }
        }

        
        public static void Flush()
        {             
            for(int i = 2; i < GPU.buffer.Length; i++) //start at 2 to skip configuration buffers
            {
                GPU.buffer[i].SetData(new uint[GPU.buffer[i].count]);             
            }

            Debug.Log("GPU Buffers Flushed.");
        }


        public static void Release()
        {
            for (int i = 0; i < buffer.Length; i++)
            {
                if(buffer[i] != null)
                {
                    buffer[i].Dispose();                    
                }
            }   
        }
    }
}