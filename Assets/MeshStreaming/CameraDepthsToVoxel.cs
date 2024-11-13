using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

namespace MeshStreaming
{
    //[ExecuteInEditMode]
    public class CameraDepthsToVoxel : MonoBehaviour
    {
        public List<DepthCamera> Cameras;
        public Vector3Int Resolution = new Vector3Int(64, 64, 64);
        public Transform CaptureOrigin;
        public Vector3 CaptureRange;
        
        [DoNotSerialize]
        public VoxelGrid VoxelGrid;
        
        public void Update()
        {
            if (VoxelGrid == null) VoxelGrid = new VoxelGrid(Resolution);
            VoxelGrid.Capture(Cameras, VoxelGrid, CaptureOrigin.position, CaptureRange);
        }
    }
    
    #if UNITY_EDITOR
    [UnityEditor.CustomEditor(typeof(CameraDepthsToVoxel))]
    public class CameraDepthsToVoxelEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            var script = (CameraDepthsToVoxel) target;
            if (GUILayout.Button("Capture"))
            {
                script.Update();
                foreach (var camera in script.Cameras)
                {
                    camera.LateUpdate();
                }
            }
        }
    }
    #endif
}