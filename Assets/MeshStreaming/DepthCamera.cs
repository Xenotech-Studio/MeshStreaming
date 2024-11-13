using System;
using UnityEngine;

namespace MeshStreaming
{
    [RequireComponent(typeof(Camera))]
    public class DepthCamera : MonoBehaviour
    {
        private Camera _camera;
        public Camera Camera
        {
            get
            {
                if (_camera == null)
                {
                    _camera = GetComponent<Camera>();
                }
                return _camera;
            }
        }

        private Texture2D depthTexture;
        private bool depthTextureCaptured = false;

        public RenderTexture CameraOutput => Camera.targetTexture;
        
        public bool InBound(Vector2Int pixel)
        {
            return pixel.x >= 0 && pixel.x < Camera.pixelWidth &&
                   pixel.y >= 0 && pixel.y < Camera.pixelHeight;
        }
        
        public float GetDepth(Vector2Int pixel)
        {
            if (!InBound(pixel))
            {
                return 1000000f;
            }

            if (!depthTextureCaptured)
            {
                depthTexture = new Texture2D(CameraOutput.width, CameraOutput.height, TextureFormat.RFloat, false);
                RenderTexture.active = CameraOutput;
                depthTexture.ReadPixels(new Rect(0, 0, CameraOutput.width, CameraOutput.height), 0, 0);
                depthTexture.Apply();
                depthTextureCaptured = true;
            }

            return depthTexture.GetPixel(pixel.x, pixel.y).r;
        }

        public void LateUpdate()
        {
            depthTextureCaptured = false;
        }
    }
}