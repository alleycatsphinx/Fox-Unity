using System.Collections.Generic;          // for IList<T>
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Rendering;              // for IPreprocessShaders, ShaderCompilerData
using UnityEngine;

public class ShaderVariantStripper : IPreprocessShaders
{
    public int callbackOrder => 0;

    public void OnProcessShader(
        Shader shader,
        ShaderSnippetData snippet,
        IList<ShaderCompilerData> data)
    {
        // Keep only the bare minimum
        for (int i = data.Count - 1; i >= 0; i--)
        {
            var keywords = data[i].shaderKeywordSet.GetShaderKeywords();

            // Example: remove *all* keywords except a specific one
            if (keywords.Length > 0)
            {
                data.RemoveAt(i);
            }
        }
    }
}