using UnityEngine;
using System;
using System.Text;
using System.Reflection;

namespace secantastronomy
{
    using static State;

    public static class Display
    {
        // private static StringBuilder _sb_status;
        // private static StringBuilder _sb_edit;
        // private static StringBuilder _sb_input;
        private static StringBuilder _sb_kernels;
        private static string _notes; //todo : switch to string builder

        private enum DisplayMode
        {
            Status,
            Program 
        }       

        private static DisplayMode _display_mode    = DisplayMode.Status;


        private static void BuildProgramsString(ref State state)
        {            
            _sb_kernels.Clear();            
        }


        public static void Update(ref State state)
        {                  
          
            if(state.commands.display.ui) //this ui toggle mess is nonsense! 
            {
                switch(_display_mode) 
                {                 
                    case DisplayMode.Program:    
                        BuildProgramsString(ref state);
                        Windows.SetText(_sb_kernels.ToString(), 0);  
                        break;
                    default:                       
                        break;   
                }             
            }            
            else
            {
                Windows.SetText("U | UI", 0);                           
            }
            _display_mode   = state.commands.display.programs   ? DisplayMode.Program   : _display_mode;
   
        }


        public static void Initialize()
        {      
            Windows.Initialize();

            Windows.SetActive(true);

            Windows.SetVisible( true, 0); //Intro Screen
            Windows.SetVisible(false, 1); //Compute Status 
            Windows.SetVisible(false, 2);
            Windows.SetVisible(false, 3);
            Windows.SetVisible(false, 4);
            Windows.SetVisible(false, 5);
            Windows.SetVisible(false, 6);
            Windows.SetVisible(false, 7);         
           
            Windows.SetSize(new Vector2(Screen.width * 0.5f, Screen.height), 0);                
            Windows.SetAnchor(new Vector2(0.0f,  0.0f), 0);

            // Windows.SetSize(new Vector2(Screen.width * 0.5f, Screen.height), 4);
            // Windows.SetAnchor(new Vector2(Screen.width * 0.5f - 4.0f, 0), 4);

            _sb_kernels = new StringBuilder("", 2048);

            // Debug.Log("Display Initialized");           
        }


        public static void SetActive(bool active)
        { 
            Windows.SetActive(false);
        }


        public static void Destroy()
        {
            Windows.Destroy();
        }


        public static void ParseStruct(Type type, string prefix, object instance = null, int depth = 0, int maxDepth = 10)
        {
            if (depth > maxDepth)
            {
                Debug.LogWarning($"Max depth reached for prefix: {prefix}");
                return;
            }

            FieldInfo[] fields = type.GetFields(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static);
            PropertyInfo[] properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static);

            foreach (var field in fields)
            {
                try
                {
                    object value = field.IsStatic ? field.GetValue(null) : field.GetValue(instance);

                    if (field.FieldType.IsEnum)
                    {
                        HandleEnumField(field, value, prefix);
                        continue;
                    }

                    if (!field.FieldType.IsPrimitive && field.FieldType != typeof(string) && value != null)
                    {
                        ParseStruct(field.FieldType, AppendToPrefix(prefix, field.Name), value, depth + 1, maxDepth);
                    }
                    else
                    {
                        CreateTextUI(AppendToPrefix(prefix, field.Name), value?.ToString());
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogError($"Error parsing field '{field.Name}': {ex.Message}");
                }
            }

            foreach (var property in properties)
            {
                try
                {
                    if (!property.CanRead) continue;

                    object value = property.GetGetMethod().IsStatic ? property.GetValue(null) : property.GetValue(instance);

                    if (property.PropertyType.IsEnum)
                    {
                        HandleEnumField(property, value, prefix);
                        continue;
                    }

                    if (!property.PropertyType.IsPrimitive && property.PropertyType != typeof(string) && value != null)
                    {
                        ParseStruct(property.PropertyType, AppendToPrefix(prefix, property.Name), value, depth + 1, maxDepth);
                    }
                    else
                    {
                        CreateTextUI(AppendToPrefix(prefix, property.Name), value?.ToString());
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogError($"Error parsing property '{property.Name}': {ex.Message}");
                }
            }
        }

        public static void HandleEnumField(MemberInfo field, object value, string prefix)
        {
            string fieldName = AppendToPrefix(prefix, field.Name);
            Type enumType = field is FieldInfo fi ? fi.FieldType : ((PropertyInfo)field).PropertyType;

            if (Enum.GetValues(enumType).Length > 10) // Adjust threshold as needed
            {
                // For large enums, summarize the range of values
                CreateTextUI(fieldName, $"Enum with {Enum.GetValues(enumType).Length} entries.");
            }
            else
            {
                // Display enum value directly
                CreateTextUI(fieldName, value?.ToString());
            }
        }

        public static string AppendToPrefix(string prefix, string name)
        {
            return string.IsNullOrEmpty(prefix) ? name : $"{prefix}.{name}";
        }

        public static void CreateTextUI(string commandName, string value)
        {
            _notes += $"{commandName}: {value}" + "\n";
        }
    }
}