using UnityEngine;
using UnityEditor;

namespace secantastronomy
{
	public class CreateConfiguration
	{
		[MenuItem("Secant Astronomy/Create/Configuration Asset")]
		public static void CreateAsset ()
		{
			Configuration asset = ScriptableObject.CreateInstance<Configuration>();

			ProjectWindowUtil.CreateAsset(asset, "New " + typeof(Configuration).Name + ".asset");
		}
	}
}
