using System.Collections.Generic;
using UnityEngine;

namespace MeshScreaming
{
    public class VoxelObject
    {
        public VoxelObject(Vector3 resolution)
        {
            Resolution = resolution;
        }
        
        private List<List<List<bool>>> Voxels;
    
        public Vector3 Resolution
        {
            set
            {
                Voxels = new List<List<List<bool>>>();
                for (int x = 0; x < value.x; x++)
                {
                    Voxels.Add(new List<List<bool>>());
                    for (int y = 0; y < value.y; y++)
                    {
                        Voxels[x].Add(new List<bool>());
                        for (int z = 0; z < value.z; z++)
                        {
                            Voxels[x][y].Add(false);
                        }
                    }
                }
            }
            get => new Vector3(Voxels.Count, Voxels[0].Count, Voxels[0][0].Count);
        }
        
        public void SetVoxel(Vector3Int position, bool value)
        {
            Voxels[position.x][position.y][position.z] = value;
        }
    
        public bool GetVoxel(Vector3Int position)
        {
            return Voxels[position.x][position.y][position.z];
        }
    }
}