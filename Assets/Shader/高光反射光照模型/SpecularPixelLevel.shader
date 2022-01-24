//逐像素光照
Shader "URP/Specular Pixel-Level"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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
        float4 _Specular;
        float _Gloss;
        CBUFFER_END

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 worldNormal:TEXCOORD0;
            float3 worldPos:TEXCOORD1;
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
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.worldPos = TransformObjectToWorld(v.positionOS);

                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                float3 worldNormal = normalize(i.worldNormal);
                Light mainLight = GetMainLight();
                float3 worldLightDir = normalize(mainLight.direction);

                float3 diffuse = mainLight.color * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                float3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                float3 specular = mainLight.color.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                return float4(ambient + diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
}