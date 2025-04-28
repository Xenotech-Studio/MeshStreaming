using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthToRenderOptions : MonoBehaviour
{
    public Material depthToRenderMaterial;
    
    public bool ShowDepthOnly
    {
        get => depthToRenderMaterial.GetFloat("_ShowDepthOnly") == 1;
        set => depthToRenderMaterial.SetFloat("_ShowDepthOnly", value ? 1 : 0);
    }
    
    public bool ShowNormalOnly
    {
        get => depthToRenderMaterial.GetInt("_ShowNormalOnly") == 1;
        set => depthToRenderMaterial.SetInt("_ShowNormalOnly", value ? 1 : 0);
    }
}