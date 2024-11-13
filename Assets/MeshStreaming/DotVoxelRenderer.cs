using System;
using System.Collections.Generic;
using MeshScreaming;
using UnityEngine;

namespace MeshStreaming
{
    public class DotVoxelRenderer : MonoBehaviour
    {
        public CameraDepthsToVoxel CameraDepthsToVoxel;
        public Dictionary<Vector3Int, GameObject> VoxelObjects = new Dictionary<Vector3Int, GameObject>();

        public void Update()
        {
            // for each voxel in the voxel grid, set the sphere to active if the voxel is larger than 0.3
            Vector3 Resolution = CameraDepthsToVoxel.Resolution;
            for (int x = 0; x < Resolution.x; x++)
            {
                if (x%4 != 0) continue;
                for (int y = 0; y < Resolution.y; y++)
                {
                    if (y%4 != 0) continue;
                    for (int z = 0; z < Resolution.z; z++)
                    {
                        if (z%4!=0) continue;
                        var position = new Vector3Int(x, y, z);
                        var sphere = GetSphereAt(position);
                        var voxel = CameraDepthsToVoxel.VoxelGrid.GetTSDF(position);
                        sphere.name = voxel.ToString();
                        sphere.SetActive(voxel > 0.9f);
                    }
                }
            }
        }
        
        public GameObject GetSphereAt(Vector3Int position)
        {
            if (VoxelObjects.TryGetValue(position, out var voxelObject))
            {
                return voxelObject;
            }
            else
            {
                var sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                sphere.transform.localScale = Vector3.one * 0.1f;
                sphere.transform.position = new Vector3(
                    position.x * 0.1f /4,
                    position.y * 0.1f /4,
                    position.z * 0.1f /4
                );
                VoxelObjects[position] = sphere;
                return sphere;
            }
        }
        
        public void Clear()
        {
            foreach (var voxelObject in VoxelObjects.Values)
            {
                DestroyImmediate(voxelObject);
            }
            VoxelObjects.Clear();
        }
    }
    
    #if UNITY_EDITOR
    [UnityEditor.CustomEditor(typeof(DotVoxelRenderer))]
    public class DotVoxelRendererEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            var script = (DotVoxelRenderer) target;
            if (GUILayout.Button("Update"))
            {
                script.Update();
            }

            if (GUILayout.Button("Clear"))
            {
                script.Clear();
            }
        }
    }
    #endif
}