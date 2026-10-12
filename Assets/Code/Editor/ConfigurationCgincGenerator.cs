using UnityEngine;
using System.IO;
using UnityEditor;

namespace secantastronomy
{
	using static State;

	//this code is ghetto - sorry 
	//todo : make auto execute on changes to config, get thread definitions and enums from state automatically

    public static class ConfigurationCgincGenerator
    {        
    	private const string PATH_STATE 			= "Assets/Code/ScriptableObjects/State.cs";
		private const string PATH_CONFIGURATION 	= "Assets/Code/ScriptableObjects/Configuration.cs";		
		private const string PATH_CGINC				= "Assets/Resources/Compute/Includes/configuration.cginc";
		
		private const string RW_STRUCTURED_BUFFER	= "RWStructuredBuffer";
		private const string RAW_BYTE_BUFFER		= "RawByte";


		private static readonly string[,] _syntax_replacement_strings = new string[,] 
		{ 			
			{ "[HideInInspector]", "" },
			{ "[Space]", "" },
			{ "[Range(0.0f, 1.0f)]", "" },	
			{ "[System.Serializable]", "" }, 
			{ "public Color ", "float4 " },
			{ "public ", "" },		
			{ "const ", "" },
			{ "=", "" },
			{ "\t", " " },
			{ "} ", "};" },
			{ "bool", "uint " },
			{ "_OPEN_BRACKET_", "[" },
			{ "_CLOSE_BRACKET_", "]" },	
			{ "[StructLayout(LayoutKind.Sequential)]", "" },					
			{ "harmonics", "harmonics[45]" }, //disgusting hack - fix!
			{ "float[]", "float" }		//also >.<			
		};


