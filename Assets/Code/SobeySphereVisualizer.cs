using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Linq;

// JSON structure for occupational stress data
[System.Serializable]
public class StressData
{
    public string employeeName;
    public string title;
    public List<CategoryValue> categories;
}

[System.Serializable]
public class CategoryValue
{
    public string name;
    public float value; // 0-1 range: 0 = high stress (vivid, deep), 1 = low stress (pastel, surface)
}

public class IndentedSphereRadarChart : MonoBehaviour
{
    [Header("Data Source")]
    [Tooltip("Path to JSON file relative to StreamingAssets folder")]
    public string jsonFileName = "stress_data.json";
    
    [Header("Visual Settings")]
    public Material surfaceMaterial;
    public Material pointMaterial;
    public bool showReferenceGuidelines = true;
    public bool showCategoryLabels = true;
    public int labelFrequency = 3; // Show every Nth label
    
    [Header("Animation")]
    public bool animateOnStart = true;
    public float animationDuration = 2f;
    
    private StressData stressData;
    private GameObject chartRoot;
    private List<Vector3> baseVertices;
    private List<Color> categoryColors;
    private float animationTimer = 0f;
    private bool isAnimating = false;
    
    void Start()
    {
        LoadDataAndCreateChart();
    }
    
    void Update()
    {
        if (isAnimating)
        {
            animationTimer += Time.deltaTime;
            if (animationTimer >= animationDuration)
            {
                isAnimating = false;
                animationTimer = animationDuration;
            }
            UpdateChartAnimation(animationTimer / animationDuration);
        }
    }
    
    public void LoadDataAndCreateChart()
    {
        string filePath = Path.Combine(Application.streamingAssetsPath, jsonFileName);
        
        if (File.Exists(filePath))
        {
            string jsonData = File.ReadAllText(filePath);
            stressData = JsonUtility.FromJson<StressData>(jsonData);
            CreateChart();
        }
        else
        {
            Debug.LogError($"JSON file not found: {filePath}");
            // Create sample data for testing
            CreateSampleData();
            CreateChart();
        }
    }
    
    void CreateSampleData()
    {
        stressData = new StressData
        {
            employeeName = "Sample Employee",
            title = "Occupational Stress Profile",
            categories = new List<CategoryValue>()
        };
        
        string[] categoryNames = new string[]
        {
            // PHYSIOLOGICAL NEEDS
            "Workload", "Work Hours", "Physical Safety", "Ergonomics", "Fatigue",
            "Sleep Quality", "Nutrition Access", "Hydration", "Rest Breaks", "Physical Strain",
            
            // SAFETY & SECURITY
            "Job Security", "Income Stability", "Benefits", "Retirement", "Health Insurance",
            "Workplace Violence", "Harassment", "Discrimination", "Legal Protection", "Contract Clarity",
            
            // LOVE & BELONGING
            "Team Cohesion", "Peer Support", "Manager Support", "Social Isolation", "Work-Life Balance",
            "Family Time", "Friendships", "Community", "Mentorship", "Collaboration",
            
            // ESTEEM
            "Recognition", "Respect", "Autonomy", "Authority", "Competence",
            "Achievement", "Status", "Reputation", "Performance Feedback", "Promotion Opportunity",
            
            // SELF-ACTUALIZATION
            "Purpose", "Meaning", "Creativity", "Innovation", "Learning",
            "Skill Development", "Challenge", "Growth", "Mastery", "Legacy",
            
            // OPERATIONAL STRESSORS
            "Time Pressure", "Deadlines", "Interruptions", "Multitasking", "Technology Issues",
            "Communication", "Role Clarity", "Resources", "Training", "Equipment Quality"
        };
        
        for (int i = 0; i < 60; i++)
        {
            stressData.categories.Add(new CategoryValue
            {
                name = categoryNames[i],
                value = Random.Range(0.3f, 1.0f)
            });
        }
        
        // Add some high stress areas
        stressData.categories[0].value = 0.25f;  // Workload
        stressData.categories[15].value = 0.3f;  // Workplace Violence
        stressData.categories[23].value = 0.35f; // Social Isolation
    }
    
