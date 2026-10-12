using UnityEngine;
using System.Runtime.InteropServices;

namespace secantastronomy
{
	public static class MarshalStruct
	{	
	    public static byte[] ToByteArray<T>(this T structure) where T : struct
	    {
	        int bufferSize 			= Marshal.SizeOf(structure);
	        byte[] byteArray 		= new byte[bufferSize];

	        System.IntPtr handle 	= Marshal.AllocHGlobal(bufferSize);
	        Marshal.StructureToPtr(structure, handle, true);
	        Marshal.Copy(handle, byteArray, 0, bufferSize);

	        return byteArray;
	    }


	    public static T ToStructure<T>(this byte[] byteArray) where T : struct
	    {
	        T packet 				= new T();
	        int bufferSize 			= Marshal.SizeOf(packet);
	        System.IntPtr handle 	= Marshal.AllocHGlobal(bufferSize);
	        Marshal.Copy(byteArray, 0, handle, bufferSize);
 			
	        return Marshal.PtrToStructure<T>(handle);
	    }
	}
}