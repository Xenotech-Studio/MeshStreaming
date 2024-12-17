using UnityEngine;
using System.Collections;
using com.rfilkov.kinect;


namespace com.rfilkov.components
{
    public class DepthSpriteViewerJoints : MonoBehaviour
    {
        [Tooltip("Index of the player, tracked by this component. 0 means the 1st player, 1 - the 2nd one, 2 - the 3rd one, etc.")]
        public int playerIndex = 0;

        [Tooltip("Depth sensor index used for color frame overlay - 0 is the 1st one, 1 - the 2nd one, etc.")]
        public int sensorIndex = 0;

        [Tooltip("Camera used to estimate the overlay positions of 3D-objects over the background. By default it is the main camera.")]
        public Camera foregroundCamera;

        [Tooltip("Depth image renderer.")]
        public SpriteRenderer depthImage;

        [Tooltip("Body joints acting as colliders.")]
        public KinectInterop.JointType[] colliderJoints = new KinectInterop.JointType[] { KinectInterop.JointType.HandLeft, KinectInterop.JointType.HandRight };

        // width of the created box colliders
        private const float colliderWidth = 0.4f;

        // the KinectManager instance
        private KinectManager kinectManager;

        // sensor index used for body tracking
        //private int sensorIndex;
        private KinectInterop.SensorData sensorData = null;

        // texture-2d of the depth texture
        private Texture2D texDepth2D = null;

        // screen rectangle taken by the foreground image (in pixels)
        private Rect foregroundImgRect;

        // game objects to contain the joint colliders
        private GameObject[] jointColliders = null;
        private int numColliders = 0;

        private Matrix4x4 matTransform = Matrix4x4.identity;


        void Start()
        {
            if (foregroundCamera == null)
            {
                // by default use the main camera
                foregroundCamera = Camera.main;
            }

            kinectManager = KinectManager.Instance;
        }

        void Update()
        {
            // setup joint colliders, if needed
            if (jointColliders == null)
            {
                SetupJointColliders();
            }

            // get the users texture
            if (kinectManager && kinectManager.IsInitialized() && depthImage /**&& depthImage.sprite == null*/)
            {
                Texture texDepth = kinectManager.GetUsersImageTex(sensorIndex);

                if (texDepth != null)
                {
                    Rect rectDepth = new Rect(0, 0, texDepth.width, texDepth.height);
                    Vector2 pivotSprite = new Vector2(0.5f, 0.5f);

                    if (texDepth2D == null && texDepth != null && sensorData != null)
                    {
                        texDepth2D = new Texture2D(texDepth.width, texDepth.height, TextureFormat.ARGB32, false);

                        depthImage.sprite = Sprite.Create(texDepth2D, rectDepth, pivotSprite);
                        depthImage.flipX = sensorData.depthImageScale.x < 0;
                        depthImage.flipY = sensorData.depthImageScale.y < 0;
                    }

                    if (texDepth2D != null)
                    {
                        Graphics.CopyTexture(texDepth, texDepth2D);
                    }

                    float worldScreenHeight = foregroundCamera.orthographicSize * 2f;
                    float spriteHeight = depthImage.sprite.bounds.size.y;

                    float scale = worldScreenHeight / spriteHeight;
                    depthImage.transform.localScale = new Vector3(scale, scale, 1f);
                }
            }

            // update joint colliders
            if (kinectManager && kinectManager.IsUserDetected(playerIndex) && foregroundCamera)
            {
                ulong userId = kinectManager.GetUserIdByIndex(playerIndex);  // manager.GetPrimaryUserID();
                matTransform.SetTRS(transform.position, transform.rotation, Vector3.one);

                for (int i = 0; i < numColliders; i++)
                {
                    bool bActive = false;

                    if (kinectManager.IsJointTracked(userId, colliderJoints[i]))
                    {
                        Vector3 posJoint = matTransform.MultiplyPoint3x4(kinectManager.GetJointPosDepthOverlay(userId, colliderJoints[i], sensorIndex, foregroundCamera, foregroundImgRect));
                        posJoint.z = depthImage ? depthImage.transform.position.z : 0f;

                        jointColliders[i].transform.position = posJoint;
                        bActive = true;
                    }

                    if (jointColliders[i].activeSelf != bActive)
                    {
                        // change collider activity
                        jointColliders[i].SetActive(bActive);
                    }
                }
            }

        }


        // sets up the image rectangle and body colliders
        private void SetupJointColliders()
        {
            if (kinectManager && kinectManager.IsInitialized())
            {
                //sensorIndex = kinectManager.GetPrimaryBodySensorIndex();
                sensorData = kinectManager.GetSensorData(sensorIndex);

                if (sensorData != null && foregroundCamera != null)
                {
                    foregroundImgRect = kinectManager.GetForegroundRectDepth(sensorIndex, foregroundCamera);

                    // create joint colliders
                    numColliders = colliderJoints.Length;
                    jointColliders = new GameObject[numColliders];

                    for (int i = 0; i < numColliders; i++)
                    {
                        string sColObjectName = ((KinectInterop.JointType)i).ToString() + "Collider";
                        jointColliders[i] = new GameObject(sColObjectName);
                        jointColliders[i].transform.parent = transform;

                        CircleCollider2D collider = jointColliders[i].AddComponent<CircleCollider2D>();
                        collider.radius = colliderWidth;
                    }
                }
            }
        }

    }
}
