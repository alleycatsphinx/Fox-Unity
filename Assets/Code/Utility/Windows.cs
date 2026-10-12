using UnityEngine;
using UnityEngine.UI;

namespace secantastronomy
{
    public static class Windows
    {        
        public const int WINDOW_COUNT               = 8;

        private static GameObject _parent_object    = _parent_object ?? new GameObject("Windows", typeof(Canvas), typeof(CanvasScaler));        
        private static GameObject[] _window_object  = _window_object ?? new GameObject[8];

        private const string _FONT_NAME             = "LegacyRuntime.ttf";
        // private const string _FONT_NAME             = "Fonts/Courier_New"
        
        private static Font _font                   = Resources.GetBuiltinResource<Font>(_FONT_NAME);         

        private static bool _active                 = false; 

        private static Window[] _window =
        {            
            new Window(_window_object[0]),
            new Window(_window_object[1]),
            new Window(_window_object[2]),
            new Window(_window_object[3]),
            new Window(_window_object[4]),
            new Window(_window_object[5]),
            new Window(_window_object[6]),
            new Window(_window_object[7]),
        }; 

        
        struct Window
        {
            public RectTransform    rect;
            public Text             content;
            public GameObject       gameobject;

            public Window(GameObject o)
            {
                o                           = o ?? new GameObject("Window", typeof(Canvas), typeof(Text));        

                gameobject                  = o;
                rect                        = gameobject.GetComponent<RectTransform>();
                content                     = gameobject.GetComponent<Text>();
                
                //content.font                = Resources.Load("Fonts/Courier_New") as Font;
                content.font                = Resources.GetBuiltinResource<Font>(_FONT_NAME);
                content.fontSize            = 18;
                content.lineSpacing         = 0.85f;
                content.raycastTarget       = false;
                

                gameobject.transform.SetParent(_parent_object.transform);
            }
        }


        public static void SetActive(bool active)
        {
            _active = active;
            
            _parent_object.SetActive(active);            
        }


        public static void ToggleActive()
        {
            _active = !_active;
            
            _parent_object.SetActive(_active);            
        } 
        

        public static void SetVisible(bool active, int id)
        {
            if(Valid(id)) _window[id].gameobject.SetActive(active);                
        } 


        public static void SetText(string text, int id)
        {
             if(Valid(id)) _window[id].content.text = text;
        }


        public static void SetSize(Vector2 scale, int id)
        {
            if(Valid(id)) _window[id].rect.sizeDelta = scale;
        }


        public static void SetFontColor(Color color, int id)
        {
            if(Valid(id)) _window[id].content.color = color;
        }


        public static void SetAnchor(Vector2 anchor, int id)
        {
            if(Valid(id)) _window[id].rect.anchoredPosition = anchor;
        }
 

        private static bool Valid(int id)
        {
            if(id < _window.Length) 
            {
                return true;
            }
            else
            {
                Debug.LogWarning("Console Window ID is out of range.");
                return false;    
            }
        }

        public static void Initialize()
        {
            _parent_object.GetComponent<Canvas>().worldCamera   = Camera.main;                
            _parent_object.GetComponent<Canvas>().renderMode    = RenderMode.ScreenSpaceCamera; 
            _parent_object.transform.SetParent(Camera.main.transform);
            
            Vector2 resolution  = new Vector2(Screen.width, Screen.height);
            Vector2 scale       = resolution * new Vector2(0.5f, 0.25f);
            for(int i = 0; i < _window.Length; i++)
            {
                _window[i].gameobject.name  = "Window (" + i + ")";
                
                _window[i].content.text     = _window[i].gameobject.name;

                _window[i].rect.anchorMin           = Vector2.zero;
                _window[i].rect.anchorMax           = Vector2.zero;
                _window[i].rect.pivot               = Vector2.zero;
                _window[i].rect.anchoredPosition    = Vector2.zero;;
                _window[i].rect.sizeDelta           = scale;

                //move to external initializer
                if(i < 4)
                {
                    _window[i].rect.anchoredPosition = new Vector2(0.0f, Screen.height - scale.y * (i+1));
                }
                else
                {
                    _window[i].rect.anchoredPosition = new Vector2(Screen.width * 0.5f - 4.0f, Screen.height - scale.y * (i-3));
                    _window[i].content.alignment = TextAnchor.UpperRight;
                }
            }
        }


        public static void Destroy()
        {
            for(int i = 0; i < _window.Length; i++)
            {
                GameObject.Destroy(_window[i].gameobject);
            }

            GameObject.Destroy(_parent_object);
        }
    }
}