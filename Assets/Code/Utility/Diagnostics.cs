using UnityEngine;
using System.Runtime.InteropServices;

namespace secantastronomy
{
    using static State;

    public static class Diagnostics
    {
        public enum GraphicsApi
        {
            Direct3D,
            OpenGL,
            Metal,
            Vulcan,
            Unknown
        }

        public static bool Test()
        {
            bool fail   = false;
            if(SystemInfo.graphicsDeviceName.Contains("ntel"))
            {
                Debug.LogWarning("Integrated GPU detected, expect poor performance. Use a dedicated GPU.\nDevice Name : " + SystemInfo.graphicsDeviceName);
                fail    = true;
            } 

            if(GPU.SizeOfMemoryAllocations() > SystemInfo.graphicsMemorySize)
            {
                Debug.LogWarning("Insufficent GPU Memory : " + GPU.SizeOfMemoryAllocations() + "mb required, but only " + SystemInfo.graphicsMemorySize + "mb available.");
                fail    = true;
            }

            if(!fail)
            {
               // Debug.Log("Diagnostic Success : All systems nominal.");
            }

            return !fail;
        }


        public static void Log()
        {
            string log = "Diagnostic Log\n";
            log += LogDeviceConfiguration();
            log += "\n\n";            
            log += LogComputeBufferConfiguration();

            Debug.Log(log);
        }

        
        public static GraphicsApi DeviceConfiguration()
        {
            return SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D", System.StringComparison.Ordinal) > -1 ? GraphicsApi.Direct3D
                 : SystemInfo.graphicsDeviceVersion.IndexOf(  "OpenGL", System.StringComparison.Ordinal) > -1 ? GraphicsApi.OpenGL
                 : SystemInfo.graphicsDeviceVersion.IndexOf(   "Metal", System.StringComparison.Ordinal) > -1 ? GraphicsApi.Metal
                 : SystemInfo.graphicsDeviceVersion.IndexOf(  "Vulcan", System.StringComparison.Ordinal) > -1 ? GraphicsApi.Vulcan
                 :                                                                                              GraphicsApi.Unknown;
        }


        public static string LogDeviceConfiguration()
        {
            int pad     = 64;

            string log  = "GPU Configuration\n";
            log         += "Name"            + SystemInfo.graphicsDeviceName.PadRight(pad/2).PadLeft(pad)                    + "\n";
            log         += "Vendor"          + SystemInfo.graphicsDeviceVendor.PadRight(pad/2).PadLeft(pad)                  + "\n";
            log         += "Version"         + SystemInfo.graphicsDeviceVersion.PadRight(pad/2).PadLeft(pad)                 + "\n";
            log         += "Memory"          + (SystemInfo.graphicsMemorySize.ToString()+"mb").PadRight(pad/2).PadLeft(pad)  + "\n";
            log         += "Async Readback"  + (SystemInfo.supportsAsyncGPUReadback.ToString()).PadRight(pad/2).PadLeft(pad) + "\n";
            log         += "Async Compute"   + (SystemInfo.supportsAsyncCompute.ToString()).PadRight(pad/2).PadLeft(pad)     + "\n";
            log         += "Sparse Textures" + (SystemInfo.supportsSparseTextures.ToString()).PadRight(pad/2).PadLeft(pad)   + "\n";
            log         += "UV Layout"       + (SystemInfo.graphicsUVStartsAtTop ? "Starts At Top" : "Starts At Bottom").PadRight(pad/2).PadLeft(pad);

            return log;
        }


        public static string LogComputeBufferConfiguration()
        {
            int size = 0; 
            
            string log = "Compute Buffers\n";
            for(int i = 0; i < GPU.buffer.Length; i++)
            {                
                size    += GPU.buffer[i].stride * GPU.buffer[i].count;

                log     += i.ToString() 
                        + " " 
                        + ((Buffer)i).ToString() 
                        + " | stride : " 
                        + GPU.buffer[i].stride.ToString() 
                        + " | count : " 
                        + GPU.buffer[i].count.ToString() 
                        + "\n";
            }

            size        /= 1000000;

            log         += "\n"
                        + "Total Buffer Memory : " 
                        + size.ToString() 
                        + "mb";

            return log;
        }
    }
}