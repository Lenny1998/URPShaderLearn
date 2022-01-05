Shader "URP/ShadowCaster"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(10, 300)) = 50
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        [KeywordEnum(ON,OFF)]_CUT ("CUT",float) = 1
        _Cutoff ("Cutoff", Range(0,1)) = 1
        [KeywordEnum(ON,OFF)]_ADD_LIGHT("AddLight", float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        #pragma shader_feature_local _CUT_ON
        #pragma shader_feature_local _ADD_LIGHT_ON

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Cutoff;
        float _Gloss;
        real4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float4 normalOS:NORMAL;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
            #ifdef _MAIN_LIGHT_SHADOWS
            float4 shadowcoord:TEXCOORD1;
            #endif
            float3 WS_P:TEXCOORD2;
            float3 WS_N:TEXCOORD4;
            float3 WS_V:TEXCOORD3;
        };
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
                "RenderType" = "TransparentCutout"
                "Queue" = "AlphaTest"
            }

            Cull off

            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX_ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);

                #ifdef _MAIN_LIGHT_SHADOWS
                o.shadowcoord = TransformWorldToShadowCoord(o.WS_P);
                #endif
                o.WS_V = normalize(_WorldSpaceCameraPos - o.WS_P.xyz);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));

                return o;
            }

            real4 FRAG(v2f i):SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * _BaseColor;

                #ifdef _CUT_ON
                clip(tex.a - _Cutoff);
                #endif

                float3 NormalWS = i.WS_N;
                float3 PositionWS = i.WS_P;
                float3 viewDir = i.WS_V;

                #ifdef _MAIN_LIGHT_SHADOWS
                Light mylight = GetMainLight(TransformWorldToShadowCoord(i.shadowcoord));
                #else
                Light mylight = GetMainLight();
                #endif

                half4 MainColor = (dot(normalize(mylight.direction.xyz), NormalWS) * 0.5 + 0.5) * half4(mylight.color, 1);
                MainColor += pow(max(dot(normalize(viewDir + normalize(mylight.direction.xyz)), NormalWS), 0), _Gloss);
                MainColor *= mylight.shadowAttenuation;

                //addLights
                half4 AddColor = half4(0, 0, 0, 1);
                #ifdef _ADD_LIGHT_ON
                int addLightCount = GetAdditionalLightsCount();
                for (int i = 0; i < addLightCount; i++)
                {
                    Light addLight = GetAdditionalLight(i, PositionWS);

                    //额外光直接算半兰伯特
                    AddColor += (dot(normalize(addLight.direction.xyz), NormalWS) * 0.5 + 0.5) * half4(addLight.color, 1) * addLight.shadowAttenuation
                        * addLight.distanceAttenuation;
                }
                #endif

                return tex * (MainColor + AddColor);
            }
            ENDHLSL
        }

        pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            HLSLPROGRAM
            #pragma vertex vertshadow
            #pragma fragment fragshadow

            v2f vertshadow(a2v i)
            {
                v2f o;
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);
                float3 WS_P = TransformObjectToWorld(i.positionOS.xyz);
                Light mainLight = GetMainLight();
                float3 WS_N = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.positionCS = TransformWorldToHClip(ApplyShadowBias(WS_P, WS_N, mainLight.direction));

                #if UNITY_REVERSED_Z
                o.positionCS.z = min(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                o.positionCS.z = max(o.positionCS.z,o.positionCS.w*UNITY_NEAR_CLIP_VALUE);
                #endif

                return o;
            }

            half4 fragshadow(v2f i):SV_TARGET
            {
                #ifdef _CUT_ON
                float alpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).a;
                clip(alpha - _Cutoff);
                #endif

                return 0;
            }
            ENDHLSL
        }
    }
}