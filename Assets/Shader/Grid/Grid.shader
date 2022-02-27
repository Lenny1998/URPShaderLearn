Shader "URP/Grid"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        [HDR]_GridColour ("Grid Colour", Color) = (.255,.0,.0,1)
        _GridSize ("Grid Size", Range(0.0001, 1.0)) = 0.1

        //线的粗细
        _GridLineThickness ("Grid Line Thickness", Range(0.00001, 0.010)) = 0.003

        //格子透明度
        _Alpha ("Grid Transparency", Range(0, 1)) = 0.5
        _Intensity ("Emission Intensity", Range(-5,5)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _GridColour;
        float _GridSize;
        float _GridLineThickness;
        float _Alpha;
        float _Intensity;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct appdata
        {
            float4 vertex:POSITION;
            float2 uv:TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float GridTest(float2 r)
            {
                float result;

                for (float i = 0.0; i <= 100; i += _GridSize)
                {
                    for (int j = 0; j < 2; j++)
                    {
                        result += 1.0 - smoothstep(0.0, _GridLineThickness, abs(r[j] - i));
                    }
                }

                return result;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 gridColour = (_GridColour * GridTest(i.uv)) + SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                gridColour = float4(gridColour.r, gridColour.g, gridColour.b, _Alpha);
                return float4(gridColour);
            }
            ENDHLSL
        }
    }
}