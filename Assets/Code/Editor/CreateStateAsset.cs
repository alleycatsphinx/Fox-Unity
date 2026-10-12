using UnityEngine;
using UnityEditor;

namespace secantastronomy
{
    public class CreateState
    {
        [MenuItem("Secant Astronomy/Create/State Asset")]
        public static void CreateAsset ()
        {
            State asset = ScriptableObject.CreateInstance<State>();

            ProjectWindowUtil.CreateAsset(asset, "New " + typeof(State).Name + ".asset");
        }
    }
}
