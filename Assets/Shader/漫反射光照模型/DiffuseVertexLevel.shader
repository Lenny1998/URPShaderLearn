//逐顶点光照
Shader "URP/Diffuse Vertex-Level"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _Diffuse;
        CBUFFER_END

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 color:COLOR;
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

            v2f VERT(a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS, true);
                Light mainLight = GetMainLight();
                float3 worldLight = normalize(mainLight.direction);
                float3 diffuse = mainLight.color * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                o.color = ambient + diffuse;
                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                return float4(i.color, 1.0);
            }
            ENDHLSL
        }
    }
}