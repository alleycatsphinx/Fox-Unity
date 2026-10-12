using UnityEngine;

//swipe handler 
public static class Swipe
{
	public static float minSwipeLength = 5f;
	private static Vector2 firstPressPos;
	private static Vector2 secondPressPos;
	private static Vector2 currentSwipe;
	
	public static Vector2 firstClickPos;
	public static Vector2 secondClickPos;
	
	public enum SwipeEnum { None, Up, Down, Left, Right };
	public static SwipeEnum swipeDirection;

	public static void Update ()
	{
		if (Input.touches.Length > 0) 
		{
			Touch t = Input.GetTouch(0);
			
			if (t.phase == TouchPhase.Began) 
			{
				firstPressPos = new Vector2(t.position.x, t.position.y);
			}
						
			if (t.phase == TouchPhase.Ended) 
			{
				secondPressPos 	= new Vector2(t.position.x, t.position.y);
				currentSwipe 	= new Vector3(secondPressPos.x - firstPressPos.x, secondPressPos.y - firstPressPos.y);
				
				// Make sure it was a legit swipe, not a tap
				if (currentSwipe.magnitude < minSwipeLength) 
				{
					swipeDirection = SwipeEnum.None;
					return;
				}
				
				currentSwipe.Normalize();
				
				// Swipe up
				if (currentSwipe.y > 0 && currentSwipe.x > -0.5f && currentSwipe.x < 0.5f) {
					swipeDirection = SwipeEnum.Up;
					Debug.Log("up");
				} 
				else if (currentSwipe.y < 0 && currentSwipe.x > -0.5f && currentSwipe.x < 0.5f) {
					swipeDirection = SwipeEnum.Down;
					Debug.Log("down");
				} 
				else if (currentSwipe.x < 0 && currentSwipe.y > -0.5f && currentSwipe.y < 0.5f) {
					swipeDirection = SwipeEnum.Left;
					Debug.Log("left");
				} 
				else if (currentSwipe.x > 0 && currentSwipe.y > -0.5f && currentSwipe.y < 0.5f) {
					swipeDirection = SwipeEnum.Right;
					Debug.Log("right");
				}
			}
		} 
		else 
		{
			if (Input.GetMouseButtonDown(1)) 
			{
				firstClickPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
			} 
			else 
			{
				swipeDirection = SwipeEnum.None;
				//Debug.Log ("None");
			}
			if (Input.GetMouseButtonUp (1))
			{
				secondClickPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
				currentSwipe = new Vector3(secondClickPos.x - firstClickPos.x, secondClickPos.y - firstClickPos.y);
	
				// Make sure it was a legit swipe, not a tap
				if (currentSwipe.magnitude < minSwipeLength) 
				{
					swipeDirection = SwipeEnum.None;
					return;
				}
				
				currentSwipe.Normalize();
	
				if (currentSwipe.y > 0 && currentSwipe.x > -0.5f && currentSwipe.x < 0.5f) {
					swipeDirection = SwipeEnum.Up;
					Debug.Log ("up");
				} else if (currentSwipe.y < 0 && currentSwipe.x > -0.5f && currentSwipe.x < 0.5f) {
					swipeDirection = SwipeEnum.Down;
					Debug.Log ("down");
				} else if (currentSwipe.x < 0 && currentSwipe.y > -0.5f && currentSwipe.y < 0.5f) {
					swipeDirection = SwipeEnum.Left;
					Debug.Log ("left");
				} else if (currentSwipe.x > 0 && currentSwipe.y > -0.5f && currentSwipe.y < 0.5f) {
					swipeDirection = SwipeEnum.Right;
					Debug.Log("right");
				}
			}
	
		}
	}
}
