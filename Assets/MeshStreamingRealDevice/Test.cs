using System.Collections;
using System.Collections.Generic;
using com.rfilkov.kinect;
using UnityEngine;

public class Test : MonoBehaviour
{
    public KinectManager KinectManager;

    // Update is called once per frame
    void Update()
    {
        KinectInterop.SensorData sensorData =  KinectManager.GetSensorData(0);
        
        Debug.Log(sensorData.colorImageTexture==null?"null":"not null");
    }
}
