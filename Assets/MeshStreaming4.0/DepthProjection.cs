using UnityEngine;

[ExecuteInEditMode]
public class DepthReprojection : MonoBehaviour
{
    [Header("Inputs:")]
    public Camera inputCamera1;       // 输入相机1（提供深度图）
    public RenderTexture inputDepth1; // 输入深度图1（需确保配置正确）
    
    public Camera inputCamera2;       // 输入相机2（提供深度图）
    public RenderTexture inputDepth2; // 输入深度图2（需确保配置正确）
    
    public Camera outputCamera;      // 输出相机（用于重投影）
    
    [Header("Output:")]
    public RenderTexture resultDepth; // 输出重投影结果，请手动挂引用
    
    
    [Header("Parameters:")]
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
    [Range(0,10)]
    public int blurIterations = 1;

    public void Update()
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
        depthReprojectionShader.SetInt("inputWidth",     inputDepth1.width);
        depthReprojectionShader.SetInt("inputHeight",    inputDepth1.height);
        depthReprojectionShader.SetInt("outputWidth",    resultDepth.width);
        depthReprojectionShader.SetInt("outputHeight",   resultDepth.height);
        
        // 传递 Inspector 可调的输出颜色
        depthReprojectionShader.SetVector("outputColor", outputColor);
        
        // 传递 splat 半径
        depthReprojectionShader.SetInt("splatRadius", splatRadius);
        
        // 分配线程组（假设每组 16×16 像素）
        int threadGroupsX = Mathf.CeilToInt(inputDepth1.width / 16f);
        int threadGroupsY = Mathf.CeilToInt(inputDepth1.height / 16f);
        
        // 1) 主投影 pass（沿用你原来的 kernelHandle）
        depthReprojectionShader.Dispatch(kernelHandle, threadGroupsX, threadGroupsY, 1);
        
        // 2) blur pass
        for (int i = 0; i < blurIterations; i++)
        {
            int blurKernel = depthReprojectionShader.FindKernel("CSSmooth");
            RenderTexture tmp =
                RenderTexture.GetTemporary(resultDepth.width, resultDepth.height, 0, resultDepth.format);
            Graphics.Blit(resultDepth, tmp); // GPU-side copy
            depthReprojectionShader.SetTexture(blurKernel, "ResultSrc", tmp); // t2
            depthReprojectionShader.SetTexture(blurKernel, "Result", resultDepth); // u0
            depthReprojectionShader.Dispatch(blurKernel, Mathf.CeilToInt(resultDepth.width / 16f),
                Mathf.CeilToInt(resultDepth.height / 16f), 1);
            RenderTexture.ReleaseTemporary(tmp);
        }
    }
}

#if UNITY_EDITOR
[UnityEditor.CustomEditor(typeof(DepthReprojection))]
public class DepthReprojectionEditor : UnityEditor.Editor
{
    public override void OnInspectorGUI()
    {
        // info box
        string description = "将两张输入图投影成新视角的深度图像\n" +
                             "输入：两张深度图和他们的位置旋转 + 输出相机的位置旋转\n" +
                             "输出：一张深度图\n" +
                             "注意：因为原理类似于点云渲染，所以输入深度图的像素在输出图上泼溅为一个有半径的点";
        UnityEditor.EditorGUILayout.HelpBox(description, UnityEditor.MessageType.None);
        
        base.OnInspectorGUI();
        
        serializedObject.Update();
        
        UnityEditor.EditorGUILayout.Separator();
        if (GUILayout.Button("Update"))
        {
            ((DepthReprojection)target).Update();
        }
        
        serializedObject.ApplyModifiedProperties();
    }
}
#endif
