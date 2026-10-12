using UnityEngine;

namespace secantastronomy
{
	public static class Framerate 
	{
		public static string fps_string { get { return digits[Mathf.Clamp(_fps, 0, 99)]; } }
		public static int fps 			{ get { return _fps; } }

		private const int WINDOW		= 8;		
		private static int[] _buffer	= new int[WINDOW];
		private static int _fps			= 60;		
		private static int _index		= 0;
		private static int _sum			= 60;

		static string[] digits			= 
		{
			"00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
			"10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
			"20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
			"30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
			"40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
			"50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
			"60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
			"70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
			"80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
			"90", "91", "92", "93", "94", "95", "96", "97", "98", "99"
		}; //this avoids gc allocation on string creation
	
	
		public static void Initialize () 
		{			
			_buffer 		= new int[WINDOW];
			_buffer[0]		= 0;
			_index 			= 0;
		}
	
	
		public static void Update () 
		{		
			if (_buffer.Length != WINDOW) 
			{
				Initialize();
			}
			
			_buffer[_index++ % WINDOW] 	= (int)Mathf.Min(1f / Time.unscaledDeltaTime, 99.0f);
	
			_sum						= 0;
			for (int i = 0; i < WINDOW; i++) 
			{
				_sum 					+= _buffer[i];			
			}
	
			_fps 						= _sum / WINDOW; 	
		}
	}
}