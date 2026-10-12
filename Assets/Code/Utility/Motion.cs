using UnityEngine;

namespace secantastronomy
{
    public class Motion : MonoBehaviour 
    {
        public float acceleration           = 8.0f;         // how fast you accelerate
        public float fast_multiplier        = 24.0f;        // how much faster you go when activated
        public float slow_multiplier        = 0.002f;       // how much slower you go when activated
        public float sensitivity            = 4.0f;         // mouse look sensitivity
        public float damping_coefficient    = 8.0f;         // how quickly you break to a halt after you stop your input        
        public float target_interpolant     = 0.125f; 
        public float collision_threshold    = 0.00001f; 
        public float restitution_velocity   = 0.000001f; 

        public bool active_on_enable        = true;         // whether or not to focus and lock cursor immediately on enable
        public bool use_internal_input      = true;         // use internal keys to control drive motion instead of getting input from an external class - should do the same for mouse...
        
        private bool _fast                  = false;
        private bool _slow                  = false;
        private bool _active                = false;
        private bool _orbit                 = false;
        private bool _interpolate           = false;

        private Vector3 _velocity           = Vector3.zero;        
        private Vector2 _rotation_input     = Vector2.zero;
        private Vector3 _motion_input       = Vector2.zero;
        private Vector3 _direction          = Vector3.zero;     
        private float _distance             = 0.0f;
        private Vector2 _angle              = Vector2.zero;              
        private Vector3 _position           = Vector3.zero;
        private Quaternion _rotation        = Quaternion.identity;    
        private float _zoom_damper          = 0.0f;
        private float _velocity_multiplier  = 1.0f;

        private Vector3 _target_orbit       = Vector3.zero; 
        private Vector3 _target_position    = Vector3.zero;
        private Quaternion _target_rotation = Quaternion.identity;        

        public float xSpeed                 = 240.0f;
        public float ySpeed                 = 240.0f;
     
        public float yMinLimit              = -0f;
        public float yMaxLimit              = 80f;
     
        public float distanceMin            = 0.0000005f;
        public float distanceMax            = 2.5f;
   

        void Awake()
        {
            _active                         = active_on_enable;   
            Cursor.visible                  = true;
            Cursor.lockState                = CursorLockMode.None; 
            fast_multiplier                 = Mathf.Max(1.0f, fast_multiplier);
            slow_multiplier                 = Mathf.Min(1.0f, slow_multiplier);        
        }


        void Update()
        {
            Cursor.lockState    = _active ? CursorLockMode.Locked : CursorLockMode.None;
        
            if(use_internal_input)
            {
                GetInput();  
            }

            Move();
        }

        
        void OnEnable()                                         { _active           = active_on_enable; }
                                            
        void OnDisable()                                        { _active           = false;            }         

        public void Fast()                                      { _fast             = true;             }    
        public void Slow()                                      { _slow             = true;             }    
        
        public void ToggleActive()                              { _active           = !_active;         }
        public void SetOrbitTarget(Vector3 position)            { _target_orbit           = position;   }    
        
        public void Translate(Vector3 direction)                { _motion_input     += direction;       }    
        public void Rotate(Vector2 rotation_delta)              { _rotation_input   = rotation_delta;   }   


        public void Move()
        {
            if(_active)
            {  
                _interpolate            = _interpolate && Input.anyKey ? !_interpolate : _interpolate;
                _rotation_input         = new Vector2(Input.GetAxis("Mouse X"), -Input.GetAxis("Mouse Y")) * sensitivity;     

                if(_orbit || _interpolate)
                {
                    transform.rotation  = _rotation;
                }
                else
                {
                    transform.Rotate(Vector3.up, _rotation_input.x, Space.World); 
                    transform.Rotate(Vector3.right, _rotation_input.y,  Space.Self);    

                    // Quaternion pitch    = Quaternion.AngleAxis(-_rotation_input.y, Vector3.right);
                    // Quaternion yaw      = Quaternion.AngleAxis( _rotation_input.x, Vector3.up);
                    // Quaternion rollQuat = Quaternion.AngleAxis(roll, Vector3.forward);                                             
                } 
                  

                //testing to see if this fixes collision
                _position.x             = _position.x >  10.0f ?   10.0f : _position.x;
                _position.y             = _position.y >  10.0f ?   10.0f : _position.y;
                _position.z             = _position.z >  10.0f ?   10.0f : _position.z;

                _position.x             = _position.x < -10.0f ?  -10.0f : _position.x;
                _position.y             = _position.y < -10.0f ?  -10.0f : _position.y;
                _position.z             = _position.z < -10.0f ?  -10.0f : _position.z;

                transform.position      = _position;  

                if(_interpolate)
                {
                    Interpolate();
                }
                else
                {      
                    if(_orbit)
                    {
                        Orbit();              
                    }
                    else
                    {
                        Drive();
                    } 
                }
            }
        }


