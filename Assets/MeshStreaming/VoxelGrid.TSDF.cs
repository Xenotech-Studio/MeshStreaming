using System.Collections.Generic;
using UnityEngine;

namespace MeshStreaming
{
    // 假定这是一个VoxelGrid类，用于管理TSDF值
    public partial class VoxelGrid
    {
        public static void Capture(List<DepthCamera> cameras, VoxelGrid grid, Vector3 Origin, Vector3 Range)
        {
            for (int i = 0; i < cameras.Count; i++)
            {
                cameras[i].Camera.Render();
                UpdateTSDF(cameras[i], grid, Origin, Range);
            }
        }
        
        public static void UpdateTSDF(DepthCamera camera, VoxelGrid grid, Vector3 Origin, Vector3 Range)
        {
            Matrix4x4 camToWorld = camera.transform.localToWorldMatrix;
            float maxTruncation = 0.1f; // 最大截断距离，具体值根据应用场景调整

            for (int x = 0; x < camera.CameraOutput.width; x++)
            {
                for (int y = 0; y < camera.CameraOutput.height; y++)
                {
                    float depth = camera.GetDepth(new Vector2Int(x, y));
                    float actualDepth = 0.2980392f / depth;
                    //if(depth>0)Debug.Log(depth + " -> " + actualDepth);
                    Vector3 voxelPos = CameraPixelToWorld(camToWorld, camera.Camera, x, y, actualDepth);
                    Vector3Int voxelIndex = WorldToGridIndex(voxelPos, grid, Origin, Range);

                    // 计算截断距离并更新TSDF和权重
                    if (InBounds(voxelIndex, grid))
                    {
                        float sdf = Mathf.Min((voxelPos - camToWorld.MultiplyPoint(camera.transform.position)).magnitude - actualDepth, maxTruncation);
                        float weight = 1.0f; // 这里可以根据距离或其他标准调整权重
                        grid.UpdateVoxel(voxelIndex, sdf, weight);
                    }
                }
            }
        }
    }
}