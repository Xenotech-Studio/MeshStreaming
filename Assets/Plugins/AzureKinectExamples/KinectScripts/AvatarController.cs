using UnityEngine;
//using Windows.Kinect;

using System;
using System.Collections;
using System.Collections.Generic;
using com.rfilkov.kinect;


namespace com.rfilkov.components
{
    /// <summary>
    /// Avatar controller is the component that transfers the captured user motion to a humanoid model (avatar).
    /// </summary>
    [RequireComponent(typeof(Animator))]
    public class AvatarController : MonoBehaviour
    {
        [Tooltip("Index of the player, tracked by this component. 0 means the 1st player, 1 - the 2nd one, 2 - the 3rd one, etc.")]
        public int playerIndex = 0;

        [Tooltip("Whether the avatar is facing the player or not.")]
        public bool mirroredMovement = false;

        [Tooltip("Whether the avatar is allowed to move vertically or not.")]
        public bool verticalMovement = true;

        [Tooltip("Whether the avatar is allowed to move horizontally or not.")]
        public bool horizontalMovement = true;

        [Tooltip("Whether the avatar's root motion is applied by other component or script.")]
        public bool externalRootMotion = false;

        [Tooltip("Whether the head rotation is controlled externally (e.g. by VR-headset).")]
        public bool externalHeadRotation = false;

        [Tooltip("Whether the hand and finger rotations are controlled externally (e.g. by LeapMotion controller)")]
        public bool externalHandRotations = false;

        [Tooltip("Whether the finger orientations are allowed or not.")]
        public bool fingerOrientations = false;

        [Tooltip("Rate at which the avatar will move through the scene.")]
        public float moveRate = 1f;

        [Tooltip("Smooth factor used for avatar movements and joint rotations.")]
        public float smoothFactor = 10f;

        [Tooltip("Whether to update the avatar in LateUpdate(), instead of in Update(). Needed for Mecanim animation blending.")]
        public bool lateUpdateAvatar = false;

        [Tooltip("Game object this transform is relative to (optional).")]
        public Transform offsetNode;

        [Tooltip("If enabled, makes the avatar position relative to this camera to be the same as the player's position to the sensor.")]
        public Camera posRelativeToCamera;

        public List<Camera> Cameras;
        [Tooltip("Whether the avatar's position should match the color image (in Pos-rel-to-camera mode only).")]
        public bool posRelOverlayColor = false;

        //[Tooltip("Plane used to render the color camera background to overlay.")]
        //public Transform backgroundPlane;

        [Tooltip("Whether z-axis movement needs to be inverted (Pos-Relative mode only).")]
        [HideInInspector]
        public bool posRelInvertedZ = false;

        [Tooltip("Whether the avatar's feet must stick to the ground.")]
        public bool groundedFeet = false;

        [Tooltip("Whether to apply the humanoid model's muscle limits or not.")]
        public bool applyMuscleLimits = false;

        [Tooltip("Whether to flip left and right, relative to the sensor.")]
        private bool flipLeftRight = false;

        [Tooltip("Whether to keep the avatar's last position and rotation, when the user gets lost.")]
        public bool keepLastPose = false;


        [Tooltip("Horizontal offset of the avatar with respect to the position of user's spine-base.")]
        [Range(-0.5f, 0.5f)]
        public float horizontalOffset = 0f;

        [Tooltip("Vertical offset of the avatar with respect to the position of user's spine-base.")]
        [Range(-0.5f, 0.5f)]
        public float verticalOffset = 0f;

        [Tooltip("Forward offset of the avatar with respect to the position of user's spine-base.")]
        [Range(-0.5f, 0.5f)]
        public float forwardOffset = 0f;

        // suggested and implemented by Ruben Gonzalez
        [Tooltip("Whether to use unscaled or normal (scaled) time.")]
        public bool useUnscaledTime = false;

        [Tooltip("Radius of the joint sphere and bone capsule colliders, in meters. You can set it to 0.02 to try it out. 0 means no collider.")]
        [Range(0f, 0.1f)]
        public float boneColliderRadius = 0f;  // 0.02f;

        // userId of the player
        [NonSerialized]
        public ulong playerId = 0;


        // The body root node
        protected Transform bodyRoot;
        protected float hipCenterDist = 0f;

        // Variable to hold all them bones. It will initialize the same size as initialRotations.
        protected Transform[] bones;
        //protected Transform[] fingerBones;

        protected CapsuleCollider[] boneColliders;
        protected Transform[] boneColTrans;
        protected Transform[] boneColJoint;
        protected Transform[] boneColParent;

        // Rotations of the bones when the Kinect tracking starts.
        protected Quaternion[] initialRotations;
        protected Quaternion[] localRotations;
        protected bool[] isBoneDisabled;

        // Local rotations of finger bones
        protected Dictionary<HumanBodyBones, Quaternion> fingerBoneLocalRotations = new Dictionary<HumanBodyBones, Quaternion>();
        protected Dictionary<HumanBodyBones, Vector3> fingerBoneLocalAxes = new Dictionary<HumanBodyBones, Vector3>();

        // Initial position and rotation of the transform
        protected Vector3 initialPosition;
        protected Quaternion initialRotation;
        protected Vector3 initialHipsPosition;
        protected Quaternion initialHipsRotation;
        protected Vector3 initialUpVector;

        //protected Vector3 offsetNodePos;
        //protected Quaternion offsetNodeRot;
        protected Vector3 bodyRootPosition;
        protected Vector3 bodyRootOffsetPos;

        // Calibration Offset Variables for Character Position.
        [NonSerialized]
        public bool offsetCalibrated = false;
        protected Vector3 offsetPos = Vector3.zero;
        //protected float xOffset, yOffset, zOffset;
        //private Quaternion originalRotation;
        //protected Vector3 offsetCamPos = Vector3.zero;
        //protected Quaternion offsetCamRot = Quaternion.identity;

        //// whether the user pose has been applied on the avatar or not
        //protected bool poseApplied = false;
        //protected Quaternion pelvisRotation = Quaternion.identity;

        // sharp rotation angle
        protected const float SHARP_ROT_ANGLE = 90f;  // 90 degrees

        protected Animator animatorComponent = null;
        private HumanPoseHandler humanPoseHandler = null;
        private HumanPose humanPose = new HumanPose();

        // whether the parent transform obeys physics
        protected bool isRigidBody = false;

        // private instance of the KinectManager
        protected KinectManager kinectManager;
        
        //// last hand events
        //private InteractionManager.HandEventType lastLeftHandEvent = InteractionManager.HandEventType.Release;
        //private InteractionManager.HandEventType lastRightHandEvent = InteractionManager.HandEventType.Release;

        //// fist states
        //private bool bLeftFistDone = false;
        //private bool bRightFistDone = false;

        // grounder constants and variables
        //protected const int raycastLayers = ~2;  // Ignore Raycast
        protected const float MaxFootDistanceGround = 0.02f;  // maximum distance from lower foot to the ground
        protected const float MaxFootDistanceTime = 0.2f; // 1.0f;  // maximum allowed time, the lower foot to be distant from the ground
        protected Transform leftFoot, rightFoot;
        protected Vector3 leftFootPos, rightFootPos;

        //protected float fFootDistanceInitial = 0f;
        protected float fFootDistance = 0f;
        protected float fFootDistanceTime = 0f;
        protected Vector3 vFootCorrection = Vector3.zero;

        //// background plane rectangle
        //private Rect planeRect = new Rect();
        //private bool planeRectSet = false;

        // last time when the avatar was updated
        protected float lastUpdateTime = 0f;
        protected const float MaxUpdateTime = 0.5f;  // allow 0.5 seconds max for smooth updates


        /// <summary>
        /// Gets the number of bone transforms (array length).
        /// </summary>
        /// <returns>The number of bone transforms.</returns>
        public int GetBoneTransformCount()
        {
            return bones != null ? bones.Length : 0;
        }

        /// <summary>
        /// Gets the bone transform by index.
        /// </summary>
        /// <returns>The bone transform.</returns>
        /// <param name="index">Index</param>
        public Transform GetBoneTransform(int index)
        {
            if (index >= 0 && bones != null && index < bones.Length)
            {
                return bones[index];
            }

            return null;
        }

        /// <summary>
        /// Disables the bone and optionally resets its orientation.
        /// </summary>
        /// <param name="index">Bone index.</param>
        /// <param name="resetBone">If set to <c>true</c> resets bone orientation.</param>
        public void DisableBone(int index, bool resetBone)
        {
            if (index >= 0 && index < bones.Length)
            {
                isBoneDisabled[index] = true;

                if (resetBone && bones[index] != null)
                {
                    bones[index].rotation = localRotations[index];
                }
            }
        }

