using UnityEngine;

namespace MeshStreaming
{
    // 假定这是一个VoxelGrid类，用于管理TSDF值
    public partial class VoxelGrid
    {
        public Vector3Int Resolution;
        public float[,,] TSDF;
        public float[,,] Weights;

        public VoxelGrid(Vector3Int resolution)
        {
            Resolution = resolution;
            TSDF = new float[resolution.x, resolution.y, resolution.z];
            Weights = new float[resolution.x, resolution.y, resolution.z];

            // 初始化TSDF网格
            InitializeGrid();
        }

        void InitializeGrid()
        {
            for (int x = 0; x < Resolution.x; x++)
            {
                for (int y = 0; y < Resolution.y; y++)
                {
                    for (int z = 0; z < Resolution.z; z++)
                    {
                        TSDF[x, y, z] = 1.0f; // 初始化为最大截断距离
                        Weights[x, y, z] = 0f; // 初始化权重
                    }
                }
            }
        }
        
        void UpdateVoxel(Vector3Int index, float sdf, float weight)
        {
            float oldTSDF = TSDF[index.x, index.y, index.z];
            float oldWeight = Weights[index.x, index.y, index.z];

            // 更新公式
            float newTSDF = (oldTSDF * oldWeight + sdf * weight) / (oldWeight + weight);
            float newWeight = oldWeight + weight;

            // 将更新后的值写回网格
            TSDF[index.x, index.y, index.z] = newTSDF;
            Weights[index.x, index.y, index.z] = newWeight;
        }
        
        public float GetTSDF(Vector3Int index)
        {
            return TSDF[index.x, index.y, index.z];
        }
        
        public float GetWeight(Vector3Int index)
        {
            return Weights[index.x, index.y, index.z];
        }
    }
}