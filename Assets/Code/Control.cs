using UnityEngine;
using System;

namespace secantastronomy
{
    using static State;    
    using static Commands;    
    using static Configuration;    

    public static class Control
    {
        private static Motion   _motion;

        private static float    _key_timer                      = 0.0f;
        private const float     _KEY_TIMER_LIMIT                = 0.3f;        


        public static void Initialize() 
        {   
            _motion                                             = Camera.main.gameObject.GetComponent<Motion>();         
            _motion                                             = _motion ?? Camera.main.gameObject.AddComponent<Motion>();                    
            _motion.use_internal_input                          = false;
            _motion.MoveToTarget(Vector3.back * 2.5f, Quaternion.identity);             
            _motion.ToggleOrbit();               
        }


        public static void Update(ref State state)
        {                  
            //note - KeyCode.G is being sinfully abused in Main.cs...

            state.commands.sim.initialize                           = Input.GetKeyUp(KeyCode.I) ? !state.commands.sim.initialize            : state.commands.sim.initialize;     
            state.commands.sim.update                               = Input.GetKeyUp(KeyCode.U) ? !state.commands.sim.update                : state.commands.sim.update;     
            state.commands.sim.flow                                 = Input.GetKeyUp(KeyCode.P) ? !state.commands.sim.flow                  : state.commands.sim.flow;     


            state.commands.motion.waypoint.create                   =  Input.GetKeyUp( KeyCode.RightShift);
            state.commands.motion.waypoint.first                    =  Input.GetKeyUp(  KeyCode.DownArrow); 
            state.commands.motion.waypoint.prior                    =  Input.GetKeyUp(  KeyCode.LeftArrow);             
            state.commands.motion.waypoint.next                     =  Input.GetKeyUp( KeyCode.RightArrow);
            state.commands.motion.waypoint.move                     =     Input.GetKeyUp( KeyCode.UpArrow)
                                                                    ||state.commands.motion.waypoint.first
                                                                    ||state.commands.motion.waypoint.prior
                                                                    || state.commands.motion.waypoint.next;


            // state.commands.display.help                         = Input.GetKeyUp(KeyCode.H);
            // state.commands.display.programs                     = Input.GetKeyUp(KeyCode.P);
            // state.commands.display.ui                           = Input.GetKeyUp(KeyCode.U) ? !state.commands.display.ui : state.commands.display.ui;

            if(_motion == null)
            {
                _motion                                         = Camera.main.gameObject.GetComponent<Motion>();         
                _motion                                         = _motion ?? Camera.main.gameObject.AddComponent<Motion>();        
            } 
            else
            {
                // _motion.SetVelocity(state.commands.motion.velocity); //todo - rewrite camera and motion system with quaternions

                if(Input.GetKey(          KeyCode.W))           _motion.Translate(Vector3.forward);
                if(Input.GetKey(          KeyCode.S))           _motion.Translate(   Vector3.back);
                if(Input.GetKey(          KeyCode.A))           _motion.Translate(   Vector3.left);
                if(Input.GetKey(          KeyCode.D))           _motion.Translate(  Vector3.right);
                if(Input.GetKey(          KeyCode.E))           _motion.Translate(     Vector3.up);
                if(Input.GetKey(          KeyCode.Q))           _motion.Translate(   Vector3.down);
                if(Input.GetKey(          KeyCode.F))           _motion.Fast();
                if(Input.GetKey(  KeyCode.LeftShift))           _motion.Slow();
                if(Input.GetKeyUp(        KeyCode.O))           _motion.ToggleOrbit();
                if(Input.GetKeyUp(    KeyCode.Space))           _motion.ToggleActive();

                //if(Input.GetKeyUp(   KeyCode.Alpha9)) {         _motion.MoveToTarget(Vector3.back * 2.5f, Quaternion.identity);             }                
            }
            
            

            // if(Input.GetKeyDown(KeyCode.P))                     { Screenshot(ref state); }


            state.commands.data.bitmap.collision                ^= Input.GetKeyUp(KeyCode.C);


            if(Input.GetKeyUp(KeyCode.Delete))                  { GPU.Flush(); }            
        }


