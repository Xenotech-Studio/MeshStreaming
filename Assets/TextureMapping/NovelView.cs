using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class NovelView : MonoBehaviour
{
    public bool Execute = false;
    
    public List<Material> TextureMappingMaterial;

    public Camera[] Cameras;

    public Transform OutputOrigin;

    public Material[] NeedOutCamPoseMaterials;
    public Camera OutCam;

    // Update is called once per frame
    void Update()
    {
        if (!Execute) return;
        
        foreach (var material in TextureMappingMaterial)
        {
            for (int i = 0; i < Cameras.Length; i++)
            {
                material.SetVector("_Camera"+(i+1)+"Position", Cameras[i].transform.position);
                material.SetVector("_Camera"+(i+1)+"Rotation", Cameras[i].transform.rotation.eulerAngles);
            }
        
            material.SetVector("_PositionOffset", OutputOrigin.position);
        }

        foreach (var needOutCamPoseMaterial in NeedOutCamPoseMaterials)
        {
            needOutCamPoseMaterial.SetVector("_CamOutPosition", OutCam.transform.position);
            needOutCamPoseMaterial.SetVector("_CamOutRotation", OutCam.transform.rotation.eulerAngles);
        }
    }
}
