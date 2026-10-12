using UnityEngine;

namespace secantastronomy
{
	public static class Mouse
	{
		private static Vector2 _position 	= Vector2.zero;
		public static Vector2 position
		{
			get
			{				
				_position.x 				= Input.mousePosition.x;
				_position.y 				= Input.mousePosition.y;
		
				return _position;
			}
		}


		private static Vector2 _normalized 	= Vector2.zero;
		public static Vector2 normalized
		{
			get
			{				
				_normalized.x 				= position.x / Screen.width;
				_normalized.y 				= position.y / Screen.height;
				return _position;
			}
		}


		private static Vector2 _delta	 	= Vector2.zero;
		public static Vector2 delta
		{
			get
			{				
				_delta.x 					= Input.GetAxis("Mouse X");
				_delta.y 					= Input.GetAxis("Mouse Y");			

				return _delta;
			}
		}


		private static float _scroll_0		= 0.0f;
		public static float scroll_0
		{
			get
			{	
				_scroll_0					= Input.GetAxis("Mouse ScrollWheel");
				return _scroll_0;		
			}
		}


		private static float _scroll_1		= 0.0f;
		public static float scroll_1
		{
			get
			{	
				_scroll_1					= Input.GetAxis("Mouse ScrollWheel 2");
				return _scroll_1;		
			}
		}


		private static float _scroll_2		= 0.0f;
		public static float scroll_2
		{
			get
			{	
				_scroll_2					= Input.GetAxis("Mouse ScrollWheel 3");
				return _scroll_2;		
			}
		}


		private static Vector3 _wheels		= Vector3.zero;
		public static Vector3 wheels
		{
			get
			{	
				_wheels.x 					= _scroll_0;
				_wheels.y 					= _scroll_1;
				_wheels.z 					= _scroll_2;
				return _wheels;		
			}
		}

		public static uint buttons
		{
			get
			{	
				return (Input.GetMouseButton(0) ? 0x00000001u : 0x00000000u) 
					|  (Input.GetMouseButton(1) ? 0x00000002u : 0x00000000u) 
					|  (Input.GetMouseButton(2) ? 0x00000004u : 0x00000000u); 		
			}
		}


		public static Vector3 Ray(Camera camera)
		{	
			return camera.ScreenPointToRay (Mouse.position).direction;
		}
	}
}