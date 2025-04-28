using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraLookAt : MonoBehaviour
{
    public Transform Target;
    public float Y = 1.5f;

    // Update is called once per frame
    void LateUpdate()
    {
        Vector3 target = Target.position;
        target.y = Y;
        transform.LookAt(target);
    }
}
