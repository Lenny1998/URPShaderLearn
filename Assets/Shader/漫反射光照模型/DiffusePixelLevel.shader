//逐像素光照
Shader "URP/Diffuse Pixel-Level"
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
            float3 normalCS:TEXCOORD0;
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
                o.normalCS = TransformObjectToWorldNormal(v.normalOS);

                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float3 worldNormal = TransformObjectToWorldNormal(i.normalCS);
                Light mainLight = GetMainLight();
                float3 worldLight = normalize(mainLight.direction);
                float3 diffuse = mainLight.color * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                float3 color = ambient + diffuse;
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}