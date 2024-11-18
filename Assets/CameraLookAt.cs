using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraLookAt : MonoBehaviour
{
    public Transform Target;

    // Update is called once per frame
    void LateUpdate()
    {
        Vector3 target = Target.position;
        target.y = transform.position.y;
        transform.LookAt(target);
    }
}
