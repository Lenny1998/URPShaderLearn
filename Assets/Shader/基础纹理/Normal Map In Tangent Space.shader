Shader "URP/Normal Map In Tangent Space"
{
    Properties
    {
        _Color("Color Tint",Color)=(1,1,1,1)
        _MainTex("Main Tex",2D)="white"{}
        _BumpMap("Normal Map", 2D) = "bump"{}
        _BumpScale("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss",Range(8.0,256)) = 20
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BumpMap_ST;
        float4 _MainTex_ST;
        real4 _Color;
        real _BumpScale;
        real _Gloss;
        real4 _Specular;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        TEXTURE2D(_BumpMap);
        SAMPLER(sampler_MainTex);
        SAMPLER(sampler_BumpMap);

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float4 tangentOS:TANGENT;
            float2 texcoord:TEXCOORD0;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float4 uv:TEXCOORD0;
            float3 lightDir:TEXCOORD1;
            float3 viewDir:TEXCOORD2;
        };
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                float3 binormal = cross(normalize(v.normalOS), normalize(v.tangentOS.xyz)) * v.tangentOS.w;
                float3x3 rotation = float3x3(v.tangentOS.xyz, binormal, v.normalOS);

                Light light = GetMainLight();
                o.lightDir = mul(rotation, light.direction);
                o.viewDir = mul(rotation, normalize(TransformWorldToObject(_WorldSpaceCameraPos) - v.positionOS.xyz));
                return o;
            }

            real4 frag(v2f i):SV_TARGET
            {
                float3 tangentLightDir = normalize(i.lightDir);
                float3 tangentViewDir = normalize(i.viewDir);

                // Get the texel in the normal map
                float4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv.zw);
                float3 tangentNormal;
                // If the texture is not marked as "Normal map"
                //				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                //				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // Or mark the texture as "Normal map", and use the built-in funciton
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                float3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                Light light = GetMainLight();

                float3 diffuse = light.color.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                float3 halfDir = normalize(tangentLightDir + tangentViewDir);
                float3 specular = light.color.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return float4(ambient + diffuse + specular, 1.0);
            }
            ENDHLSL

        }
    }
}