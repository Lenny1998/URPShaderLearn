//广告牌
Shader "URP/Billboard"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Color ("BaseColor", Color) = (1, 1, 1, 1)
        _Rotate("Rotate",Range(0,3.14))=0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Rotate;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };
        ENDHLSL

        pass
        {

            Tags
            {
                "LightMode"="UniversalForward"
            }

            ZWrite off
            ZTest always

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG

            #pragma shader_feature_local _Z_STAGE_LOCK_Z

            v2f VERT(a2v i)
            {
                v2f o;
                o.texcoord = TRANSFORM_TEX(i.texcoord, _MainTex);

                float4 pivotWS = mul(UNITY_MATRIX_M, float4(0, 0, 0, 1));
                float4 pivotVS = mul(UNITY_MATRIX_V, pivotWS);

                float ScaleX = length(float3(UNITY_MATRIX_M[0].x,UNITY_MATRIX_M[1].x,UNITY_MATRIX_M[2].x));
                float ScaleY = length(float3(UNITY_MATRIX_M[0].y,UNITY_MATRIX_M[1].y,UNITY_MATRIX_M[2].y));

                //float ScaleZ=length(float3(UNITY_MATRIX_M[0].z,UNITY_MATRIX_M[1].z,UNITY_MATRIX_M[2].z));//暂时不用上
                //定义一个旋转矩阵
                float2x2 rotateMatrix = {cos(_Rotate), -sin(_Rotate), sin(_Rotate), cos(_Rotate)};

                //用来临时存放旋转后的坐标
                float2 pos = i.positionOS.xy * float2(ScaleX, ScaleY);
                pos = mul(rotateMatrix, pos);
                float4 positionVS = pivotVS + float4(pos, 0, 1); //深度取的轴心位置深度，xy进行缩放

                o.positionCS = mul(UNITY_MATRIX_P, positionVS);

                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                return c;
            }
            ENDHLSL
        }
    }
}