        public static void Configure(ref State state)            
        {                                   
            state.configuration.status.frame                    = (uint)Time.frameCount;
            state.configuration.status.fps                      = (uint)Framerate.fps;
            state.configuration.status.delta_time               = (float)Time.deltaTime;
            state.configuration.status.time                     = (float)Time.time;
 
            //     _configuration.input.transform                      = input_gameobject.transform.worldToLocalMatrix; - boooring

            state.configuration.field.function                  = (uint)state.commands.data.field.function;

            state.configuration.mouse.buttons                   = 0x00000000u;
            state.configuration.mouse.position                  = Mouse.position;
            state.configuration.mouse.delta                     = Mouse.delta;
            state.configuration.mouse.wheels                    = Mouse.wheels;
            state.configuration.mouse.buttons                   = Mouse.buttons;    

            state.configuration.rendering.resolution.x          = (uint)GPU.resolution.width;
            state.configuration.rendering.resolution.y          = (uint)GPU.resolution.height;
            
            state.configuration.selection.ray                   = Camera.main.ScreenPointToRay(new Vector3(Mouse.position.x, Mouse.position.y, 0.0f)).direction; //todo make static
            
            state.configuration.rendering.projection.position   = Camera.main.transform.position;
            state.configuration.rendering.projection.direction  = Camera.main.transform.forward;
            state.configuration.rendering.projection.to_view    = Camera.main.worldToCameraMatrix;            
            state.configuration.rendering.projection.to_world   = Camera.main.cameraToWorldMatrix;     
            state.configuration.rendering.projection.view       = Camera.main.projectionMatrix;          
            state.configuration.rendering.projection.inverse    = Camera.main.projectionMatrix.inverse;
            state.configuration.rendering.projection.fov        = Camera.main.fieldOfView * 0.01f;   
            state.configuration.rendering.projection.near       = Camera.main.nearClipPlane;
            state.configuration.rendering.projection.far        = Camera.main.farClipPlane;

            state.configuration.field.collision.origin          = Camera.main.transform.position;
        }

        
        public static void DispatchCompute(ref State state)
        {   
            //Bitmapping
            if(state.commands.data.bitmap.clear)                { GPU.Dispatch(Program.Map, Kernel.Clear);              }      
            
            if(state.commands.data.bitmap.collision)            { GPU.Dispatch(Program.Map, Kernel.Collision);          }
            if(state.commands.data.bitmap.focus)                { GPU.Dispatch(Program.Map, Kernel.Focus);              }      
            if(state.commands.data.bitmap.field)                { GPU.Dispatch(Program.Map, Kernel.Field);              }            
                                                                                                                                      
            if(state.commands.data.bitmap.tensor)               { GPU.Dispatch(Program.Map, Kernel.Tensor);             }                                                                                                              
            if(state.commands.data.bitmap.guassian)             { GPU.Dispatch(Program.Map, Kernel.Guassian);           }        
            if(state.commands.data.bitmap.view)                 { GPU.Dispatch(Program.Map, Kernel.View);               }                          

            if(state.commands.data.bitmap.combine)              { GPU.Dispatch(Program.Map, Kernel.Combine);            }   

            if(state.commands.data.bitmap.tree)                 { GPU.Dispatch(Program.Tree, Kernel.Oct);               }   



            //Particle Simulation
            if(state.commands.data.tensor.sum)
            { 
                                                                  GPU.Dispatch(Program.Sum, Kernel.Tensor);   
                                                                  GPU.Dispatch(Program.Sum, Kernel.Threads);
                                                                  GPU.Dispatch(Program.Sum, Kernel.Groups);
                                                                  GPU.Dispatch(Program.Sum, Kernel.Combine);                                                              
                                                                  GPU.Dispatch(Program.Sum, Kernel.Order);
            }
           
            float iterations    = state.commands.data.tensor.iterations;
            iterations          = iterations < 1  ?  1 
                                : iterations > 32 ? 32
                                : iterations;

            for(int i = 0; i < iterations; i++)
            {
                if(state.commands.data.tensor.mesh)             { GPU.Dispatch(Program.Mesh, Kernel.Tensor);            }                                                                                                            
                                                                                                                        
            }          
            
            if(state.commands.sim.initialize)                   { GPU.Dispatch(Program.Sim, Kernel.Initialize);         }              
            if(state.commands.sim.flow)                         { GPU.Dispatch(Program.Sim, Kernel.Flow);               }
            if(state.commands.sim.field)                        { GPU.Dispatch(Program.Sim, Kernel.Field);              }
            if(state.commands.sim.bitmap)                       { GPU.Dispatch(Program.Sim, Kernel.Bitmap);             }
            if(state.commands.sim.update)                       { GPU.Dispatch(Program.Sim, Kernel.Update);             }              
        }


