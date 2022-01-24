//逐顶点光照
Shader "URP/Specular Vertex-Level"
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
                float3 worldLightDir = normalize(mainLight.direction);
                float3 diffuse = mainLight.color * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                float3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.positionOS).xyz);

                float3 specular = mainLight.color.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                o.color = ambient + diffuse + specular;
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