    void CreateChart()
    {
        if (chartRoot != null)
            Destroy(chartRoot);
        
        chartRoot = new GameObject("Sphere Radar Chart");
        chartRoot.transform.position = transform.position;
        
        GenerateBaseVertices();
        GenerateCategoryColors();
        
        if (showReferenceGuidelines)
            CreateReferenceGuidelines();
        
        if (animateOnStart)
        {
            isAnimating = true;
            animationTimer = 0f;
        }
        else
        {
            CreateDeformedSphere();
            CreateDataPoints();
            CreateConnectionLines();
            if (showCategoryLabels)
                CreateLabels();
        }
    }
    
    void GenerateBaseVertices()
    {
        baseVertices = new List<Vector3>();
        float phiGolden = (1.0f + Mathf.Sqrt(5.0f)) / 2.0f;
        
        for (int i = 0; i < 60; i++)
        {
            float y = 1.0f - (i / 59.0f) * 2.0f; // y from 1 to -1
            float radius = Mathf.Sqrt(1.0f - y * y);
            float theta = phiGolden * i * 2.0f * Mathf.PI;
            
            float x = Mathf.Cos(theta) * radius;
            float z = Mathf.Sin(theta) * radius;
            
            baseVertices.Add(new Vector3(x, y, z));
        }
    }
    
    void GenerateCategoryColors()
    {
        categoryColors = new List<Color>();
        float phiConjugate = (Mathf.Sqrt(5.0f) - 1.0f) / 2.0f;
        
        List<float> hues = new List<float>();
        for (int i = 0; i < 60; i++)
        {
            hues.Add((i * phiConjugate) % 1.0f);
        }
        
        // Sort and interleave for maximum contrast
        hues.Sort();
        List<float> reorderedHues = new List<float>(new float[60]);
        int halfCount = hues.Count / 2;
        
        for (int i = 0; i < halfCount; i++)
        {
            reorderedHues[i * 2] = hues[i];
        }
        
        for (int i = halfCount; i < hues.Count; i++)
        {
            reorderedHues[(i - halfCount) * 2 + 1] = hues[i];
        }
        
        foreach (float hue in reorderedHues)
        {
            categoryColors.Add(Color.HSVToRGB(hue, 1.0f, 0.9f));
        }
    }
    
    void CreateReferenceGuidelines()
    {
        GameObject guidelineRoot = new GameObject("Reference Guidelines");
        guidelineRoot.transform.parent = chartRoot.transform;
        
        float[] radii = { 1.0f, 0.75f, 0.55f, 0.35f };
        Color[] colors = { 
            new Color(0.5f, 0.5f, 0.5f, 0.2f), 
            new Color(0.3f, 0.5f, 1.0f, 0.3f),
            new Color(1.0f, 0.6f, 0.2f, 0.3f),
            new Color(1.0f, 0.3f, 0.3f, 0.3f)
        };
        
        foreach (float radius in radii)
        {
            CreateSphereWireframe(guidelineRoot, radius, colors[System.Array.IndexOf(radii, radius)]);
        }
    }
    
    void CreateSphereWireframe(GameObject parent, float radius, Color color)
    {
        GameObject wireframe = new GameObject($"Wireframe_{radius:F2}");
        wireframe.transform.parent = parent.transform;
        
        LineRenderer lr = wireframe.AddComponent<LineRenderer>();
        lr.material = new Material(Shader.Find("Sprites/Default"));
        lr.startColor = color;
        lr.endColor = color;
        lr.startWidth = 0.01f;
        lr.endWidth = 0.01f;
        lr.useWorldSpace = false;
        
        // Create latitude circles
        List<Vector3> points = new List<Vector3>();
        int segments = 32;
        
        for (int lat = 0; lat < 8; lat++)
        {
            float vAngle = (lat / 8.0f) * Mathf.PI;
            float latRadius = Mathf.Sin(vAngle) * radius;
            float y = Mathf.Cos(vAngle) * radius;
            
            for (int i = 0; i <= segments; i++)
            {
                float angle = (i / (float)segments) * 2.0f * Mathf.PI;
                float x = Mathf.Cos(angle) * latRadius;
                float z = Mathf.Sin(angle) * latRadius;
                points.Add(new Vector3(x, y, z));
            }
        }
        
        lr.positionCount = points.Count;
        lr.SetPositions(points.ToArray());
    }
    
