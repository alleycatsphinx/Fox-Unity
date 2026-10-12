using UnityEngine;

namespace secantastronomy
{
    using static State;

    //This class has all the controls that drive the system - all commands should be routed through here.
    [System.Serializable]
    public class Commands : ScriptableObject
    {       
        [System.Serializable]       
        public enum EnumFieldFunction
        {         
            None,   
            Sphere,
            Fractal,
            Comet,
            Alba
        }

        [System.Serializable]
        public struct StructFieldCommands
        {        
            public EnumFieldFunction                function;
        }


        [System.Serializable]
        public struct StructTensorCommands
        {
            public bool                             map;
            public bool                             sum;
            public bool                             mesh;   
            public uint                             iterations;                 
        }


        [System.Serializable]
        public struct StructGuassianCommands
        {
            public bool                             load;
        }


        [System.Serializable]
        public struct StructViewCommands
        {
        }


        [System.Serializable]
        public struct StructBitmapCommands
        {   
            public bool                             combine;
            public bool                             tree;
            public bool                             clear;
            public bool                             field;
            public bool                             tensor;
            public bool                             guassian;
            public bool                             view;
            public bool                             focus;
            public bool                             collision;
        }        


        [System.Serializable]
        public struct StructDataCommands
        {            
            public StructBitmapCommands             bitmap;
            public StructFieldCommands              field;
            public StructTensorCommands             tensor;
            public StructGuassianCommands           guassian;
            public StructViewCommands               view;
        }
        
        
        [System.Serializable]
        public struct StructSimCommands
        {   
            public bool                             initialize;
            public bool                             field;
            public bool                             bitmap;
            public bool                             flow;
            public bool                             update;  
        }



        [System.Serializable]
        public struct StructRenderCommands
        {
            public bool                             field;
            public bool                             tensor;
            public bool                             prior;
            public bool                             radiance;
            public bool                             cursor;
            public bool                             composite;
        }
        

        [System.Serializable]
        public struct StructDiagnosticCommands
        {                   
            public bool                             vertex;
            public bool                             volume;
            public bool                             derivative;
            public bool                             tensor;
            public bool                             address;
            public bool                             curve;
            public bool                             mesh;
            public bool                             collision;
            public bool                             input;
            public bool                             bitmap;            
            public bool                             memory;            
            public bool                             target;  
            public bool                             uv;
        }


        [System.Serializable]
        public struct StructWayPointCommands
        {   
            public bool                             first;
            public bool                             prior;
            public bool                             next;
            public bool                             move;
            public uint                             index;
            public bool                             create;
        }


        [System.Serializable]
        public struct StructMotionCommands
        {
            public bool                             forward;
            public bool                             back;
            public bool                             left;
            public bool                             right;
            public bool                             up;
            public bool                             down;
            public bool                             fast;
            public bool                             slow;

            public bool                             orbit;
            public bool                             auto_rotate;
            public bool                             active;     

            public StructWayPointCommands           waypoint;       
        }


        [System.Serializable]
        public struct StructDisplayCommands
        {
            public bool                             help;
            public bool                             programs;
            public bool                             status;
            public bool                             notes;
            public bool                             ui;
        }
        

        [System.Serializable]
        public struct StructCommands
        {   
            public StructDataCommands               data;
            public StructSimCommands                sim;
            public StructRenderCommands             render;
            public StructDiagnosticCommands         diagnostic;
            public StructDisplayCommands            display;   
            public StructMotionCommands             motion;

            public Matrix4x4[]                      waypoint;

            [HideInInspector]
            public uint                             screenshot_index;             
        }
    }
}
