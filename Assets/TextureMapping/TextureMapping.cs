using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TextureMapping : MonoBehaviour
{
    public bool Execute = false;
    
    public Material TextureMappingMaterial;

    public Camera[] Cameras;

    public Transform OutputOrigin;

    // Update is called once per frame
    void Update()
    {
        if (!Execute) return;

        for (int i = 0; i < Cameras.Length; i++)
        {
            TextureMappingMaterial.SetVector("_Camera"+(i+1)+"Position", Cameras[i].transform.position);
            TextureMappingMaterial.SetVector("_Camera"+(i+1)+"Rotation", Cameras[i].transform.rotation.eulerAngles);
        }

        TextureMappingMaterial.SetFloat("_ClippingDepth", -Cameras[0].transform.position.z);
        
        
        TextureMappingMaterial.SetVector("_PositionOffset", OutputOrigin.position);
    }
}
