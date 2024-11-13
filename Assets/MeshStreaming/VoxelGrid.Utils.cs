using UnityEngine;

namespace MeshStreaming
{
    // 假定这是一个VoxelGrid类，用于管理TSDF值
    public partial class VoxelGrid
    {
        static Vector3 CameraPixelToWorld(Matrix4x4 camToWorld, Camera camera, int x, int y, float depth)
        {
            // 将像素坐标转换为归一化的设备坐标
            Vector3 ndc = new Vector3((x / (float)camera.pixelWidth) * 2 - 1, (y / (float)camera.pixelHeight) * 2 - 1, depth);
            ndc.y = -ndc.y; // Unity中的y坐标是向上的，归一化设备坐标中y应向下

            // 将NDC坐标转换为世界坐标
            Vector4 clipSpace = new Vector4(ndc.x, ndc.y, depth, 1.0f);
            Vector4 worldSpace = camToWorld * clipSpace;

            // 除以w坐标进行透视除法
            return worldSpace / worldSpace.w;
        }
        
        static Vector3Int WorldToGridIndex(Vector3 worldPos, VoxelGrid grid, Vector3 Origin, Vector3 GridSize)
        {
            float relativeX = (worldPos.x - Origin.x) / GridSize.x;
            float relativeY = (worldPos.y - Origin.y) / GridSize.y;
            float relativeZ = (worldPos.z - Origin.z) / GridSize.z;

            // 将计算出的比例值转换为体素网格的索引
            return new Vector3Int(
                Mathf.FloorToInt(relativeX * grid.Resolution.x),
                Mathf.FloorToInt(relativeY * grid.Resolution.y),
                Mathf.FloorToInt(relativeZ * grid.Resolution.z)
            );
        }
        
        static bool InBounds(Vector3Int index, VoxelGrid grid)
        {
            return index.x >= 0 && index.x < grid.Resolution.x &&
                   index.y >= 0 && index.y < grid.Resolution.y &&
                   index.z >= 0 && index.z < grid.Resolution.z;
        }
    }
}