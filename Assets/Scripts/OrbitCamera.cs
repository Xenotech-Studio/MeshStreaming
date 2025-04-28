using UnityEngine;

/// <summary>
/// 
/// Orbit-style camera controller supporting mouse & touch with a unified post-processing pipeline.
/// 拖动旋转；滚轮 / 双指缩放；所有输入在 CollectInput() 中汇总，后续只走 ApplyInput()。
/// </summary>

public class OrbitCamera : MonoBehaviour
{
    public Camera camera; // 需要在 Inspector 中指定 Camera
    
    [Header("Focus Target")]
    public Transform target;
    public float Y = 1.7f;
    public float distance = 1.5f;

    [Header("Limits")]
    public float minDistance = 1f;
    public float maxDistance = 15f;
    public float minPitch = -30f;
    public float maxPitch = 80f;

    [Header("Speeds")]
    public float rotateSpeed = 150f;      // °/s
    public float zoomSpeed   =  5f;       // mouse wheel
    public float pinchFactor = 0.02f;     // touch pinch sensitivity

    // runtime state
    float yaw;
    float pitch;

    void Start()
    {
        if (!ValidateTarget()) return;

        Vector3 offset = camera.transform.position - target.position - new Vector3(0, Y, 0);
        distance = offset.magnitude;
        yaw   = Mathf.Atan2(offset.x, offset.z) * Mathf.Rad2Deg;
        pitch = Mathf.Asin(offset.y / distance) * Mathf.Rad2Deg;
    }

    void Update()
    {
        if (!ValidateTarget()) return;

        // 1. 收集所有输入
        Vector2 deltaRot;
        float   zoomScale;
        CollectInput(out deltaRot, out zoomScale);

        // 2. 统一应用
        ApplyInput(deltaRot, zoomScale);

        // 3. 更新相机 Transform
        UpdateTransform();
    }

    #region Input
    /// <summary>采集鼠标/触摸输入，并汇总成统一的旋转 Δ 和缩放倍率。</summary>
    void CollectInput(out Vector2 deltaRot, out float zoomScale)
    {
        deltaRot = Vector2.zero;
        zoomScale = 1f;

        // ---------- 鼠标 ----------
        if (Input.touchCount == 0)     // 只在没有触摸时使用鼠标
        {
            if (Input.GetMouseButton(0))
            {
                deltaRot.x = Input.GetAxis("Mouse X") * rotateSpeed * Time.deltaTime;
                deltaRot.y = Input.GetAxis("Mouse Y") * rotateSpeed * Time.deltaTime;
            }

            float wheel = Input.GetAxis("Mouse ScrollWheel");
            if (Mathf.Abs(wheel) > 1e-5f)
                zoomScale = Mathf.Exp(-wheel * zoomSpeed);
        }
        // ---------- 触摸 ----------
        else if (Input.touchCount == 1) // 单指拖动旋转
        {
            Touch t = Input.GetTouch(0);
            if (t.phase == TouchPhase.Moved)
            {
                deltaRot.x = t.deltaPosition.x * rotateSpeed * Time.deltaTime * 0.1f;
                deltaRot.y = t.deltaPosition.y * rotateSpeed * Time.deltaTime * 0.1f;
            }
        }
        else if (Input.touchCount >= 2) // 双指捏合缩放
        {
            Touch t0 = Input.GetTouch(0);
            Touch t1 = Input.GetTouch(1);

            float prevDist = (t0.position - t0.deltaPosition - (t1.position - t1.deltaPosition)).magnitude;
            float currDist = (t0.position - t1.position).magnitude;
            float pinchDelta = currDist - prevDist;

            zoomScale = Mathf.Exp(-pinchDelta * pinchFactor);
        }
    }
    #endregion

    #region Apply & Update
    /// <summary>把统一输入作用到状态（角度、距离），并负责 Clamp。</summary>
    void ApplyInput(Vector2 deltaRot, float zoomScale)
    {
        yaw   += deltaRot.x;
        pitch += deltaRot.y;
        distance *= zoomScale;

        pitch    = Mathf.Clamp(pitch,   minPitch,   maxPitch);
        distance = Mathf.Clamp(distance, minDistance, maxDistance);
    }

    void UpdateTransform()
    {
        Quaternion rot = Quaternion.Euler(pitch, yaw, 0);
        Vector3 offset = rot * Vector3.forward * distance;

        camera.transform.position = target.position + new Vector3(0, Y, 0) + offset;
        //camera.transform.rotation = rot;
    }
    #endregion

    #region Helpers
    bool ValidateTarget()
    {
        if (target != null) return true;
        Debug.LogWarning($"{nameof(OrbitCamera)}: 请在 Inspector 中指定 Target。");
        enabled = false;
        return false;
    }
    #endregion
}
