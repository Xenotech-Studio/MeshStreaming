using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UseDepthToRedShader : MonoBehaviour
{
    public ComputeShader depthToRedShader; // 你创建的 Compute Shader
    public RenderTexture depthTexture; // 输入的深度图
    public RenderTexture resultTexture; // 输出的渲染纹理

    void Start()
    {
        // 创建一个与输入深度图相同尺寸的输出渲染纹理
        resultTexture = new RenderTexture(depthTexture.width, depthTexture.height, 0, RenderTextureFormat.ARGB32);
        resultTexture.enableRandomWrite = true;
        resultTexture.Create();
    }

    void Update()
    {
        // 设置计算着色器的输入和输出
        int kernelHandle = depthToRedShader.FindKernel("CSMain");

        depthToRedShader.SetTexture(kernelHandle, "depthTexture", depthTexture);
        depthToRedShader.SetTexture(kernelHandle, "Result", resultTexture);


        // 调用计算着色器
        int threadGroupsX = Mathf.CeilToInt(depthTexture.width / 16f);
        int threadGroupsY = Mathf.CeilToInt(depthTexture.height / 16f);
        depthToRedShader.Dispatch(kernelHandle, threadGroupsX, threadGroupsY, 1);
    }
}
