using System;
using UnityEngine;

public class PixelMapper : MonoBehaviour
{
    public ComputeShader shader;
    public RenderTexture sourceTexture;
    public RenderTexture resultTexture;

    public Camera cam1;
    public Camera outCam;

    // Camera parameters
    [Range(0, 2)]
    public float cam1F;
    [Range(0, 2)]
    public float outF;

    public Matrix4x4 cam1R;
    public Vector3 cam1T;
    public Matrix4x4 outR;
    public Vector3 outT;

    void Start()
    {
        UpdateCameraTransforms();

        int kernelHandle = shader.FindKernel("CSMain");

        shader.SetTexture(kernelHandle, "Result", resultTexture);
        shader.SetTexture(kernelHandle, "Source", sourceTexture);

        shader.SetFloat("cam1F", cam1F);
        shader.SetFloat("outF", outF);
        shader.SetMatrix("cam1R", cam1R);
        shader.SetVector("cam1T", cam1T);
        shader.SetMatrix("outR", outR);
        shader.SetVector("outT", outT);

        shader.Dispatch(kernelHandle, sourceTexture.width / 8, sourceTexture.height / 8, 1);
    }

    private void Update()
    {
        UpdateCameraTransforms();
    }

    private void UpdateCameraTransforms()
    {
        cam1R = Matrix4x4.Rotate(cam1.transform.rotation);
        outR = Matrix4x4.Rotate(outCam.transform.rotation);
        cam1T = cam1.transform.position;
        outT = outCam.transform.position;
    }
}