        public static void DispatchRender(RenderTexture source, RenderTexture destination, ref State state)
        {
            Graphics.Blit(source, GPU.target[(int)Target.Color]);                                           

            Graphics.Blit(source, GPU.target[(int)Target.Geometry]);                                                   


            if(state.commands.render.field)                     { GPU.Dispatch(    Program.Render, Kernel.Field);       }  
            if(state.commands.render.tensor)                    { GPU.Dispatch(    Program.Render, Kernel.Tensor);      }

            if(state.commands.render.cursor)                    { GPU.Dispatch(       Program.Hud, Kernel.Cursor);      }  

            if(state.commands.diagnostic.uv)                    { GPU.Dispatch(Program.Diagnostic, Kernel.UV);          }
            if(state.commands.diagnostic.vertex)                { GPU.Dispatch(Program.Diagnostic, Kernel.Vertex);      }       
            if(state.commands.diagnostic.volume)                { GPU.Dispatch(Program.Diagnostic, Kernel.Focus);       } 
            if(state.commands.diagnostic.volume)                { GPU.Dispatch(Program.Diagnostic, Kernel.Volume);      }              
            if(state.commands.diagnostic.curve)                 { GPU.Dispatch(Program.Diagnostic, Kernel.Curve);       }                                
            if(state.commands.diagnostic.derivative)            { GPU.Dispatch(Program.Diagnostic, Kernel.Derivative);  }
            if(state.commands.diagnostic.curve)                 { GPU.Dispatch(Program.Diagnostic, Kernel.Curve);       }            
            if(state.commands.diagnostic.mesh)                  { GPU.Dispatch(Program.Diagnostic, Kernel.Mesh);        }
            if(state.commands.diagnostic.collision)             { GPU.Dispatch(Program.Diagnostic, Kernel.Collision);   }
            if(state.commands.diagnostic.input)                 { GPU.Dispatch(Program.Diagnostic, Kernel.Input);       }
            if(state.commands.diagnostic.tensor)                { GPU.Dispatch(Program.Diagnostic, Kernel.Tensor);      }              
            if(state.commands.diagnostic.address)               { GPU.Dispatch(Program.Diagnostic, Kernel.Address);     }
            if(state.commands.diagnostic.bitmap)                { GPU.Dispatch(Program.Diagnostic, Kernel.Bitmap);      }  
            if(state.commands.diagnostic.memory)                { GPU.Dispatch(Program.Diagnostic, Kernel.Memory);      }               
            if(state.commands.diagnostic.target)                { GPU.Dispatch(Program.Diagnostic, Kernel.Target);      }


            if(state.commands.render.composite)                 { GPU.Dispatch( Program.Composite, Kernel.Geometry);    }  

    
            if(state.commands.render.prior)                     { GPU.Dispatch(Program.Composite, Kernel.Prior);      }

            Graphics.Blit(GPU.target[(int)Target.Color], destination);     
            
        }


        public static void UploadConfiguration(ref State state)
        {        
            if(GPU.buffer[(int)Buffer.CPU] == null)
            {       
                Debug.LogWarning("Warning : GPU.buffer[(int)Buffers.CPU] == null - NO CONFIGURATION BUFFER! Reinitializing GPU state.");
                
                // Initialize(ref state);
            }
            else
            {
                byte[] buffer_bytes = new byte[GPU.buffer[(int)Buffer.CPU].stride];
                byte[] struct_bytes = state.configuration.ToByteArray<Configuration.StructConfiguration>();

                for(int i = 0; i < struct_bytes.Length; i++) //use blockcopy?
                {
                    buffer_bytes[i] = struct_bytes[i];
                }

                GPU.buffer[(int)Buffer.CPU].SetData(buffer_bytes);                                     
            }            
        }