    void CreateDeformedSphere()
    {
        GameObject sphereObj = new GameObject("Deformed Sphere");
        sphereObj.transform.parent = chartRoot.transform;
        
        MeshFilter meshFilter = sphereObj.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = sphereObj.AddComponent<MeshRenderer>();
        
        if (surfaceMaterial != null)
            meshRenderer.material = surfaceMaterial;
        else
        {
            meshRenderer.material = new Material(Shader.Find("Standard"));
            meshRenderer.material.color = new Color(0.8f, 0.8f, 0.8f, 0.7f);
        }
        
        Mesh mesh = CreateDeformedSphereMesh();
        meshFilter.mesh = mesh;
    }
    
    Mesh CreateDeformedSphereMesh()
    {
        List<Vector3> vertices = new List<Vector3>();
        List<Color> colors = new List<Color>();
        List<int> triangles = new List<int>();
        
        // Create high-res sphere points
        int resolution = 40;
        for (int lat = 0; lat <= resolution; lat++)
        {
            float v = lat / (float)resolution;
            float theta = v * Mathf.PI;
            
            for (int lon = 0; lon <= resolution; lon++)
            {
                float u = lon / (float)resolution;
                float phi = u * 2.0f * Mathf.PI;
                
                float x = Mathf.Sin(theta) * Mathf.Cos(phi);
                float y = Mathf.Cos(theta);
                float z = Mathf.Sin(theta) * Mathf.Sin(phi);
                
                Vector3 spherePoint = new Vector3(x, y, z);
                
                // Find nearest data points and interpolate
                float indentFactor = GetInterpolatedIndentFactor(spherePoint);
                Vector3 deformedPoint = spherePoint * indentFactor;
                
                vertices.Add(deformedPoint);
                
                // Get interpolated color
                Color vertexColor = GetInterpolatedColor(spherePoint);
                colors.Add(vertexColor);
            }
        }
        
        // Create triangles
        for (int lat = 0; lat < resolution; lat++)
        {
            for (int lon = 0; lon < resolution; lon++)
            {
                int current = lat * (resolution + 1) + lon;
                int next = current + resolution + 1;
                
                triangles.Add(current);
                triangles.Add(next);
                triangles.Add(current + 1);
                
                triangles.Add(current + 1);
                triangles.Add(next);
                triangles.Add(next + 1);
            }
        }
        
        Mesh mesh = new Mesh();
        mesh.vertices = vertices.ToArray();
        mesh.colors = colors.ToArray();
        mesh.triangles = triangles.ToArray();
        mesh.RecalculateNormals();
        
        return mesh;
    }
    
    float GetInterpolatedIndentFactor(Vector3 spherePoint)
    {
        // Find k nearest vertices
        int k = 5;
        var nearestIndices = baseVertices
            .Select((v, i) => new { Index = i, Distance = Vector3.Distance(spherePoint, v) })
            .OrderBy(x => x.Distance)
            .Take(k)
            .ToList();
        
        float totalWeight = 0f;
        float weightedIndent = 0f;
        
        foreach (var item in nearestIndices)
        {
            float weight = 1.0f / (item.Distance + 0.1f);
            float dataValue = stressData.categories[item.Index].value;
            float indentFactor = 0.3f + (dataValue * 0.7f); // Map 0->0.3, 1->1.0
            
            weightedIndent += indentFactor * weight;
            totalWeight += weight;
        }
        
        return weightedIndent / totalWeight;
    }
    
    Color GetInterpolatedColor(Vector3 spherePoint)
    {
        int k = 5;
        var nearestIndices = baseVertices
            .Select((v, i) => new { Index = i, Distance = Vector3.Distance(spherePoint, v) })
            .OrderBy(x => x.Distance)
            .Take(k)
            .ToList();
        
        float totalWeight = 0f;
        Color weightedColor = Color.black;
        float weightedDataValue = 0f;
        
        foreach (var item in nearestIndices)
        {
            float weight = 1.0f / (item.Distance + 0.1f);
            float dataValue = stressData.categories[item.Index].value;
            
            weightedColor += categoryColors[item.Index] * weight;
            weightedDataValue += dataValue * weight;
            totalWeight += weight;
        }
        
        weightedColor /= totalWeight;
        weightedDataValue /= totalWeight;
        
        // Apply saturation based on stress level
        float h, s, v;
        Color.RGBToHSV(weightedColor, out h, out s, out v);
        s = 1.0f - (weightedDataValue * 0.7f); // Low stress = pastel, high stress = vivid
        
        return Color.HSVToRGB(h, s, 0.8f);
    }
    
