using System.Collections;
using System.Collections.Generic;
using com.rfilkov.kinect;
using UnityEngine;

public class Test : MonoBehaviour
{
    public KinectManager KinectManager;
    
    public Material material;
    public Material colorMaterial;

    // Update is called once per frame
    void Update()
    {
        KinectInterop.SensorData sensorData =  KinectManager.GetSensorData(0);
        
        Debug.Log(sensorData.colorDepthTexture==null?"null":"not null");
        
        material.SetTexture("_Texture0", sensorData.depthImageTexture);
        
        colorMaterial.SetTexture("_Texture0", sensorData.colorImageTexture);
        
        Debug.Log("" + sensorData.sensorPosePosition);
    }
}
