using com.rfilkov.kinect;
using UnityEngine;

public class DualImageCorrection : MonoBehaviour
{
    public KinectManager kinectManager; // KinectManager
    
    public KinectInterop.CameraIntrinsics depthCamIntr; // 深度相机内参
    public KinectInterop.CameraIntrinsics colorCamIntr; // Color相机内参

    private RenderTexture depthTexture; // 深度图
    private Texture colorTexture; // RGB图

    public Material correctionMaterial; // 自定义Shader材质

    public bool UpdateParams = true;

    private void Update()
    {
        KinectInterop.SensorData sensorData =  kinectManager.GetSensorData(0);

        if (UpdateParams)
        {
            depthCamIntr = sensorData.depthCamIntr;
            colorCamIntr = sensorData.colorCamIntr;
        }

        depthTexture = sensorData.depthImageTexture;
        colorTexture = sensorData.colorImageTexture;
        
        // 将深度和Color图的内参、畸变参数传递到Shader
        correctionMaterial.SetTexture("_DepthTex", depthTexture);
        correctionMaterial.SetTexture("_ColorTex", colorTexture);

        // 深度相机参数
        correctionMaterial.SetFloat("_DepthFx", depthCamIntr.fx);
        correctionMaterial.SetFloat("_DepthFy", depthCamIntr.fy);
        correctionMaterial.SetFloat("_DepthCx", depthCamIntr.ppx);
        correctionMaterial.SetFloat("_DepthCy", depthCamIntr.ppy);
        correctionMaterial.SetFloatArray("_DepthDistCoeffs", depthCamIntr.distCoeffs);
        correctionMaterial.SetVector("_DepthTexSize", new Vector2(depthCamIntr.width, depthCamIntr.height));

        // Color相机参数
        correctionMaterial.SetFloat("_ColorFx", colorCamIntr.fx);
        correctionMaterial.SetFloat("_ColorFy", colorCamIntr.fy);
        correctionMaterial.SetFloat("_ColorCx", colorCamIntr.ppx);
        correctionMaterial.SetFloat("_ColorCy", colorCamIntr.ppy);
        correctionMaterial.SetFloatArray("_ColorDistCoeffs", colorCamIntr.distCoeffs);
        correctionMaterial.SetVector("_ColorTexSize", new Vector2(colorCamIntr.width, colorCamIntr.height));
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // 执行Shader，处理校正和混合
        Graphics.Blit(src, dest, correctionMaterial);
    }
}