using UnityEngine;
using UnityEditor;

namespace secantastronomy
{
	public class CreateCommands
	{
		[MenuItem("Secant Astronomy/Create/Commands Asset")]
		public static void CreateAsset ()
		{
			Commands asset = ScriptableObject.CreateInstance<Commands>();

			ProjectWindowUtil.CreateAsset(asset, "New " + typeof(Commands).Name + ".asset");
		}
	}
}
