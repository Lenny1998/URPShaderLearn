// 渐变纹理
//核心思想是在对贴图进行采样时，不使用的常规的模型的uv采样，而是对Dot（N,L)进行采样，
//由于我们使用的ramp图是水平渐变的，故采样的u轴即为Dot（N,L)，而v轴为常数，一般取0.5，即ramp图的中间水平线。 
Shader "URP/RAMP"
{
    Properties
    {
        _MainTex ("RAMP", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        CBUFFER_END

        sampler2D _MainTex;

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 normalWS:NORMAL;
        };
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS));
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                real3 lightdir = normalize(GetMainLight().direction);
                float dott = dot(i.normalWS, lightdir) * 0.5 + 0.5;
                half4 tex = tex2D(_MainTex, float2(dott, 0.5)) * _BaseColor;
                return tex;
            }
            ENDHLSL
        }
    }
}