    void CreateDataPoints()
    {
        GameObject pointsRoot = new GameObject("Data Points");
        pointsRoot.transform.parent = chartRoot.transform;
        
        for (int i = 0; i < 60; i++)
        {
            float dataValue = stressData.categories[i].value;
            float indentFactor = 0.3f + (dataValue * 0.7f);
            Vector3 position = baseVertices[i] * indentFactor;
            
            GameObject point = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            point.name = $"Point_{stressData.categories[i].name}";
            point.transform.parent = pointsRoot.transform;
            point.transform.localPosition = position;
            point.transform.localScale = Vector3.one * 0.03f;
            
            // Apply color with saturation based on stress
            Color baseColor = categoryColors[i];
            float h, s, v;
            Color.RGBToHSV(baseColor, out h, out s, out v);
            s = 1.0f - (dataValue * 0.7f);
            Color finalColor = Color.HSVToRGB(h, s, 0.85f);
            
            Renderer renderer = point.GetComponent<Renderer>();
            renderer.material = new Material(Shader.Find("Standard"));
            renderer.material.color = finalColor;
        }
    }
    
    void CreateConnectionLines()
    {
        GameObject linesRoot = new GameObject("Connection Lines");
        linesRoot.transform.parent = chartRoot.transform;
        
        for (int i = 0; i < 60; i += labelFrequency)
        {
            GameObject lineObj = new GameObject($"Line_{i}");
            lineObj.transform.parent = linesRoot.transform;
            
            LineRenderer lr = lineObj.AddComponent<LineRenderer>();
            lr.material = new Material(Shader.Find("Sprites/Default"));
            
            float dataValue = stressData.categories[i].value;
            float indentFactor = 0.3f + (dataValue * 0.7f);
            
            Color baseColor = categoryColors[i];
            float h, s, v;
            Color.RGBToHSV(baseColor, out h, out s, out v);
            s = 1.0f - (dataValue * 0.7f);
            Color lineColor = Color.HSVToRGB(h, s, 0.9f);
            lineColor.a = 0.6f;
            
            lr.startColor = lineColor;
            lr.endColor = lineColor;
            lr.startWidth = 0.015f;
            lr.endWidth = 0.015f;
            lr.useWorldSpace = false;
            
            lr.positionCount = 2;
            lr.SetPosition(0, baseVertices[i]);
            lr.SetPosition(1, baseVertices[i] * indentFactor);
        }
    }
    
    void CreateLabels()
    {
        GameObject labelsRoot = new GameObject("Labels");
        labelsRoot.transform.parent = chartRoot.transform;
        
        for (int i = 0; i < 60; i += labelFrequency)
        {
            Vector3 labelPosition = baseVertices[i] * 1.25f;
            
            GameObject labelObj = new GameObject($"Label_{stressData.categories[i].name}");
            labelObj.transform.parent = labelsRoot.transform;
            labelObj.transform.localPosition = labelPosition;
            labelObj.transform.LookAt(Camera.main.transform);
            
            TextMesh textMesh = labelObj.AddComponent<TextMesh>();
            textMesh.text = stressData.categories[i].name;
            textMesh.characterSize = 0.05f;
            textMesh.anchor = TextAnchor.MiddleCenter;
            textMesh.alignment = TextAlignment.Center;
            textMesh.fontSize = 32;
            
            float dataValue = stressData.categories[i].value;
            Color baseColor = categoryColors[i];
            float h, s, v;
            Color.RGBToHSV(baseColor, out h, out s, out v);
            s = 1.0f - (dataValue * 0.7f);
            textMesh.color = Color.HSVToRGB(h, s, 0.9f);
        }
    }
    
    void UpdateChartAnimation(float t)
    {
        t = Mathf.SmoothStep(0f, 1f, t);
        // Animation logic can be expanded here
    }
}

// Example JSON format to save as stress_data.json in StreamingAssets folder:
/*
{
    "employeeName": "John Doe",
    "title": "Occupational Stress Profile - Software Engineer",
    "categories": [
        {"name": "Workload", "value": 0.25},
        {"name": "Work Hours", "value": 0.65},
        {"name": "Physical Safety", "value": 0.85},
        ... (57 more categories)
    ]
}
*/