        public void Drive()
        {                                     
            _rotation_input         *= sensitivity;
            _direction              = transform.TransformVector(_motion_input.normalized);
        
            if(_slow)       
            {       
                _velocity           += _direction * acceleration * slow_multiplier * Time.deltaTime * _velocity_multiplier; // slow mode
            }       
            else if(_fast)      
            {       
                _velocity           += _direction * acceleration * fast_multiplier * Time.deltaTime * _velocity_multiplier; // fast mode
            }       
            else        
            {       
                _velocity           += _direction * acceleration * Time.deltaTime * _velocity_multiplier;   
            }       
        
            _velocity               = Vector3.Lerp(_velocity, Vector3.zero, damping_coefficient * Time.deltaTime );
        
            _slow                   = false;
            _fast                   = false;
            _motion_input           = Vector3.zero;        
        
            _position               += _velocity * Time.deltaTime;              
        }


        public void Orbit()  
        {                  
            _angle                  = transform.eulerAngles;
    
            _angle.y                += Input.GetAxis("Mouse X") * xSpeed * Mathf.Max(1.0f, _distance) * 0.02f;
            _angle.x                -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f; 
                
            _rotation               = Quaternion.Euler(_angle.x, _angle.y, 0.0f);
    
            _zoom_damper            = Mathf.Clamp(_distance, 0.000001f, 1.0f);
            _distance               = Mathf.Clamp(_distance - Input.GetAxis("Mouse ScrollWheel") * 5.0f * _zoom_damper, distanceMin, distanceMax);
                
            _position               = _rotation * new Vector3(0.0f, 0.0f, -_distance) + _target_orbit;
        }    


        public void Interpolate()
        { 
            if(Mathf.Abs(Vector3.Dot(_position - _target_position, Vector3.one)) > 0.001f ? Vector3.Magnitude(_position - _target_position) < 0.001f : false)
            {                
                if(!_orbit)
                {
                    _position       = _target_position;
                    _rotation       = _target_rotation;
                }
                
                _interpolate        = false;   
            }
            else
            {
                _position           = Vector3.Lerp(_position, _target_position, target_interpolant);

                if(!_orbit)
                {
                    _rotation       = Quaternion.Lerp(_rotation, _target_rotation, target_interpolant);                           
                }
                else
                {
                    transform.LookAt(_target_orbit);                    
                    _distance       = Vector3.Magnitude(_position - _target_orbit);
                    _angle          = transform.eulerAngles;      
                    _rotation       = transform.rotation;              
                }
                
                _interpolate        = true;                
            }      
        }


        public void MoveToTarget(Vector3 position, Quaternion rotation) 
        { 
            _target_position        = position; 
            _target_rotation        = rotation;

            _interpolate            = true;         
        }   


        public void SetVelocity(float velocity) 
        {

            _velocity_multiplier = velocity;
        }


        public void ToggleOrbit()                               
        { 
            _orbit                  = !_orbit; 

            transform.LookAt(_target_orbit); 

            _angle = transform.eulerAngles; 
            _rotation = Quaternion.Euler(_angle.x, _angle.y, 0.0f);
        }    
  

        public void ResolveCollision(Vector3 position, Vector3 direction, float range, float distance)
        {
            if(!System.Single.IsNaN(position.x) && !System.Single.IsNaN(direction.x) && !System.Single.IsNaN(range) && !System.Single.IsNaN(distance))
            {
                if(range < collision_threshold)
                {
                    // _velocity           -= direction * Time.deltaTime * restitution_velocity; //restitution velocity, really 
                    _position           -= _velocity  * Time.deltaTime * 0.5f;         
                    _velocity           -= direction * Time.deltaTime * Vector3.Magnitude(_velocity) * 0.5f; //restitution velocity, really     
                }
            }
        }


        private void GetInput()
        {    
            if(Input.GetKey(          KeyCode.W))   Translate(Vector3.forward);
            if(Input.GetKey(          KeyCode.S))   Translate(   Vector3.back);
            if(Input.GetKey(          KeyCode.A))   Translate(   Vector3.left);
            if(Input.GetKey(          KeyCode.D))   Translate(  Vector3.right);
            if(Input.GetKey(          KeyCode.E))   Translate(     Vector3.up);
            if(Input.GetKey(          KeyCode.Q))   Translate(   Vector3.down);
            if(Input.GetKey(          KeyCode.F))   Fast();
            if(Input.GetKey(  KeyCode.LeftShift))   Slow();
            if(Input.GetKeyUp(      KeyCode.Tab))   ToggleOrbit();
            if(Input.GetKeyUp(    KeyCode.Space))   ToggleActive();                        
        }
    }
}