        public static void DownloadConfiguration(ref State state)
        {        
             GPU.GetBuffers(ref state);
             
             state.gpu = state.compute_buffer_data[1].ToStructure<Configuration.StructConfiguration>();
        }

        
        // public static void SaveBuffers(ref State state)
        // {
        //     GPU.GetBuffers(ref state);
        
        //     string timestamp                    = DateTime.Now.ToString("MM_dd_HH_mm_ss_fff");            
        //     string name                         = "compute_buffers_" + timestamp + ".dat";
        //     string path                         = Path.Combine(state.commands.system.io.path, name);
        
        //     SaveByteArrayData(state.compute_buffer_data, path);
            
        //     state.commands.system.io.file       = Directory.GetFiles(state.commands.system.io.path);
        
        //     Debug.Log($"Saved GPU buffer data to byte array file at : {path}");
        // }


        // public static void LoadBuffers(ref State state)
        // {
        //     state.commands.system.io.file       = Directory.GetFiles(state.commands.system.io.path);
        //     string name                         = state.commands.system.io.file[state.commands.system.io.index];
        //     string path                         = Path.Combine(state.commands.system.io.path, name);
            
        //     byte[][] data                       = LoadByteArrayData(path);

        //     if(data.Length > 0)
        //     {
        //         state.compute_buffer_data       = data;

        //         GPU.SetBuffers(ref state);

        //         Debug.Log($"Loaded GPU buffer data from : {path}");
        //     }
        //     else
        //     {
        //        Debug.LogError("Byte array file not found for loading.");
        //     }
        // }


        // public static void SaveByteArrayData(byte[][] data, string path)        
        // {
        //     using (FileStream filestream        = new FileStream(path, FileMode.Create, FileAccess.Write))
        //     {
        //         using (BinaryWriter writer      = new BinaryWriter(filestream))
        //         {
        //             writer.Write(data.Length);

        //             for(int i = 0; i < data.Length; i++)
        //             {
        //                 writer.Write(data[i].Length);
        //                 writer.Write(data[i]);
        //             }
        //         }
        //     }
        // }


        // public static byte[][] LoadByteArrayData(string path)        
        // {
        //     byte[][] data = new byte[0][];

        //     if (File.Exists(path))
        //     {
        //         using (FileStream filestream    = new FileStream(path, FileMode.Open, FileAccess.Read))
        //         {
        //             using (BinaryReader reader  = new BinaryReader(filestream))
        //             {                        
        //                 int count               = reader.ReadInt32();
        //                 data                    = new byte[count][];
                        
        //                 for (int i = 0; i < count; i++)
        //                 {
        //                     int length          = reader.ReadInt32();
        //                     data[i]             = reader.ReadBytes(length);
        //                 }
        //             }
        //         }             
        //     }
    
        //     return data;
        // }

        // public static void FileNext(ref State state) 
        // {
        //     state.commands.system.io.index    = (state.commands.system.io.index + 1) % state.commands.system.io.file.Length;
        // }


        // public static void FilePrior(ref State state) 
        // {
        //     state.commands.system.io.index    = state.commands.system.io.index == 0 
        //                                       ? state.commands.system.io.file.Length - 1 
        //                                       : state.commands.system.io.index - 1;
        // }
            

        public static void Screenshot(ref State state)
        {
            string path = Application.persistentDataPath + "/" + "screenshot_" + state.commands.screenshot_index.ToString() + ".png";
            ScreenCapture.CaptureScreenshot(path);
            Debug.Log("Saved screenshot to: " + path);
            state.commands.screenshot_index++;
        }

        private static bool GetKeyUpTimedConditionalToggle(KeyCode key, bool condition, bool result)
        {
            _key_timer      = Input.GetKeyDown(key) && condition ? Time.time : _key_timer;    
            if(Input.GetKeyUp(key))
            {                                
                result      = Time.time - _key_timer > _KEY_TIMER_LIMIT && condition;                
                _key_timer  = 0.0f;                
            }
            return result;
        }
    }
}