        /// <summary>
        /// Enables the bone, so AvatarController could update its orientation.
        /// </summary>
        /// <param name="index">Bone index.</param>
        public void EnableBone(int index)
        {
            if (index >= 0 && index < bones.Length)
            {
                isBoneDisabled[index] = false;
            }
        }

        /// <summary>
        /// Determines whether the bone orientation update is enabled or not.
        /// </summary>
        /// <returns><c>true</c> if the bone update is enabled; otherwise, <c>false</c>.</returns>
        /// <param name="index">Bone index.</param>
        public bool IsBoneEnabled(int index)
        {
            if (index >= 0 && index < bones.Length)
            {
                return !isBoneDisabled[index];
            }

            return false;
        }

        /// <summary>
        /// Gets the bone index by joint type.
        /// </summary>
        /// <returns>The bone index.</returns>
        /// <param name="joint">Joint type</param>
        /// <param name="bMirrored">If set to <c>true</c> gets the mirrored joint index.</param>
        public int GetBoneIndexByJoint(KinectInterop.JointType joint, bool bMirrored)
        {
            int boneIndex = -1;

            if (jointMap2boneIndex.ContainsKey(joint))
            {
                boneIndex = !bMirrored ? jointMap2boneIndex[joint] : mirrorJointMap2boneIndex[joint];
            }

            return boneIndex;
        }

        /// <summary>
        /// Gets the list of AC-controlled mecanim bones.
        /// </summary>
        /// <returns>List of AC-controlled mecanim bones</returns>
        public List<HumanBodyBones> GetMecanimBones()
        {
            List<HumanBodyBones> alMecanimBones = new List<HumanBodyBones>();

            for (int boneIndex = 0; boneIndex < bones.Length; boneIndex++)
            {
                if (!boneIndex2MecanimMap.ContainsKey(boneIndex) || boneIndex >= 21)
                    continue;

                alMecanimBones.Add(boneIndex2MecanimMap[boneIndex]);
            }

            return alMecanimBones;
        }

        public void SwitchToCamera2()
        {
            posRelativeToCamera = Cameras[0];
        }
        
        public void SwitchToCamera3()
        {
            posRelativeToCamera = Cameras[1];
        }

        // transform caching gives performance boost since Unity calls GetComponent<Transform>() each time you call transform 
        private Transform _transformCache;
        public new Transform transform
        {
            get
            {
                if (!_transformCache)
                {
                    _transformCache = base.transform;
                }

                return _transformCache;
            }
        }


