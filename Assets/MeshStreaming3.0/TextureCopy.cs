using UnityEngine;

public class TextureCopy : MonoBehaviour
{
    public ComputeShader copyShader;
    public RenderTexture sourceTexture;
    public RenderTexture resultTexture;

    public Material Output;
    
    void Start()
    {
        int kernelHandle = copyShader.FindKernel("CSMain");

        copyShader.SetTexture(kernelHandle, "Source", sourceTexture);
        copyShader.SetTexture(kernelHandle, "Result", resultTexture);

        // Dispatch the shader
        copyShader.Dispatch(kernelHandle, sourceTexture.width / 8, sourceTexture.height / 8, 1);
    }
}