		[MenuItem("Secant Astronomy/Synchronize/CPU to GPU Configuration")]
		public static void Write()
		{
			////PARSE CONFIGURATION .CS
			StreamReader reader					= new StreamReader(PATH_CONFIGURATION);
			string code         				= reader.ReadToEnd();
			reader.Close();			
			
			int parse_start						= code.IndexOf("//PARSE_CONFIGURATION_BEGIN") + 27; //27 = length of "//PARSE_CONFIGURATION_BEGIN" string
			int parse_end       				= code.IndexOf("//PARSE_CONFIGURATION_END");
			
			code								= code.Substring(parse_start, parse_end - parse_start);
			////PARSE CONFIGURATION .CS


			////GRENERATE CONFIGURATION .CGINC					
			//first replace enum strings with "uint" 
			//we access the State.cs file to extract the enum names - these will be replaced with "uint" in the gpu config
			//potentially we can generate matching #defines to make the gpu code easier to read
			reader 								= new StreamReader(PATH_STATE);
			string state_string     			= reader.ReadToEnd();			
			reader.Close();


			////DEFINITIONS
			//parse out the definitions
			parse_start     					= state_string.IndexOf("//PARSE_DEFINITIONS_BEGIN") + 25; //25 = length of string
			parse_end       					= state_string.IndexOf("//PARSE_DEFINITIONS_END");
			string definitions_string 			= state_string.Substring(parse_start, parse_end - parse_start);
	
			for(int i = 0; i < _syntax_replacement_strings.Length/2; i++)		
			{
				definitions_string				= definitions_string.Replace(_syntax_replacement_strings[i,0], _syntax_replacement_strings[i,1]);	
			}

			definitions_string					= definitions_string.Replace("int", "#define");	
			definitions_string					= definitions_string.Replace(";", "");	
			definitions_string					= "\n\n\t\t//Definitions\t\t" + definitions_string;
			////END DEFINITIONS


			////ENUMERATIONS
			parse_start     					= state_string.IndexOf("//PARSE_ENUM_BEGIN") + 18; //18 = length of string
			parse_end       					= state_string.IndexOf("//PARSE_ENUM_END");
			string enum_string     				= state_string.Substring(parse_start, parse_end - parse_start);

			//first count enums by removing all occurances of "enum" and checking the difference in length between it and the origional
			int count 							= (enum_string.Length - enum_string.Replace("enum", "").Length);
			count 								= count > 0 ? count / 4 : 0; //because there are 4 characters in "enum"						

			//if the count is > 0 we next extract the enum names replace them in the .cginc code string
			if(count != 0)
			{
				string enum_replacement_string 	= "";
				//we know all enum names are preceded by "enum " and followed up with "{" so we first find the earliest index of "enum " and then the following index of "{"
				//then we write the string to the array, remove the characters in that interval, and repeat
				for(int i = 0; i < count; i++)
				{
					parse_start     			= enum_string.IndexOf("enum ") + 5;
					parse_end       			= enum_string.IndexOf("{");

					enum_replacement_string 	= enum_string.Substring(parse_start, parse_end - parse_start);
					
					enum_string 				= enum_string.Remove(parse_start - 5, enum_replacement_string.Length + 6);
					enum_replacement_string 	= enum_replacement_string.Remove(enum_replacement_string.IndexOf(" ")-1);
					
					code						= code.Replace(enum_replacement_string, "uint");					
				}
			}			
			////END ENUMERATIONS

			//next add .cginc syntax and remove excess .cs syntax 
			for(int i = 0; i < _syntax_replacement_strings.Length/2; i++)		
			{
				code							= code.Replace(_syntax_replacement_strings[i,0], _syntax_replacement_strings[i,1]);	
			}


			//write arguments			
			// string arguments 					= "\n\n\t\t//Arguments\n\t\t#define THREAD_GROUP_SIZE " + threadgroup_string + "\n";
			// string arguments 		= "\n\n//Arguments\n";
			// for(int i = 0; i < Argument.GetValues(typeof(Argument)).Length; i++)
			// {					
			// 	arguments 			+= "#define ARGUMENT_" + ((Argument)i).ToString() + "\t" + i + "\n";
			// }
			// arguments 				+= "#define ARGUMENT_COUNT " + Argument.GetValues(typeof(Argument)).Length + "\n";
			// code								+= arguments;

			//write buffer definitions
			string buffers 						= "\n\n\t\t//Buffers\n";
			for(int i = 0; i <  Buffer.GetValues(typeof(Buffer)).Length; i++)
			{
				buffers							+= "\t\t" + buffer_configuration[i].structure + "\t_" + ((Buffer)i).ToString() + ";\n";					
				if(i < 2)
				{
					buffers						+= "\t\t#define " + ((Buffer)i).ToString() + "\t_" + ((Buffer)i).ToString() + "[0]\n";	
				}				
				buffers							+= "\t\t#define " + ((Buffer)i).ToString() + "_COUNT " + buffer_configuration[i].count + "\n";
				buffers							+= "\t\t#define " + ((Buffer)i).ToString() + "_STRIDE " + buffer_configuration[i].stride + "\n\n";
			}
			code								+= buffers;

			//write target definitions
			string targets 						= "\n\t\t//Targets\n";
			for(int i = 0; i < Target.GetValues(typeof(Target)).Length; i++)
			{
				targets							+= "\t\tRWTexture2D<float4>\t_" + ((Target)i).ToString() + "Target;\n";													
			}
			code								+= targets;
			

			code 								= definitions_string + code;

			//add header and footer
			code 								= "#ifndef CONFIGURATION\n\t#define CONFIGURATION" + code;
			code 								+= "\n#endif";			
			////END GENERATE CONFIGURATION .CGINC


			////WRITE FILE
			StreamWriter writer 				= new StreamWriter(PATH_CGINC, false, System.Text.Encoding.UTF8);
			writer.Write(code);
			writer.Close();
			
			Debug.Log("Generated " + PATH_CGINC + " from "+ PATH_CONFIGURATION);
			////END WRITE
		}
    }
}