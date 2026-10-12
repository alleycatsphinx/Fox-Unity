using UnityEngine;
using UnityEditor;

using GaussianSplatting;
using GaussianSplatting.Runtime;

namespace secantastronomy
{
    using static State;

    public class Main : MonoBehaviour 
    {                  
        public State        state;              

        public GameObject   volume;      
        public GameObject   field;
        public GameObject   sun;  

        public GameObject guassian_object;
        

        void Awake()
        {              
            ValidState();  
            
            state.gpu = state.configuration;                                   

            GPU.Initialize();            
        }
        

        void Start() 
        {           
            if(!Diagnostics.Test())
            {              
                Diagnostics.Log(); 

                #if UNITY_EDITOR
                UnityEditor.EditorApplication.isPlaying = false;
                #endif
                
                Application.Quit();
            } 
            else
            {   
                Control.Initialize();                          
                // Display.Initialize();            
            }                   
        }


        public static Vector3 Reciprocal(Vector3 v)
        {
            return new Vector3(
                v.x != 0f ? 1f / v.x : 0f,
                v.y != 0f ? 1f / v.y : 0f,
                v.z != 0f ? 1f / v.z : 0f
            );
        }


        void OnPreRender()
        {
            if(ValidState())
            {
                state.configuration.rendering.light.position        = sun.transform.position;
                //state.configuration.rendering.light.color         = sun.GetComponent<Light>().color;
                //state.configuration.rendering.light.intensity     = sun.GetComponent<Light>().intensity;

                state.configuration.encoding.transform              = Matrix4x4.TRS(volume.transform.position, volume.transform.rotation, volume.transform.localScale);
                state.configuration.field.transform                 = Matrix4x4.TRS(field.transform.position, field.transform.rotation, Reciprocal(field.transform.localScale));
                state.configuration.guassian.transform              = Matrix4x4.TRS(guassian_object.transform.position, guassian_object.transform.rotation, guassian_object.transform.localScale);

                Control.Configure(ref state);                
                Control.UploadConfiguration(ref state);      
            }                
        }


        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {             
            if(!ValidState() || GPU.TargetNotInitialized() || GPU.ResolutionChanged())
            {
                Graphics.Blit(source, destination);            
            }
            else if(Camera.current == Camera.main)
            {        
                Control.DispatchCompute(ref state);
                
                Control.DispatchRender(source, destination, ref state);
            }     
        }


        void OnPostRender()
        {
            if(ValidState())
            {
                // Control.DownloadConfiguration(ref state);    
            }               
        }

 
        public void Update()
        {    
            if(ValidState())
            {                
                Control.Update(ref state);           
            }       

            if(Input.GetKeyUp(KeyCode.G)) //TODO - unhax
            {
                GPU.buffer[(int)Buffer.Guassian_Position].SetData(guassian_object.GetComponent<GaussianSplatRenderer>().asset.posData.GetData<uint>());  
                GPU.buffer[(int)Buffer.Guassian_Rotation].SetData(guassian_object.GetComponent<GaussianSplatRenderer>().asset.otherData.GetData<uint>());  

                Debug.Log("Set Guassian Asset Position Data");
                // asset.posData
            }
        }

    
        public void OnGUI()
        {             
            Display.Update(ref state); 
        }


        void OnDisable()
        {            
            GameObject.Destroy(sun);
            GameObject.Destroy(volume);
            GameObject.Destroy(field);
            
            Display.Destroy();

            GPU.Release();
        }


        bool ValidState()
        {
            if(state == null)
            {   
                Debug.LogWarning("Warning : state == null\nFix this by using the Secant Astronomy menu tab to create a new State asset, then add it to the Main.cs script in the scene.\nCreating temporary state as a hack.");  
                
                state = new State();
            
                return false;
            } 

            return true;
        }
    }  
}