        public virtual void Awake()
        {
            // check for double start
            if (bones != null)
                return;
            if (!gameObject.activeInHierarchy)
                return;

            // inits the bones array
            bones = new Transform[25];

            // get the animator reference
            animatorComponent = GetComponent<Animator>();

            // Map bones to the points the Kinect tracks
            MapBones();

            // get distance to hip center
            Vector3 bodyRootPos = bodyRoot != null ? bodyRoot.position : transform.position;
            Vector3 hipCenterPos = bodyRoot != null ? bodyRoot.position : (bones != null && bones.Length > 0 && bones[0] != null ? bones[0].position : transform.position);
            hipCenterDist = (hipCenterPos - bodyRootPos).magnitude;

            // Set model's arms to be in T-pose, if needed
            SetModelArmsInTpose();

            // Initial rotations and directions of the bones.
            initialRotations = new Quaternion[bones.Length];
            localRotations = new Quaternion[bones.Length];
            isBoneDisabled = new bool[bones.Length];

            // Get initial bone rotations
            GetInitialRotations();

            // enable all bones
            for (int i = 0; i < bones.Length; i++)
            {
                isBoneDisabled[i] = false;
            }

            // get initial distance to ground
            //fFootDistanceInitial = GetCorrDistanceToGround();
            fFootDistance = 0f;
            fFootDistanceTime = 0f;

            // get left & right foot positions
            leftFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.FootLeft, false));
            rightFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.FootRight, false));

            if (leftFoot == null || rightFoot == null)
            {
                leftFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.AnkleLeft, false));
                rightFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.AnkleRight, false));
            }

            leftFootPos = leftFoot != null ? leftFoot.position : Vector3.zero;
            rightFootPos = rightFoot != null ? rightFoot.position : Vector3.zero;

            // if parent transform uses physics
            isRigidBody = (gameObject.GetComponent<Rigidbody>() != null);

            // get the pose handler reference
            if (animatorComponent && animatorComponent.avatar && animatorComponent.avatar.isHuman)
            {
                //Transform hipsTransform = animatorComponent.GetBoneTransform(HumanBodyBones.Hips);
                Transform rootTransform = transform.root;  // hipsTransform;  // 

                Vector3 transformPos = rootTransform.position;
                Quaternion transformRot = rootTransform.rotation;
                rootTransform.position = Vector3.zero;
                rootTransform.rotation = Quaternion.identity;

                humanPoseHandler = new HumanPoseHandler(animatorComponent.avatar, rootTransform);
                humanPoseHandler.GetHumanPose(ref humanPose);

                initialHipsPosition = humanPose.bodyPosition;
                initialHipsRotation = humanPose.bodyRotation;

                rootTransform.position = transformPos;
                rootTransform.rotation = transformRot;
                //Debug.Log($"{gameObject.name} - initialHipsPos: {initialHipsPosition}, rot: {initialHipsRotation.eulerAngles}, humanPosePos: {humanPose.bodyPosition}, transformPos: {rootTransform.position}");
            }

            // create bone and joint colliders, if needed
            CreateBoneColliders();
        }


        public virtual void Update()
        {
            if(kinectManager == null)
            {
                kinectManager = KinectManager.Instance;
            }

            ulong userId = kinectManager ? kinectManager.GetUserIdByIndex(playerIndex) : 0;
            if (playerId != userId)
            {
                if (/**playerId == 0 &&*/ userId != 0)
                    SuccessfulCalibration(userId, false);
                else if (/**playerId != 0 &&*/ userId == 0)
                    ResetToInitialPosition();
            }

            if (!lateUpdateAvatar && playerId != 0)
            {
                //Vector3 playerPos = kinectManager.GetUserPosition(playerId);
                //Vector3 playerRot = kinectManager.GetJointOrientation(playerId, 0, true).eulerAngles;
                //Debug.Log(string.Format("Avatar userIndex: {0}, userId: {1}, pos: {2}, rot: {3}", playerIndex, playerId, playerPos, playerRot));

                UpdateAvatar(playerId);
            }
        }


        public virtual void LateUpdate()
        {
            if (lateUpdateAvatar && playerId != 0)
            {
                UpdateAvatar(playerId);
            }

            // update bone colliders, as needed
            UpdateBoneColliders();
        }


        // applies the muscle limits for humanoid avatar
        private void CheckMuscleLimits()
        {
            if (humanPoseHandler == null)
                return;

            humanPoseHandler.GetHumanPose(ref humanPose);

            //Debug.Log(playerId + " - Trans: " + transform.position + ", body: " + humanPose.bodyPosition);

            //bool isPoseChanged = false;

            //float muscleMin = -1f;
            //float muscleMax = 1f;

            //for (int i = 0; i < humanPose.muscles.Length; i++)
            //{
            //    if (float.IsNaN(humanPose.muscles[i]))
            //    {
            //        //humanPose.muscles[i] = 0f;
            //        continue;
            //    }

            //    if (humanPose.muscles[i] < muscleMin)
            //    {
            //        humanPose.muscles[i] = muscleMin;
            //        isPoseChanged = true;
            //    }
            //    else if (humanPose.muscles[i] > muscleMax)
            //    {
            //        humanPose.muscles[i] = muscleMax;
            //        isPoseChanged = true;
            //    }
            //}

            //if (isPoseChanged)
            {
                Vector3 localBodyPos = initialHipsPosition;
                Quaternion localBodyRot = Quaternion.Inverse(transform.rotation) * humanPose.bodyRotation;
                //Vector3 localBodyPos = Quaternion.Inverse(initialHipsRotation) * initialHipsPosition;
                //Quaternion localBodyRot = Quaternion.Inverse(initialHipsRotation) * humanPose.bodyRotation;
                //Debug.Log($"{gameObject.name} - lBodyPos: {localBodyPos}, lBodyRot: {localBodyRot.eulerAngles}\ninitHipsPos: {initialHipsPosition}, initHipsRot: {initialHipsRotation.eulerAngles}");

                // recover the body position & orientation
                humanPose.bodyPosition = localBodyPos;  // initialHipsPosition;
                humanPose.bodyRotation = localBodyRot; // Quaternion.identity;

                humanPoseHandler.SetHumanPose(ref humanPose);
                //Debug.Log("  Human pose updated.");
            }

        }


        /// <summary>
        /// Updates the avatar each frame.
        /// </summary>
        /// <param name="UserID">User ID</param>
        public virtual void UpdateAvatar(ulong UserID)
        {
            if (!gameObject.activeInHierarchy)
                return;

            // Get the KinectManager instance
            if (kinectManager == null)
            {
                kinectManager = KinectManager.Instance;
            }

            //// get the background plane rectangle if needed 
            //if (backgroundPlane && !planeRectSet && kinectManager && kinectManager.IsInitialized())
            //{
            //    planeRectSet = true;

            //    planeRect.width = 10f * Mathf.Abs(backgroundPlane.localScale.x);
            //    planeRect.height = 10f * Mathf.Abs(backgroundPlane.localScale.z);
            //    planeRect.x = backgroundPlane.position.x - planeRect.width / 2f;
            //    planeRect.y = backgroundPlane.position.y - planeRect.height / 2f;
            //}

            // move the avatar to its Kinect position
            if (!externalRootMotion)
            {
                MoveAvatar(UserID);
            }

            //// get the left hand state and event
            //if (kinectManager && kinectManager.GetJointTrackingState(UserID, (int)KinectInterop.JointType.HandLeft) != KinectInterop.TrackingState.NotTracked)
            //{
            //    KinectInterop.HandState leftHandState = kinectManager.GetLeftHandState(UserID);
            //    InteractionManager.HandEventType leftHandEvent = InteractionManager.HandStateToEvent(leftHandState, lastLeftHandEvent);

            //    if (leftHandEvent != InteractionManager.HandEventType.None)
            //    {
            //        lastLeftHandEvent = leftHandEvent;
            //    }
            //}

            //// get the right hand state and event
            //if (kinectManager && kinectManager.GetJointTrackingState(UserID, (int)KinectInterop.JointType.HandRight) != KinectInterop.TrackingState.NotTracked)
            //{
            //    KinectInterop.HandState rightHandState = kinectManager.GetRightHandState(UserID);
            //    InteractionManager.HandEventType rightHandEvent = InteractionManager.HandStateToEvent(rightHandState, lastRightHandEvent);

            //    if (rightHandEvent != InteractionManager.HandEventType.None)
            //    {
            //        lastRightHandEvent = rightHandEvent;
            //    }
            //}

            //// check for sharp pelvis rotations
            //float pelvisAngle = GetPelvisAngle(UserID, false);

            //if (!poseApplied || pelvisAngle < SHARP_ROT_ANGLE)  
            {
                // rotate the avatar bones
                for (var boneIndex = 0; boneIndex < bones.Length; boneIndex++)
                {
                    if (!bones[boneIndex] || isBoneDisabled[boneIndex])  // check for missing or disabled bones
                        continue;

                    bool flip = !(mirroredMovement ^ flipLeftRight);
                    if (boneIndex2JointMap.ContainsKey(boneIndex))
                    {
                        KinectInterop.JointType joint = flip ? boneIndex2JointMap[boneIndex] : boneIndex2MirrorJointMap[boneIndex];

                        if (externalHeadRotation && joint == KinectInterop.JointType.Head)   // skip head if moved externally
                        {
                            continue;
                        }

                        if (externalHandRotations &&    // skip hands if moved externally
                            (joint == KinectInterop.JointType.WristLeft || joint == KinectInterop.JointType.WristRight ||
                                joint == KinectInterop.JointType.HandLeft || joint == KinectInterop.JointType.HandRight))
                        {
                            continue;
                        }

                        TransformBone(UserID, joint, boneIndex, flip);
                    }
                    else if (boneIndex >= 21 && boneIndex <= 24)
                    {
                        // fingers or thumbs
                        if (fingerOrientations && !externalHandRotations)
                        {
                            KinectInterop.JointType joint = flip ? boneIndex2FingerMap[boneIndex] : boneIndex2MirrorFingerMap[boneIndex];

                            TransformSpecialBoneFingers(UserID, (int)joint, boneIndex, flip);
                        }
                    }
                }

            }

            //// save pelvis rotation
            //SavePelvisRotation(UserID);

            //// user pose has been applied
            //poseApplied = true;

            if (applyMuscleLimits && kinectManager && kinectManager.IsUserTracked(UserID))
            {
                // check for limits
                CheckMuscleLimits();
            }

            // update time
            lastUpdateTime = Time.time;
        }

        /// <summary>
        /// Resets bones to their initial positions and rotations. This also releases avatar control from KM, by settings playerId to 0 
        /// </summary>
        public virtual void ResetToInitialPosition()
        {
            //Debug.Log("ResetToInitialPosition. UserId: " + playerId);
            playerId = 0;

            if (bones == null)
                return;

            if(keepLastPose)
            {
                //Vector3 lastPos = new Vector3(transform.position.x, 
                //    posRelativeToCamera != null || posRelOverlayColor ? transform.position.y : initialPosition.y, transform.position.z);
                //ResetInitialTransform(lastPos, transform.rotation);
                return;
            }

            // For each bone that was defined, reset to initial position.
            transform.rotation = Quaternion.identity;

            for (int pass = 0; pass < 2; pass++)  // 2 passes because clavicles are at the end
            {
                for (int i = 0; i < bones.Length; i++)
                {
                    if (bones[i] != null)
                    {
                        bones[i].rotation = initialRotations[i];
                    }
                }
            }

            // reset finger bones to initial position
            //Animator animatorComponent = GetComponent<Animator>();
            foreach (HumanBodyBones bone in fingerBoneLocalRotations.Keys)
            {
                Transform boneTransform = animatorComponent ? animatorComponent.GetBoneTransform(bone) : null;

                if (boneTransform)
                {
                    boneTransform.localRotation = fingerBoneLocalRotations[bone];
                }
            }

            //// Restore the offset's position and rotation
            //if (offsetNode != null)
            //{
            //    offsetNode.transform.position = offsetNodePos;
            //    offsetNode.transform.rotation = offsetNodeRot;
            //}

            transform.position = initialPosition;
            transform.rotation = initialRotation;
            initialUpVector = transform.up;
        }

        /// <summary>
        /// Invoked on the successful calibration of the player.
        /// </summary>
        /// <param name="userId">User identifier.</param>
        public virtual void SuccessfulCalibration(ulong userId, bool resetInitialTransform)
        {
            playerId = userId;
            //Debug.Log("SuccessfulCalibration. UserId: " + playerId);

            //// reset the models position
            //if (offsetNode != null)
            //{
            //    offsetNode.transform.position = offsetNodePos;
            //    offsetNode.transform.rotation = offsetNodeRot;
            //}

            // reset initial position / rotation if needed 
            if (resetInitialTransform)
            {
                bodyRootPosition = transform.position;
                initialPosition = transform.position;
                initialRotation = transform.rotation;
            }

            if(!keepLastPose)
            {
                transform.position = initialPosition;
                transform.rotation = initialRotation;
                initialUpVector = transform.up;

                // re-calibrate the position offset
                offsetCalibrated = false;
                //poseApplied = false;
            }
        }

        /// <summary>
        /// Sets the avatar initial position and rotation. 
        /// </summary>
        /// <param name="position">World position</param>
        /// <param name="rotation">World rotation</param>
        public virtual void ResetInitialTransform(Vector3 position, Vector3 rotation)
        {
            ResetInitialTransform(position, Quaternion.Euler(rotation));
        }

        /// <summary>
        /// Sets the avatar initial position and rotation. 
        /// </summary>
        /// <param name="position">World position</param>
        /// <param name="rotation">World rotation</param>
        public virtual void ResetInitialTransform(Vector3 position, Quaternion rotation)
        {
            bodyRootPosition = position;
            initialPosition = position;
            initialRotation = rotation;

            if (offsetNode != null)
            {
                //bodyRootOffsetPos = bodyRootPosition - offsetNode.position;
                bodyRootPosition = Vector3.zero;
            }

            transform.position = initialPosition;
            transform.rotation = initialRotation;
            initialUpVector = transform.up;

            offsetCalibrated = false;  // this causes calibrating offset in MoveAvatar function 
            //poseApplied = false;
            //Debug.Log($"Initial pos: {initialPosition}, rot: {initialRotation.eulerAngles}, bodyRoot: {bodyRootPosition}");
        }

        /// <summary>
        /// Sets the avatar's offset position (position of initial user detection).
        /// </summary>
        /// <param name="pos">New offset position. If zero, sets the current player position as offset position.</param>
        public void SetOffsetPos(Vector3 pos)
        {
            if(pos == Vector3.zero)
            {
                pos = kinectManager.GetUserPosition(playerId);
            }

            if(pos != Vector3.zero)
            {
                offsetPos.x = pos.x;
                offsetPos.y = pos.y;
                offsetPos.z = !mirroredMovement && !posRelativeToCamera ? -pos.z : pos.z;

                offsetCalibrated = true;
                //Debug.LogWarning($"{gameObject.name} offset set to: {offsetPos:F2}");
            }
        }

        // Checks if the given joint is part of the legs
        protected bool IsLegJoint(KinectInterop.JointType joint)
        {
            return ((joint == KinectInterop.JointType.HipLeft) || (joint == KinectInterop.JointType.HipRight) ||
                    (joint == KinectInterop.JointType.KneeLeft) || (joint == KinectInterop.JointType.KneeRight) ||
                    (joint == KinectInterop.JointType.AnkleLeft) || (joint == KinectInterop.JointType.AnkleRight));
        }

        //// saves current pelvis rotation
        //protected void SavePelvisRotation(ulong userId)
        //{
        //    if (kinectManager != null && kinectManager.IsJointTracked(userId, (int)KinectInterop.JointType.Pelvis))
        //    {
        //        Quaternion curPelvisRot = kinectManager.GetJointOrientation(userId, (int)KinectInterop.JointType.Pelvis, false);
        //        if (poseApplied)
        //            pelvisRotation = Quaternion.RotateTowards(pelvisRotation, curPelvisRot, 90f * Time.deltaTime);  // 90 deg/s
        //        else
        //            pelvisRotation = curPelvisRot;
        //        //Debug.Log($"    P{playerIndex}, id: {playerId} - Pel: {pelvisRotation.eulerAngles}, Cur: {curPelvisRot.eulerAngles} P: {poseApplied}, dT: {Time.deltaTime:F3}, P: {poseApplied}, dT: {Time.deltaTime:F3}");
        //    }
        //}

        //// returns the angle between the last and current pelvis orientations (in degrees 0-180), or -1 if anything goes wrong
        //protected float GetPelvisAngle(ulong userId, bool flip)
        //{
        //    int iJoint = (int)KinectInterop.JointType.Pelvis;
        //    if (kinectManager == null || !kinectManager.IsJointTracked(userId, iJoint))
        //        return -1f;

        //    // get Kinect joint orientation
        //    Quaternion jointRotation = kinectManager.GetJointOrientation(userId, iJoint, flip);
        //    if (jointRotation == Quaternion.identity)
        //        return -1f;

        //    float angle = Quaternion.Angle(pelvisRotation, jointRotation);

        //    return angle;
        //}

        // Apply the rotations tracked by kinect to the joints.
        protected virtual void TransformBone(ulong userId, KinectInterop.JointType joint, int boneIndex, bool flip)
        {
            Transform boneTransform = bones[boneIndex];
            if (boneTransform == null || kinectManager == null)
                return;

            int iJoint = (int)joint;
            if (iJoint < 0 || !kinectManager.IsJointTracked(userId, iJoint))
                return;

            // Get Kinect joint orientation
            Quaternion jointRotation = kinectManager.GetJointOrientation(userId, iJoint, flip);
            if (jointRotation == Quaternion.identity && !IsLegJoint(joint))
                return;

            //if (joint == KinectInterop.JointType.WristLeft)
            //{
            //    //jointRotation = Quaternion.identity;
            //    Debug.Log(string.Format("AC {0:F3} {1}, user: {2}, state: {3}\npos: {4}, rot: {5}", Time.time, joint,
            //        userId, kinectManager.GetJointTrackingState(userId, iJoint),
            //        kinectManager.GetJointPosition(userId, iJoint), jointRotation.eulerAngles));
            //}

            // calculate the new orientation
            Quaternion newRotation = Kinect2AvatarRot(jointRotation, boneIndex);

            if (externalRootMotion)
            {
                newRotation = transform.rotation * newRotation;
            }

            // Smoothly transition to the new rotation
            bool isSmoothAllowed = (Time.time - lastUpdateTime) <= MaxUpdateTime;

            if (isSmoothAllowed && smoothFactor != 0f)
                boneTransform.rotation = Quaternion.Slerp(boneTransform.rotation, newRotation, smoothFactor * (useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime));
            else
                boneTransform.rotation = newRotation;

            //if(boneIndex == 5 || boneIndex == 6)  // clavicles
            //{
            //    Debug.Log(boneIndex + " rot - joint: " + jointRotation.eulerAngles + ", k2a: " + newRotation.eulerAngles + ", trans: " + boneTransform.rotation.eulerAngles);
            //}
        }

        // Apply the rotations tracked by kinect to fingers (one joint = multiple bones)
        protected virtual void TransformSpecialBoneFingers(ulong userId, int joint, int boneIndex, bool flip)
        {
            //// check for hand grips
            //if (joint == (int)KinectInterop.JointType.HandtipLeft || joint == (int)KinectInterop.JointType.ThumbLeft)
            //{
            //    if (lastLeftHandEvent == InteractionManager.HandEventType.Grip)
            //    {
            //        if (!bLeftFistDone && !kinectManager.IsUserTurnedAround(userId))
            //        {
            //            float angleSign = !mirroredMovement /**(boneIndex == 21 || boneIndex == 22)*/ ? -1f : -1f;
            //            float angleRot = angleSign * 60f;

            //            TransformSpecialBoneFist(boneIndex, angleRot);
            //            bLeftFistDone = (boneIndex >= 29);
            //        }

            //        return;
            //    }
            //    else if (bLeftFistDone && lastLeftHandEvent == InteractionManager.HandEventType.Release)
            //    {
            //        TransformSpecialBoneUnfist(boneIndex);
            //        bLeftFistDone = !(boneIndex >= 29);
            //    }
            //}
            //else if (joint == (int)KinectInterop.JointType.HandtipRight || joint == (int)KinectInterop.JointType.ThumbRight)
            //{
            //    if (lastRightHandEvent == InteractionManager.HandEventType.Grip)
            //    {
            //        if (!bRightFistDone && !kinectManager.IsUserTurnedAround(userId))
            //        {
            //            float angleSign = !mirroredMovement /**(boneIndex == 21 || boneIndex == 22)*/ ? -1f : -1f;
            //            float angleRot = angleSign * 60f;

            //            TransformSpecialBoneFist(boneIndex, angleRot);
            //            bRightFistDone = (boneIndex >= 29);
            //        }

            //        return;
            //    }
            //    else if (bRightFistDone && lastRightHandEvent == InteractionManager.HandEventType.Release)
            //    {
            //        TransformSpecialBoneUnfist(boneIndex);
            //        bRightFistDone = !(boneIndex >= 29);
            //    }
            //}

            bool isJointTracked = kinectManager.IsJointTracked(userId, joint);
            if (!animatorComponent || !isJointTracked)
                return;

            // Get Kinect joint orientation
            Quaternion jointRotation = kinectManager.GetJointOrientation(userId, joint, flip);
            if (jointRotation == Quaternion.identity)
                return;

            // calculate the new orientation
            Quaternion newRotation = Kinect2AvatarRot(jointRotation, boneIndex);

            if (externalRootMotion)
            {
                newRotation = transform.rotation * newRotation;
            }

            // get the list of bones
            List<HumanBodyBones> alBones = boneIndex2MultiBoneMap[boneIndex];

            // Smoothly transition to the new rotation
            bool isSmoothAllowed = (Time.time - lastUpdateTime) <= MaxUpdateTime;

            for (int i = 0; i < alBones.Count; i++)
            {
                Transform boneTransform = animatorComponent.GetBoneTransform(alBones[i]);
                if (!boneTransform)
                    continue;

                if (isSmoothAllowed && smoothFactor != 0f)
                    boneTransform.rotation = Quaternion.Slerp(boneTransform.rotation, newRotation, smoothFactor * (useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime));
                else
                    boneTransform.rotation = newRotation;
            }
        }

        // Apply the rotations needed to transform fingers to fist
        protected virtual void TransformSpecialBoneFist(int boneIndex, float angle)
        {
            if (!animatorComponent)
                return;

            List<HumanBodyBones> alBones = boneIndex2MultiBoneMap[boneIndex];
            for (int i = 0; i < alBones.Count; i++)
            {
                if (i < 1 && (boneIndex == 22 || boneIndex == 24))  // skip the first thumb bone
                    continue;

                HumanBodyBones bone = alBones[i];
                Transform boneTransform = animatorComponent.GetBoneTransform(bone);

                // set the fist rotation
                if (boneTransform && fingerBoneLocalAxes[bone] != Vector3.zero)
                {
                    Quaternion qRotFinger = Quaternion.AngleAxis(angle, fingerBoneLocalAxes[bone]);
                    boneTransform.localRotation = fingerBoneLocalRotations[bone] * qRotFinger;
                }
            }

        }

        // Apply the initial rotations fingers
        protected virtual void TransformSpecialBoneUnfist(int boneIndex)
        {
            if (!animatorComponent)
                return;

            List<HumanBodyBones> alBones = boneIndex2MultiBoneMap[boneIndex];
            for (int i = 0; i < alBones.Count; i++)
            {
                HumanBodyBones bone = alBones[i];
                Transform boneTransform = animatorComponent.GetBoneTransform(bone);

                // set the initial rotation
                if (boneTransform)
                {
                    boneTransform.localRotation = fingerBoneLocalRotations[bone];
                }
            }
        }

        // Moves the avatar - gets the tracked position of the user and applies it to avatar.
        protected virtual void MoveAvatar(ulong UserID)
        {
            if (moveRate == 0f || !kinectManager  ||
                !kinectManager.IsJointTracked(UserID, (int)KinectInterop.JointType.Pelvis))
            {
                return;
            }

            // get the position of user's spine base
            Vector3 trans = kinectManager.GetUserPosition(UserID);

            // move avatar transform
            DoMoveAvatar(UserID, trans);
        }

        // Moves the avatar transform
        protected void DoMoveAvatar(ulong UserID, Vector3 trans)
        {
            //Debug.Log($"User {playerIndex} - userPos: {trans:F2}");
            if (flipLeftRight)
                trans.x = -trans.x;

            if (posRelativeToCamera)
            {
                if (posRelOverlayColor)
                {
                    // disable grounded feet
                    if(groundedFeet)
                    {
                        groundedFeet = false;
                    }

                    // use the color overlay position
                    int sensorIndex = kinectManager.GetPrimaryBodySensorIndex();

                    //if (backgroundPlane && planeRectSet)
                    //{
                    //    // get the plane overlay position
                    //    trans = kinectManager.GetJointPosColorOverlay(UserID, (int)KinectInterop.JointType.Pelvis, sensorIndex, planeRect);
                    //    trans.z = backgroundPlane.position.z - posRelativeToCamera.transform.position.z - 0.1f;  // 10cm offset
                    //}
                    //else
                    {
                        Rect backgroundRect = posRelativeToCamera.pixelRect;
                        PortraitBackground portraitBack = PortraitBackground.Instance;

                        if (portraitBack && portraitBack.enabled)
                        {
                            backgroundRect = portraitBack.GetBackgroundRect();
                        }

                        trans = kinectManager.GetJointPosColorOverlay(UserID, (int)KinectInterop.JointType.Pelvis, sensorIndex, posRelativeToCamera, backgroundRect);
                        trans.y -= hipCenterDist * transform.localScale.y;
                    }
                }
                else
                {
                    // move according to the camera
                    Vector3 bodyRootPos = bodyRoot != null ? bodyRoot.position : transform.position;
                    Vector3 userLocalPos = kinectManager.GetUserKinectPosition(UserID, true);
                    trans = posRelativeToCamera.transform.TransformPoint(userLocalPos);
                    //Debug.Log("  trans: " + trans + ", localPos: " + userLocalPos + ", camPos: " + posRelativeToCamera.transform.position);

                    if (!horizontalMovement)
                    {
                        trans = new Vector3(bodyRootPos.x, trans.y, bodyRootPos.z);
                    }

                    if (verticalMovement)
                    {
                        trans.y -= hipCenterDist * transform.localScale.y;
                    }
                    else
                    {
                        trans.y = bodyRootPos.y;
                    }

                    //Debug.Log("cameraPos: " + posRelativeToCamera.transform.position + ", cameraRot: " + posRelativeToCamera.transform.rotation.eulerAngles +
                    //    ", bodyRoot: " + bodyRootPos + ", hipCenterDist: " + hipCenterDist + ", localPos: " + userLocalPos + ", trans: " + trans);
                }

                if (flipLeftRight)
                    trans.x = -trans.x;

                if(posRelOverlayColor || !offsetCalibrated)
                {
                    if (bodyRoot != null)
                    {
                        bodyRoot.position = trans;
                    }
                    else
                    {
                        transform.position = trans;
                    }

                    bodyRootPosition = trans;
                    //Debug.Log($"BodyRootPos set: {trans:F2}");

                    // reset the body offset
                    offsetCalibrated = false;
                }
            }

            // invert the z-coordinate, if needed
            if (posRelativeToCamera && posRelInvertedZ)
            {
                trans.z = -trans.z;
            }

            //if (posRelativeToCamera /**&& horizontalMovement*/)
            //{
            //    //if(offsetCamPos != posRelativeToCamera.transform.position || offsetCamRot != posRelativeToCamera.transform.rotation)
            //    {
            //        //offsetCamPos = posRelativeToCamera.transform.position;
            //        //offsetCamRot = posRelativeToCamera.transform.rotation;
            //        //Debug.Log("Changed cam pos: " + offsetCamPos + ", rot: " + offsetCamRot.eulerAngles);
            //    }
            //}

            if (!offsetCalibrated)
            {
                offsetPos.x = trans.x;  // !mirroredMovement ? trans.x * moveRate : -trans.x * moveRate;
                offsetPos.y = trans.y;  // trans.y * moveRate;
                offsetPos.z = !mirroredMovement && !posRelativeToCamera ? -trans.z : trans.z;  // -trans.z * moveRate;

                offsetCalibrated = posRelativeToCamera || GetUserHipAngle(UserID) >= 150f;
                //Debug.LogWarning($"{gameObject.name} offset: {offsetPos:F2}, calibrated: {offsetCalibrated}, hipAngle: {GetUserHipAngle(UserID):F1}");
            }

            // transition to the new position
            Vector3 targetPos = bodyRootPosition + Kinect2AvatarPos(trans, verticalMovement, horizontalMovement);
            //Debug.Log($"  avatar {playerIndex} - targetPos: {targetPos}, trans: {trans}\noffsetPos: {offsetPos}, bodyRootPos: {bodyRootPosition}");

            if (isRigidBody && !verticalMovement)
            {
                // workaround for obeying the physics (e.g. gravity falling)
                targetPos.y = bodyRoot != null ? bodyRoot.position.y : transform.position.y;
            }

            // fixed bone indices - thanks to Martin Cvengros!
            var biShoulderL = GetBoneIndexByJoint(KinectInterop.JointType.ShoulderLeft, false);  // you may replace 'false' with 'mirroredMovement'
            var biShoulderR = GetBoneIndexByJoint(KinectInterop.JointType.ShoulderRight, false);  // you may replace 'false' with 'mirroredMovement'
            var biPelvis = GetBoneIndexByJoint(KinectInterop.JointType.Pelvis, false);  // you may replace 'false' with 'mirroredMovement'
            var biNeck = GetBoneIndexByJoint(KinectInterop.JointType.Neck, false);  // you may replace 'false' with 'mirroredMovement'

            // added by r618
            if (horizontalMovement && horizontalOffset != 0f &&
                bones[biShoulderL] != null && bones[biShoulderR] != null)
            {
                // { 5, HumanBodyBones.LeftUpperArm},
                // { 11, HumanBodyBones.RightUpperArm},
                //Vector3 dirSpine = bones[5].position - bones[11].position;
                Vector3 dirShoulders = bones[biShoulderR].position - bones[biShoulderL].position;
                targetPos += dirShoulders.normalized * horizontalOffset;
            }

            if (verticalMovement && verticalOffset != 0f &&
                bones[biPelvis] != null && bones[biNeck] != null)
            {
                Vector3 dirSpine = bones[biNeck].position - bones[biPelvis].position;
                targetPos += dirSpine.normalized * verticalOffset;
            }

            if (horizontalMovement && forwardOffset != 0f &&
                bones[biPelvis] != null && bones[biNeck] != null && bones[biShoulderL] != null && bones[biShoulderR] != null)
            {
                Vector3 dirSpine = (bones[biNeck].position - bones[biPelvis].position).normalized;
                Vector3 dirShoulders = (bones[biShoulderR].position - bones[biShoulderL].position).normalized;
                Vector3 dirForward = Vector3.Cross(dirShoulders, dirSpine).normalized;

                targetPos += dirForward * forwardOffset;
            }

            if (groundedFeet && verticalMovement)  // without vertical movement, grounding produces an ever expanding jump up & down
            {
                float fNewDistance = GetCorrDistanceToGround();
                float fNewDistanceTime = useUnscaledTime ? Time.unscaledTime : Time.time;
                //Vector3 lastTargetPos = targetPos;

                if (Mathf.Abs(fNewDistance) >= MaxFootDistanceGround && Mathf.Abs(fFootDistance + fNewDistance) < 1f)  // limit the correction to 1 meter
                {
                    if ((fNewDistanceTime - fFootDistanceTime) >= MaxFootDistanceTime)
                    {
                        fFootDistance += fNewDistance;
                        fFootDistanceTime = fNewDistanceTime;

                        vFootCorrection = initialUpVector * fFootDistance;

                        //Debug.Log($"****{leftFoot.name} pos: {leftFoot.position}, ini: {leftFootPos}, dif: {leftFoot.position - leftFootPos}\n" +
                        //    $"****{rightFoot.name} pos: {rightFoot.position}, ini: {rightFootPos}, dif: {rightFoot.position - rightFootPos}\n" +
                        //    $"****footDist: {fNewDistance:F2}, footCorr: {vFootCorrection}, {transform.name} pos: {transform.position}");
                    }
                }
                else
                {
                    fFootDistanceTime = fNewDistanceTime;
                }

                targetPos += vFootCorrection;
                //Debug.Log($"Gnd targetPos: {targetPos}, lastPos: {lastTargetPos}, vFootCorrection: {vFootCorrection}\nfFootDistance: {fFootDistance:F2}, fNewDistance: {fNewDistance:F2}, upVector: {initialUpVector}, distTime: {(fNewDistanceTime - fFootDistanceTime):F3}");
            }

            //Debug.Log($"User {playerIndex} - targetPos: {targetPos:F2}\ntrans: {trans:F2}, bodyRoot: {bodyRootPosition:F2}");
            bool isSmoothAllowed = (Time.time - lastUpdateTime) <= MaxUpdateTime;
            if (bodyRoot != null)
            {
                bodyRoot.position = isSmoothAllowed && smoothFactor != 0f ?
                    Vector3.Lerp(bodyRoot.position, targetPos, smoothFactor * (useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime)) : targetPos;
            }
            else
            {
                transform.position = isSmoothAllowed && smoothFactor != 0f ?
                    Vector3.Lerp(transform.position, targetPos, smoothFactor * (useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime)) : targetPos;
            }
        }

        // Returns the angle at user's hip (knee-hip-neck)
        protected float GetUserHipAngle(ulong userId)
        {
            float angle = 0f;

            if(kinectManager != null &&
                kinectManager.IsJointTracked(userId, (int)KinectInterop.JointType.Pelvis) && kinectManager.IsJointTracked(userId, (int)KinectInterop.JointType.Neck) &&
                kinectManager.IsJointTracked(userId, (int)KinectInterop.JointType.KneeLeft) && kinectManager.IsJointTracked(userId, (int)KinectInterop.JointType.KneeRight))
            {
                Vector3 posPelvis = kinectManager.GetJointPosition(userId, (int)KinectInterop.JointType.Pelvis);
                Vector3 posNeck = kinectManager.GetJointPosition(userId, (int)KinectInterop.JointType.Neck);

                Vector3 posKneeL = kinectManager.GetJointPosition(userId, (int)KinectInterop.JointType.KneeLeft);
                Vector3 posKneeR = kinectManager.GetJointPosition(userId, (int)KinectInterop.JointType.KneeRight);
                Vector3 posKneeC = (posKneeL + posKneeR) * 0.5f;

                angle = Vector3.Angle(posNeck - posPelvis, posKneeC - posPelvis);
                //Debug.Log($"Player {playerIndex} neck-hip-cknee angle: {angle:F1}");
            }

            return angle;
        }

        // Set model's arms to be in T-pose
        protected virtual void SetModelArmsInTpose()
        {
            Vector3 vTposeLeftDir = transform.TransformDirection(Vector3.left);
            Vector3 vTposeRightDir = transform.TransformDirection(Vector3.right);

            Transform transLeftUarm = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.ShoulderLeft, false)); // animator.GetBoneTransform(HumanBodyBones.LeftUpperArm);
            Transform transLeftLarm = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.ElbowLeft, false)); // animator.GetBoneTransform(HumanBodyBones.LeftLowerArm);
            Transform transLeftHand = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.WristLeft, false)); // animator.GetBoneTransform(HumanBodyBones.LeftHand);

            if (transLeftUarm != null && transLeftLarm != null)
            {
                Vector3 vUarmLeftDir = transLeftLarm.position - transLeftUarm.position;
                float fUarmLeftAngle = Vector3.Angle(vUarmLeftDir, vTposeLeftDir);

                if (Mathf.Abs(fUarmLeftAngle) >= 5f)
                {
                    Quaternion vFixRotation = Quaternion.FromToRotation(vUarmLeftDir, vTposeLeftDir);
                    transLeftUarm.rotation = vFixRotation * transLeftUarm.rotation;
                }

                if (transLeftHand != null)
                {
                    Vector3 vLarmLeftDir = transLeftHand.position - transLeftLarm.position;
                    float fLarmLeftAngle = Vector3.Angle(vLarmLeftDir, vTposeLeftDir);

                    if (Mathf.Abs(fLarmLeftAngle) >= 5f)
                    {
                        Quaternion vFixRotation = Quaternion.FromToRotation(vLarmLeftDir, vTposeLeftDir);
                        transLeftLarm.rotation = vFixRotation * transLeftLarm.rotation;
                    }
                }
            }

            Transform transRightUarm = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.ShoulderRight, false)); // animator.GetBoneTransform(HumanBodyBones.RightUpperArm);
            Transform transRightLarm = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.ElbowRight, false)); // animator.GetBoneTransform(HumanBodyBones.RightLowerArm);
            Transform transRightHand = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.WristRight, false)); // animator.GetBoneTransform(HumanBodyBones.RightHand);

            if (transRightUarm != null && transRightLarm != null)
            {
                Vector3 vUarmRightDir = transRightLarm.position - transRightUarm.position;
                float fUarmRightAngle = Vector3.Angle(vUarmRightDir, vTposeRightDir);

                if (Mathf.Abs(fUarmRightAngle) >= 5f)
                {
                    Quaternion vFixRotation = Quaternion.FromToRotation(vUarmRightDir, vTposeRightDir);
                    transRightUarm.rotation = vFixRotation * transRightUarm.rotation;
                }

                if (transRightHand != null)
                {
                    Vector3 vLarmRightDir = transRightHand.position - transRightLarm.position;
                    float fLarmRightAngle = Vector3.Angle(vLarmRightDir, vTposeRightDir);

                    if (Mathf.Abs(fLarmRightAngle) >= 5f)
                    {
                        Quaternion vFixRotation = Quaternion.FromToRotation(vLarmRightDir, vTposeRightDir);
                        transRightLarm.rotation = vFixRotation * transRightLarm.rotation;
                    }
                }
            }

        }

        // If the bones to be mapped have been declared, map that bone to the model.
        protected virtual void MapBones()
        {
            for (int boneIndex = 0; boneIndex < bones.Length; boneIndex++)
            {
                if (!boneIndex2MecanimMap.ContainsKey(boneIndex))
                    continue;

                bones[boneIndex] = animatorComponent ? animatorComponent.GetBoneTransform(boneIndex2MecanimMap[boneIndex]) : null;
            }

            //// map finger bones, too
            //fingerBones = new Transform[fingerIndex2MecanimMap.Count];

            //for (int boneIndex = 0; boneIndex < fingerBones.Length; boneIndex++)
            //{
            //    if (!fingerIndex2MecanimMap.ContainsKey(boneIndex))
            //        continue;

            //    fingerBones[boneIndex] = animatorComponent ? animatorComponent.GetBoneTransform(fingerIndex2MecanimMap[boneIndex]) : null;
            //}
        }

        // creates the joint and bone colliders 
        protected virtual void CreateBoneColliders()
        {
            if (boneColliderRadius <= 0f)
                return;

            boneColliders = new CapsuleCollider[bones.Length];
            boneColTrans = new Transform[bones.Length];
            boneColJoint = new Transform[bones.Length];
            boneColParent = new Transform[bones.Length];

            for (int i = 0; i < bones.Length; i++)
            {
                if (bones[i] == null)
                    continue;

                SphereCollider jCollider = bones[i].gameObject.AddComponent<SphereCollider>();
                jCollider.radius = boneColliderRadius;

                if (i > 0)
                {
                    GameObject objBoneCollider = new GameObject("BoneCollider" + i);
                    objBoneCollider.transform.parent = bones[i];
                    boneColTrans[i] = objBoneCollider.transform;

                    CapsuleCollider bCollider = objBoneCollider.AddComponent<CapsuleCollider>();
                    bCollider.radius = boneColliderRadius;
                    bCollider.height = 0f;

                    boneColliders[i] = bCollider;
                }
            }

            for (int i = 0; i < bones.Length; i++)
            {
                if (boneColliders[i] == null)
                    continue;

                boneColJoint[i] = bones[i];
                Transform parentTrans = boneColJoint[i].parent;

                while (parentTrans != null)
                {
                    if (parentTrans.GetComponent<SphereCollider>() != null)
                        break;
                    parentTrans = parentTrans.parent;
                }

                if (parentTrans != null)
                    boneColParent[i] = parentTrans;
                else
                    boneColliders[i] = null;
            }
        }

        // updates the bone colliders, as needed
        protected void UpdateBoneColliders()
        {
            if (boneColliders == null)
                return;

            for (int i = 0; i < bones.Length; i++)
            {
                if (boneColliders[i] == null)
                    continue;

                Vector3 posJoint = boneColJoint[i].position;
                Vector3 posParent = boneColParent[i].position;

                Vector3 dirFromParent = posJoint - posParent;
                boneColTrans[i].position = posParent + dirFromParent / 2f;
                boneColTrans[i].up = dirFromParent.normalized;
                boneColliders[i].height = dirFromParent.magnitude;
            }
        }

        // Capture the initial rotations of the bones
        protected void GetInitialRotations()
        {
            //// save the initial rotation
            //if (offsetNode != null)
            //{
            //    offsetNodePos = offsetNode.transform.position;
            //    offsetNodeRot = offsetNode.transform.rotation;
            //}

            initialPosition = transform.position;
            initialRotation = transform.rotation;
            initialUpVector = transform.up;

            transform.rotation = Quaternion.identity;

            // save the body root initial position
            if (bodyRoot != null)
            {
                bodyRootPosition = bodyRoot.position;
            }
            else
            {
                bodyRootPosition = transform.position;
            }

            if (offsetNode != null)
            {
                bodyRootOffsetPos = bodyRootPosition - offsetNode.position;
                bodyRootPosition = Vector3.zero;
                //Debug.Log($"bodyRootOffsetPos: {bodyRootOffsetPos}");
            }

            // save the initial bone rotations
            for (int i = 0; i < bones.Length; i++)
            {
                if (bones[i] != null)
                {
                    initialRotations[i] = bones[i].rotation;
                    localRotations[i] = bones[i].localRotation;
                }
            }

            // get finger bones' local rotations
            foreach (int boneIndex in boneIndex2MultiBoneMap.Keys)
            {
                List<HumanBodyBones> alBones = boneIndex2MultiBoneMap[boneIndex];

                for (int b = 0; b < alBones.Count; b++)
                {
                    HumanBodyBones bone = alBones[b];
                    Transform boneTransform = animatorComponent ? animatorComponent.GetBoneTransform(bone) : null;

                    // get the finger's 1st transform
                    Transform fingerBaseTransform = animatorComponent ? animatorComponent.GetBoneTransform(alBones[b - (b % 3)]) : null;

                    // get the finger's 2nd transform
                    Transform baseChildTransform = fingerBaseTransform && fingerBaseTransform.childCount > 0 ? fingerBaseTransform.GetChild(0) : null;
                    Vector3 vBoneDirChild = baseChildTransform && fingerBaseTransform ? (baseChildTransform.position - fingerBaseTransform.position).normalized : Vector3.zero;
                    Vector3 vOrthoDirChild = Vector3.Cross(vBoneDirChild, Vector3.up).normalized;

                    if (boneTransform)
                    {
                        fingerBoneLocalRotations[bone] = boneTransform.localRotation;

                        if (vBoneDirChild != Vector3.zero)
                        {
                            fingerBoneLocalAxes[bone] = boneTransform.InverseTransformDirection(vOrthoDirChild).normalized;
                        }
                        else
                        {
                            fingerBoneLocalAxes[bone] = Vector3.zero;
                        }
                    }
                }
            }

            // Restore the initial rotation
            transform.rotation = initialRotation;
        }

        // Converts kinect joint rotation to avatar joint rotation, depending on joint initial rotation and offset rotation
        protected Quaternion Kinect2AvatarRot(Quaternion jointRotation, int boneIndex)
        {
            Quaternion newRotation = jointRotation * initialRotations[boneIndex];
            //newRotation = initialRotation * newRotation;

            if (!externalRootMotion)  // fix by Mathias Parger
            {
                newRotation = initialRotation * newRotation;
            }

            if (offsetNode != null)
            {
                //newRotation = offsetNode.rotation * newRotation;

                Matrix4x4 matAvatar = Matrix4x4.identity;
                matAvatar.SetTRS(transform.position - offsetNode.position, newRotation, Vector3.one);
                Matrix4x4 matOffsetNode = Matrix4x4.identity;
                matOffsetNode.SetTRS(offsetNode.position, offsetNode.rotation, Vector3.one);

                Matrix4x4 matOffset = matOffsetNode * matAvatar;
                newRotation = matOffset.rotation;
            }

            return newRotation;
        }

        // Converts Kinect position to avatar skeleton position, depending on initial position, mirroring and move rate
        protected Vector3 Kinect2AvatarPos(Vector3 jointPosition, bool bMoveVertically, bool bMoveHorizontally)
        {
            float xPos = (jointPosition.x - offsetPos.x) * moveRate;
            float yPos = (jointPosition.y - offsetPos.y) * moveRate;
            float zPos = !mirroredMovement && !posRelativeToCamera ? (-jointPosition.z - offsetPos.z) * moveRate : (jointPosition.z - offsetPos.z) * moveRate;

            Vector3 newPosition = new Vector3(bMoveHorizontally ? xPos : 0f, bMoveVertically ? yPos : 0f, bMoveHorizontally ? zPos : 0f);

            Quaternion posRotation = mirroredMovement ? Quaternion.Euler(0f, 180f, 0f) * initialRotation : initialRotation;
            newPosition = posRotation * newPosition;

            if (offsetNode != null)
            {
                //newPosition += offsetNode.position;
                ////newPosition = offsetNode.position;

                Matrix4x4 matAvatar = Matrix4x4.identity;
                matAvatar.SetTRS(bodyRootOffsetPos + newPosition, Quaternion.Inverse(offsetNode.rotation) * transform.rotation, Vector3.one);
                Matrix4x4 matOffsetNode = Matrix4x4.identity;
                matOffsetNode.SetTRS(offsetNode.position, offsetNode.rotation, Vector3.one);

                Matrix4x4 matOffset = matOffsetNode * matAvatar;
                newPosition = matOffset.GetPosition();
            }

            return newPosition;
        }

        // returns distance from the given transform to its initial position
        protected virtual float GetCorrDistanceToGround(Transform trans, Vector3 initialPos, bool isRightJoint)
        {
            if (!trans)
                return 0f;

            Vector3 deltaDir = trans.position - initialPos;
            Vector3 vTrans = new Vector3(deltaDir.x * initialUpVector.x, deltaDir.y * initialUpVector.y, deltaDir.z * initialUpVector.z);

            float fSign = Vector3.Dot(deltaDir, initialUpVector) < 0f ? 1f : -1f;  // change the sign, because it's a correction
            float deltaDist = fSign * vTrans.magnitude;

            return deltaDist;
        }

        // returns the min distance distance from left or right foot to the ground, or 0 if no LF/RF are found
        protected virtual float GetCorrDistanceToGround()
        {
            //if (leftFoot == null && rightFoot == null)
            //{
            //    leftFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.FootLeft, false));
            //    rightFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.FootRight, false));

            //    if (leftFoot == null || rightFoot == null)
            //    {
            //        leftFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.AnkleLeft, false));
            //        rightFoot = GetBoneTransform(GetBoneIndexByJoint(KinectInterop.JointType.AnkleRight, false));
            //    }

            //    leftFootPos = leftFoot != null ? leftFoot.position : Vector3.zero;
            //    rightFootPos = rightFoot != null ? rightFoot.position : Vector3.zero;
            //}

            float fDistMin = 1000f;
            float fDistLeft = leftFoot ? GetCorrDistanceToGround(leftFoot, leftFootPos, false) : fDistMin;
            float fDistRight = rightFoot ? GetCorrDistanceToGround(rightFoot, rightFootPos, true) : fDistMin;
            fDistMin = Mathf.Abs(fDistLeft) < Mathf.Abs(fDistRight) ? fDistLeft : fDistRight;

            if (fDistMin == 1000f)
            {
                fDistMin = 0f;
            }

            return fDistMin;
        }

        //	protected void OnCollisionEnter(Collision col)
        //	{
        //		Debug.Log("Collision entered");
        //	}
        //
        //	protected void OnCollisionExit(Collision col)
        //	{
        //		Debug.Log("Collision exited");
        //	}



        // dictionaries to speed up bone processing
        protected static readonly Dictionary<int, HumanBodyBones> boneIndex2MecanimMap = new Dictionary<int, HumanBodyBones>
        {
            {0, HumanBodyBones.Hips},
            {1, HumanBodyBones.Spine},
            {2, HumanBodyBones.Chest},
		    {3, HumanBodyBones.Neck},
    		{4, HumanBodyBones.Head},

            {5, HumanBodyBones.LeftShoulder},
            {6, HumanBodyBones.LeftUpperArm},
            {7, HumanBodyBones.LeftLowerArm},
            {8, HumanBodyBones.LeftHand},

            {9, HumanBodyBones.RightShoulder},
            {10, HumanBodyBones.RightUpperArm},
            {11, HumanBodyBones.RightLowerArm},
            {12, HumanBodyBones.RightHand},
		
		    {13, HumanBodyBones.LeftUpperLeg},
            {14, HumanBodyBones.LeftLowerLeg},
            {15, HumanBodyBones.LeftFoot},
    		{16, HumanBodyBones.LeftToes},
		
		    {17, HumanBodyBones.RightUpperLeg},
            {18, HumanBodyBones.RightLowerLeg},
            {19, HumanBodyBones.RightFoot},
    		{20, HumanBodyBones.RightToes},

		    {21, HumanBodyBones.LeftIndexProximal},
            {22, HumanBodyBones.LeftThumbProximal},
            {23, HumanBodyBones.RightIndexProximal},
            {24, HumanBodyBones.RightThumbProximal},
        };

        protected static readonly Dictionary<int, KinectInterop.JointType> boneIndex2JointMap = new Dictionary<int, KinectInterop.JointType>
        {
            {0, KinectInterop.JointType.Pelvis},
            {1, KinectInterop.JointType.SpineNaval},
            {2, KinectInterop.JointType.SpineChest},
            {3, KinectInterop.JointType.Neck},
            {4, KinectInterop.JointType.Head},

            {5, KinectInterop.JointType.ClavicleLeft},
            {6, KinectInterop.JointType.ShoulderLeft},
            {7, KinectInterop.JointType.ElbowLeft},
            {8, KinectInterop.JointType.WristLeft},

            {9, KinectInterop.JointType.ClavicleRight},
            {10, KinectInterop.JointType.ShoulderRight},
            {11, KinectInterop.JointType.ElbowRight},
            {12, KinectInterop.JointType.WristRight},

            {13, KinectInterop.JointType.HipLeft},
            {14, KinectInterop.JointType.KneeLeft},
            {15, KinectInterop.JointType.AnkleLeft},
            {16, KinectInterop.JointType.FootLeft},

            {17, KinectInterop.JointType.HipRight},
            {18, KinectInterop.JointType.KneeRight},
            {19, KinectInterop.JointType.AnkleRight},
            {20, KinectInterop.JointType.FootRight},
        };

        protected static readonly Dictionary<int, KinectInterop.JointType> boneIndex2MirrorJointMap = new Dictionary<int, KinectInterop.JointType>
        {
            {0, KinectInterop.JointType.Pelvis},
            {1, KinectInterop.JointType.SpineNaval},
            {2, KinectInterop.JointType.SpineChest},
            {3, KinectInterop.JointType.Neck},
            {4, KinectInterop.JointType.Head},

            {5, KinectInterop.JointType.ClavicleRight},
            {6, KinectInterop.JointType.ShoulderRight},
            {7, KinectInterop.JointType.ElbowRight},
            {8, KinectInterop.JointType.WristRight},

            {9, KinectInterop.JointType.ClavicleLeft},
            {10, KinectInterop.JointType.ShoulderLeft},
            {11, KinectInterop.JointType.ElbowLeft},
            {12, KinectInterop.JointType.WristLeft},

            {13, KinectInterop.JointType.HipRight},
            {14, KinectInterop.JointType.KneeRight},
            {15, KinectInterop.JointType.AnkleRight},
            {16, KinectInterop.JointType.FootRight},

            {17, KinectInterop.JointType.HipLeft},
            {18, KinectInterop.JointType.KneeLeft},
            {19, KinectInterop.JointType.AnkleLeft},
            {20, KinectInterop.JointType.FootLeft},
        };

        protected static readonly Dictionary<KinectInterop.JointType, int> jointMap2boneIndex = new Dictionary<KinectInterop.JointType, int>
        {
            {KinectInterop.JointType.Pelvis, 0},
            {KinectInterop.JointType.SpineNaval, 1},
            {KinectInterop.JointType.SpineChest, 2},
            {KinectInterop.JointType.Neck, 3},
            {KinectInterop.JointType.Head, 4},

            {KinectInterop.JointType.ClavicleLeft, 5},
            {KinectInterop.JointType.ShoulderLeft, 6},
            {KinectInterop.JointType.ElbowLeft, 7},
            {KinectInterop.JointType.WristLeft, 8},

            {KinectInterop.JointType.ClavicleRight, 9},
            {KinectInterop.JointType.ShoulderRight, 10},
            {KinectInterop.JointType.ElbowRight, 11},
            {KinectInterop.JointType.WristRight, 12},

            {KinectInterop.JointType.HipLeft, 13},
            {KinectInterop.JointType.KneeLeft, 14},
            {KinectInterop.JointType.AnkleLeft, 15},
            {KinectInterop.JointType.FootLeft, 16},

            {KinectInterop.JointType.HipRight, 17},
            {KinectInterop.JointType.KneeRight, 18},
            {KinectInterop.JointType.AnkleRight, 19},
            {KinectInterop.JointType.FootRight, 20},
        };

        protected static readonly Dictionary<KinectInterop.JointType, int> mirrorJointMap2boneIndex = new Dictionary<KinectInterop.JointType, int>
        {
            {KinectInterop.JointType.Pelvis, 0},
            {KinectInterop.JointType.SpineNaval, 1},
            {KinectInterop.JointType.SpineChest, 2},
            {KinectInterop.JointType.Neck, 3},
            {KinectInterop.JointType.Head, 4},

            {KinectInterop.JointType.ClavicleRight, 5},
            {KinectInterop.JointType.ShoulderRight, 6},
            {KinectInterop.JointType.ElbowRight, 7},
            {KinectInterop.JointType.WristRight, 8},

            {KinectInterop.JointType.ClavicleLeft, 9},
            {KinectInterop.JointType.ShoulderLeft, 10},
            {KinectInterop.JointType.ElbowLeft, 11},
            {KinectInterop.JointType.WristLeft, 12},

            {KinectInterop.JointType.HipRight, 13},
            {KinectInterop.JointType.KneeRight, 14},
            {KinectInterop.JointType.AnkleRight, 15},
            {KinectInterop.JointType.FootRight, 16},

            {KinectInterop.JointType.HipLeft, 17},
            {KinectInterop.JointType.KneeLeft, 18},
            {KinectInterop.JointType.AnkleLeft, 19},
            {KinectInterop.JointType.FootLeft, 20},
        };

        protected static readonly Dictionary<int, KinectInterop.JointType> boneIndex2FingerMap = new Dictionary<int, KinectInterop.JointType>
        {
            {21, KinectInterop.JointType.HandtipLeft},
            {22, KinectInterop.JointType.ThumbLeft},
            {23, KinectInterop.JointType.HandtipRight},
            {24, KinectInterop.JointType.ThumbRight},
        };

        protected static readonly Dictionary<int, KinectInterop.JointType> boneIndex2MirrorFingerMap = new Dictionary<int, KinectInterop.JointType>
        {
            {21, KinectInterop.JointType.HandtipRight},
            {22, KinectInterop.JointType.ThumbRight},
            {23, KinectInterop.JointType.HandtipLeft},
            {24, KinectInterop.JointType.ThumbLeft},
        };

        protected static readonly Dictionary<int, List<HumanBodyBones>> boneIndex2MultiBoneMap = new Dictionary<int, List<HumanBodyBones>>
        {
            {21, new List<HumanBodyBones> {  // left fingers
				    HumanBodyBones.LeftIndexProximal,
                    HumanBodyBones.LeftIndexIntermediate,
                    HumanBodyBones.LeftIndexDistal,
                    HumanBodyBones.LeftMiddleProximal,
                    HumanBodyBones.LeftMiddleIntermediate,
                    HumanBodyBones.LeftMiddleDistal,
                    HumanBodyBones.LeftRingProximal,
                    HumanBodyBones.LeftRingIntermediate,
                    HumanBodyBones.LeftRingDistal,
                    HumanBodyBones.LeftLittleProximal,
                    HumanBodyBones.LeftLittleIntermediate,
                    HumanBodyBones.LeftLittleDistal,
                }},
            {22, new List<HumanBodyBones> {  // left thumb
				    HumanBodyBones.LeftThumbProximal,
                    HumanBodyBones.LeftThumbIntermediate,
                    HumanBodyBones.LeftThumbDistal,
                }},
            {23, new List<HumanBodyBones> {  // right fingers
				    HumanBodyBones.RightIndexProximal,
                    HumanBodyBones.RightIndexIntermediate,
                    HumanBodyBones.RightIndexDistal,
                    HumanBodyBones.RightMiddleProximal,
                    HumanBodyBones.RightMiddleIntermediate,
                    HumanBodyBones.RightMiddleDistal,
                    HumanBodyBones.RightRingProximal,
                    HumanBodyBones.RightRingIntermediate,
                    HumanBodyBones.RightRingDistal,
                    HumanBodyBones.RightLittleProximal,
                    HumanBodyBones.RightLittleIntermediate,
                    HumanBodyBones.RightLittleDistal,
                }},
            {24, new List<HumanBodyBones> {  // right thumb
				    HumanBodyBones.RightThumbProximal,
                    HumanBodyBones.RightThumbIntermediate,
                    HumanBodyBones.RightThumbDistal,
                }},
        };

    }
}
