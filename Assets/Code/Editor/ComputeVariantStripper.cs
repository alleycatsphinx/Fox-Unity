// Assets/Code/Editor/ComputeVariantStripper.cs
// Strips compute-shader variants at build time. Keeps only the "no-keyword"
// variant unless you whitelist keywords/kernels below.

using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Build;
using UnityEngine;

// ShaderCompilerData is Editor-side
using UnityEditor.Rendering;

// ShaderKeyword / ShaderKeywordSet are Engine-side in newer Unity;
// in older versions they also lived in UnityEditor.Rendering.
// We alias and fall back if needed.
#if UNITY_2021_2_OR_NEWER || UNITY_6000_0_OR_NEWER
using UR = UnityEngine.Rendering;
#else
using UR = UnityEditor.Rendering;
#endif

public sealed class ComputeVariantStripper : IPreprocessComputeShaders
{
    // Optional: only process these kernels; leave empty to process all.
    private static readonly HashSet<string> KernelNameWhitelist = new()
    {
        // "CSMain", "Integrate", "PrefixSum"
    };

    // Whitelist GLOBAL keywords to keep (strings exactly as in HLSL pragmas)
    private static readonly string[] GlobalKeywordWhitelist = {
        // "ASYNC_COMPUTE", "USE_HALF"
    };

    // Whitelist LOCAL (per-compute) keywords to keep
    private static readonly string[] LocalKeywordWhitelist = {
        // "MODE_A", "MODE_B"
    };

    public int callbackOrder => 0;

    // NOTE: The interface expects IList<ShaderCompilerData> from UnityEditor.Rendering.
    public void OnProcessComputeShader(ComputeShader shader, string kernelName, IList<ShaderCompilerData> data)
    {
        // If you only care about certain kernels, strip others entirely.
        if (KernelNameWhitelist.Count > 0 && !KernelNameWhitelist.Contains(kernelName))
        {
            data.Clear();
            return;
        }

        var globalWL = BuildGlobalWhitelist(GlobalKeywordWhitelist);
        var localWL  = BuildLocalWhitelist(shader, LocalKeywordWhitelist);

        bool keepOnlyNoKeywords = globalWL.Count == 0 && localWL.Count == 0;

        for (int i = data.Count - 1; i >= 0; i--)
        {
            // shaderKeywordSet type is UR.ShaderKeywordSet in both branches above
            UR.ShaderKeywordSet set = data[i].shaderKeywordSet;
            var enabled = set.GetShaderKeywords(); // UR.ShaderKeyword[]

            if (keepOnlyNoKeywords)
            {
                if (enabled.Length > 0) data.RemoveAt(i);
                continue;
            }

            bool disallowed = false;
            for (int k = 0; k < enabled.Length; k++)
            {
                var kw = enabled[k];
                if (!globalWL.Contains(kw) && !localWL.Contains(kw))
                {
                    disallowed = true; break;
                }
            }
            if (disallowed) data.RemoveAt(i);
        }
    }

    static HashSet<UR.ShaderKeyword> BuildGlobalWhitelist(string[] names)
    {
        var set = new HashSet<UR.ShaderKeyword>();
        foreach (var n in names)
            if (!string.IsNullOrEmpty(n))
                set.Add(new UR.ShaderKeyword(n));                 // global keyword
        return set;
    }

    static HashSet<UR.ShaderKeyword> BuildLocalWhitelist(ComputeShader shader, string[] names)
    {
        var set = new HashSet<UR.ShaderKeyword>();
        foreach (var n in names)
            if (!string.IsNullOrEmpty(n))
                set.Add(new UR.ShaderKeyword(shader, n));         // local (per-compute) keyword
        return set;
    }
}