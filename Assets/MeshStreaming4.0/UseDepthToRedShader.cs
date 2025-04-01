using UnityEngine;

[ExecuteInEditMode]
public class UseDepthReprojectionShader : MonoBehaviour
{
    public Camera inputCamera1;       // 输入相机1（提供深度图）
    public RenderTexture inputDepth1; // 输入深度图1（需确保配置正确）
    
    public Camera inputCamera2;       // 输入相机2（提供深度图）
    public RenderTexture inputDepth2; // 输入深度图2（需确保配置正确）
    
    public Camera outputCamera;      // 输出相机（用于重投影）
    public RenderTexture resultDepth; // 输出重投影结果，请手动挂引用
    public ComputeShader depthReprojectionShader;
    
    // Inspector 中可调的焦距系数，范围 0.8 ~ 2
    [Range(0.8f, 2f)]
    public float fovInput1 = 1.5f;
    [Range(0.8f, 2f)]
    public float fovOutput = 1.2f;
    
    // Inspector 中可调的输出颜色
    public Color outputColor = Color.red;
    
    // Splat 半径（默认值 3）
    public int splatRadius = 3;

    void Update()
    {
        // 若未挂引用则退出
        if (resultDepth == null || inputDepth1 == null || inputDepth2 == null)
            return;
        
        // 每帧开始时清空输出 RenderTexture
        RenderTexture.active = resultDepth;
        GL.Clear(true, true, Color.clear);
        RenderTexture.active = null;
        
        // 获取输入与输出相机的位置和旋转（以 Euler 角表示，单位度）
        Vector3 inputCameraPos1 = inputCamera1.transform.position;
        Vector3 inputCameraPos2 = inputCamera2.transform.position;
        Vector3 outputCameraPos = outputCamera.transform.position;
        Vector3 inputCameraRot1 = inputCamera1.transform.rotation.eulerAngles;
        Vector3 inputCameraRot2 = inputCamera2.transform.rotation.eulerAngles;
        Vector3 outputCameraRot = outputCamera.transform.rotation.eulerAngles;
        
        int kernelHandle = depthReprojectionShader.FindKernel("CSMain");
        
        // 绑定输入纹理和输出纹理
        depthReprojectionShader.SetTexture(kernelHandle, "depthTexture1", inputDepth1);
        depthReprojectionShader.SetTexture(kernelHandle, "depthTexture2", inputDepth2);
        depthReprojectionShader.SetTexture(kernelHandle, "Result", resultDepth);
        
        // 传递相机参数
        depthReprojectionShader.SetVector("inputCameraPos1", inputCameraPos1);
        depthReprojectionShader.SetVector("inputCameraPos2", inputCameraPos2);
        depthReprojectionShader.SetVector("outputCameraPos", outputCameraPos);
        depthReprojectionShader.SetVector("inputCameraRotation1", inputCameraRot1);
        depthReprojectionShader.SetVector("inputCameraRotation2", inputCameraRot2);
        depthReprojectionShader.SetVector("outputCameraRotation", outputCameraRot);
        
        // 传递焦距参数
        depthReprojectionShader.SetFloat("fovInput1", fovInput1);
        depthReprojectionShader.SetFloat("fovOutput", fovOutput);
        
        // 传递图像尺寸（整数）
        depthReprojectionShader.SetInt("imageWidth", inputDepth1.width);
        depthReprojectionShader.SetInt("imageHeight", inputDepth1.height);
        
        // 传递 Inspector 可调的输出颜色
        depthReprojectionShader.SetVector("outputColor", outputColor);
        
        // 传递 splat 半径
        depthReprojectionShader.SetInt("splatRadius", splatRadius);
        
        // 分配线程组（假设每组 16×16 像素）
        int threadGroupsX = Mathf.CeilToInt(inputDepth1.width / 16f);
        int threadGroupsY = Mathf.CeilToInt(inputDepth1.height / 16f);
        depthReprojectionShader.Dispatch(kernelHandle, threadGroupsX, threadGroupsY, 1);
    }
}
