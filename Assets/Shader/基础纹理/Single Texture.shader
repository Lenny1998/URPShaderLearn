Shader "URP/Single Texture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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
        float4 _Color;
        float4 _MainTex_ST;
        float4 _Specular;
        float _Gloss;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        // TEXTURE2D(_NormalTex);
        SAMPLER(sampler_MainTex);
        // SAMPLER(sampler_NormalTex);

        struct a2v
        {
            float3 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float2 texcoord:TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 normalWS:TEXCOORD0;
            float3 positionWS:TEXCOORD1;
            float2 uv:TEXCOORD2;
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

            v2f vert(a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            real4 frag(v2f i):SV_TARGET
            {
                float3 normalWS = normalize(i.normalWS);
                Light light = GetMainLight();
                float3 worldLightDir = normalize(light.direction);

                float3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                float3 diffuse = light.color.rgb * albedo * max(0, dot(normalWS, worldLightDir));

                float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
                float3 halfDir = normalize(worldLightDir + viewDir);
                float3 specular = light.color.rgb * _Specular.rgb * pow(max(0, dot(normalWS, halfDir)), _Gloss);

                return float4(ambient + diffuse + specular, 1.0);
            }
            ENDHLSL
        }
    }
}