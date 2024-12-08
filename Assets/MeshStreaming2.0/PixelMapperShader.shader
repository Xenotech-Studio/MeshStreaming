Shader "Custom/PixelMapperURPShader"
{
    Properties
    {
        _SourceTexture("Source Texture", 2D) = "white" {}
        _ResultTexture("Result Texture", 2D) = "white" {}
        _Cam1F("Camera1 Focal Length", Float) = 1.0
        _OutF("Out Camera Focal Length", Float) = 1.0

        _Cam1R("Camera1 Rotation", Float) = (1.0, 0.0, 0.0, 0.0)
        _Cam1T("Camera1 Translation", Vector) = (0, 0, 0)
        _OutR("Out Camera Rotation", Float) = (1.0, 0.0, 0.0, 0.0)
        _OutT("Out Camera Translation", Vector) = (0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Name"FORWARD"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma target 4.5
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // A 图像和 B 图像的纹理
            sampler2D _SourceTexture;
            sampler2D _ResultTexture;

            // 相机内参和转换矩阵
            float _Cam1F;
            float _OutF;
            float4 _Cam1R;
            float3 _Cam1T;
            float4 _OutR;
            float3 _OutT;

            // 定义输入的结构体
            struct Attributes
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            // 顶点着色器
            Attributes vert(float4 vertex : POSITION, float2 uv : TEXCOORD0)
            {
                Attributes output;
                output.position = vertex;
                output.uv = uv;
                return output;
            }

            // 定义传递给片段着色器的数据结构
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 position : SV_POSITION;
            };

            // 顶点着色器输出到片段着色器
            Varyings vertToFrag(Attributes v)
            {
                Varyings o;
                o.position = v.position;
                o.uv = v.uv;
                return o;
            }

            // 获取 UV 坐标并进行像素映射的片段着色器
            float4 frag(Varyings i) : SV_Target
            {
                // 获取 A 图像中的颜色（深度）
                float4 color = tex2D(_SourceTexture, i.uv);
                float depth = 0.298 / color.r; // 假设颜色值表示深度

                // 将 A 图像的 UV 坐标标准化到 [-0.5, 0.5] 范围
                float2 uvA_normalized = (i.uv * 2.0) - 1.0;

                // 根据深度值和 UV 坐标计算相机坐标
                float3 cameraPosA = float3(depth * uvA_normalized.x / _Cam1F, 
                                           depth * uvA_normalized.y / _Cam1F, 
                                           depth);

                // 将 A 图像坐标系的点转换到世界坐标系
                float3 worldPos = mul(_Cam1R, cameraPosA) + _Cam1T;

                // 将世界坐标转换到输出相机坐标系
                float3 outCameraPos = mul(_OutR, worldPos - _OutT);

                // 计算 B 图像的 UV 坐标
                float2 uvB = (outCameraPos.xy / outCameraPos.z) * _OutF + 0.5;

                // 确保 UV 坐标在 [0, 1] 范围内
                uvB = clamp(uvB, 0.0, 1.0);

                // 获取 B 图像中的颜色
                float4 resultColor = tex2D(_ResultTexture, uvB);

                // 使用最小值更新 B 图像的像素
                resultColor.rgb = min(resultColor.rgb, color.rgb);

                // 返回最终的颜色值
                return resultColor;
            }

            ENDHLSL
        }
    }

    Fallback "Diffuse"
}
