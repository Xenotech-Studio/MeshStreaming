using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class IkLookAt : MonoBehaviour
{
    private Animator _animator;
    public Animator Animator {
        get
        {
            if(_animator==null) _animator = GetComponent<Animator>();
            return _animator;
        }
    }
    
    public Transform LookAtTarget;
    public float LookAtWeight = 1;
    public float MaxWeight = 0.8f;

    public float SmoothSpped = 2f;
    public float LookAtThreshold = 30f;
    
    public bool ExecuteInEditMode = false;

    public Transform LeftEyeball;
    public Transform RightEyeball;
    public bool GazesAtTarget = true;
    public Transform FaceBase;
    [Range(0, 1)]
    public float GazeFactor = 0.5f;

    public bool DrawDebugLine = true;

    public bool Debug_ShouldLookAt = false;

    private void OnAnimatorIK(int layerIndex)
    {

        Vector3 facingDirection = Animator.rootRotation * Vector3.forward; facingDirection.y = 0;
        Vector3 lookAtDirection = LookAtTarget.position - Animator.rootPosition; lookAtDirection.y = 0;
        
        bool shouldLookAt = Vector3.Angle(facingDirection, lookAtDirection) < LookAtThreshold;
        Debug_ShouldLookAt = shouldLookAt;
        LookAtWeight = Mathf.Lerp(LookAtWeight, shouldLookAt ? MaxWeight : 0, Time.deltaTime * SmoothSpped);
        
        Animator.SetLookAtPosition(LookAtTarget.position + Vector3.down * 0.1f);
        Animator.SetLookAtWeight(LookAtWeight);
    }

    private void LateUpdate()
    {

        Quaternion forward = FaceBase.rotation * Quaternion.Euler(180, 90, 0);
        
        if (GazesAtTarget && GazeFactor>0.01f)
        {
            LeftEyeball.LookAt(LookAtTarget);
            LeftEyeball.Rotate(-90, 180, 180);
            LeftEyeball.rotation = Quaternion.Lerp(LeftEyeball.rotation, forward, 1-GazeFactor);

            RightEyeball.LookAt(LookAtTarget);
            RightEyeball.Rotate(-90, 180, 180);
            RightEyeball.rotation = Quaternion.Lerp(RightEyeball.rotation, forward, 1-GazeFactor);
        }

        if (DrawDebugLine)
        {
            Debug.DrawLine(LeftEyeball.position, LookAtTarget.position, Color.gray);
            Debug.DrawLine(RightEyeball.position, LookAtTarget.position, Color.gray);
            
            Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-LeftEyeball.up) * 0.05f, Color.green);
            Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-LeftEyeball.right) * 0.05f, Color.red);
            Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-LeftEyeball.forward) * 0.05f, Color.blue);

            Debug.DrawLine(RightEyeball.position, RightEyeball.position + (-RightEyeball.up) * 0.05f, Color.green);
            Debug.DrawLine(RightEyeball.position, RightEyeball.position + (-RightEyeball.right) * 0.05f, Color.red);
            Debug.DrawLine(RightEyeball.position, RightEyeball.position + (-RightEyeball.forward) * 0.05f, Color.blue);
        }

        // Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-(forward * Vector3.up)) * 0.05f, Color.green);
        // Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-(forward * Vector3.right)) * 0.05f, Color.red);
        // Debug.DrawLine(LeftEyeball.position, LeftEyeball.position + (-(forward * Vector3.forward)) * 0.05f, Color.blue);
    }
}
