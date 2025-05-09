Shader "Custom/DepthColorAlign"
{
    Properties
    {
        _DepthTex("Depth Texture", 2D) = "white" {}
        _ColorTex("Color Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _DepthTex;
            sampler2D _ColorTex;

            float _DepthFx, _DepthFy, _DepthCx, _DepthCy;
            float _ColorFx, _ColorFy, _ColorCx, _ColorCy;

            float4 _DepthTexSize, _ColorTexSize;
            float _DepthDistCoeffs[5];
            float _ColorDistCoeffs[5];

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // 畸变校正函数
            float2 UndistortUV(float2 uv, float fx, float fy, float cx, float cy, float4 texSize, float distCoeffs[5])
            {
                // 将UV坐标转换到归一化相机坐标
                float x = (uv.x * texSize.x - cx) / fx;
                float y = (uv.y * texSize.y - cy) / fy;

                // 计算径向畸变
                float r2 = x * x + y * y;
                float radial = 1.0 + distCoeffs[0] * r2 + distCoeffs[1] * r2 * r2 + distCoeffs[4] * r2 * r2 * r2;

                // 计算切向畸变
                float x_corrected = x * radial + 2.0 * distCoeffs[2] * x * y + distCoeffs[3] * (r2 + 2.0 * x * x);
                float y_corrected = y * radial + 2.0 * distCoeffs[3] * x * y + distCoeffs[2] * (r2 + 2.0 * y * y);

                // 映射回UV空间
                return float2(x_corrected * fx + cx, y_corrected * fy + cy) / texSize.xy;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 校正深度图UV
                float2 depthUV = UndistortUV(i.uv, _DepthFx, _DepthFy, _DepthCx, _DepthCy, _DepthTexSize, _DepthDistCoeffs);
                float4 depthColor = tex2D(_DepthTex, saturate(depthUV));

                // 校正Color图UV
                float2 colorUV = UndistortUV(i.uv, _ColorFx, _ColorFy, _ColorCx, _ColorCy, _ColorTexSize, _ColorDistCoeffs);
                float4 colorValue = tex2D(_ColorTex, saturate(colorUV));

                // 混合深度图和Color图（50%透明度）
                return lerp(depthColor, colorValue, 0.5);
            }
            ENDCG
        }
    }
}
