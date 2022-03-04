Shader "URP/SimpleGrid"
{
    Properties
    {
        _MyArr ("Tex", 2DArray) = "" {}
        _MainTex ("Main Tex", 2D) = "white" {}
        _LineColor ("Line Color", Color) = (1,1,1,1)
        _CellColor ("Cell Color", Color) = (0,0,0,0)
        _SelectedColor ("Selected Color", Color) = (1,0,0,1)
        [IntRange] _GridSize("Grid Size", Range(1,100)) = 10
        _LineSize("Line Size", Range(0,1)) = 0.15
        [IntRange] _SelectCell("Select Cell Toggle ( 0 = False , 1 = True )", Range(0,1)) = 0.0
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
        float4 _LineColor;
        float4 _CellColor;
        float4 _SelectedColor;
        float _GridSize;
        float _LineSize;
        float _SelectCell;
        float _SelectCell1;
        float _SelectCell2;
        float2 _SelectCelltest;

        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 texcoord : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
            float2 uv : TEXCOORD2;
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

            void SetSelectGrid(float2 uv, float test[4][2])
            {
                float2 id;
                float2 id2;
                float2 id3;
                float2 id4;

                float gsize = floor(_GridSize);

                id.x = floor(uv.x / (1.0 / gsize));
                id.y = floor(uv.y / (1.0 / gsize));

                id2.x = floor(uv.x / (1.0 / gsize));
                id2.y = floor(uv.y / (1.0 / gsize));

                id3.x = floor(uv.x / (1.0 / gsize));
                id3.y = floor(uv.y / (1.0 / gsize));

                id4.x = floor(uv.x / (1.0 / gsize));
                id4.y = floor(uv.y / (1.0 / gsize));

                if (round(_SelectCell) == 1.0 && id.x == test[0][0] && id.y == test[0][1])
                {
                    _CellColor.w = _SelectedColor.w;
                    _CellColor = _SelectedColor;
                }

                if (round(_SelectCell) == 1.0 && id2.x == test[1][0] && id2.y == test[1][1])
                {
                    _CellColor.w = _SelectedColor.w;
                    _CellColor = _SelectedColor;
                }

                if (round(_SelectCell) == 1.0 && id3.x == test[2][0] && id3.y == test[2][1])
                {
                    _CellColor.w = _SelectedColor.w;
                    _CellColor = _SelectedColor;
                }

                if (round(_SelectCell) == 1.0 && id4.x == test[3][0] && id4.y == test[3][1])
                {
                    _CellColor.w = _SelectedColor.w;
                    _CellColor = _SelectedColor;
                }
            }

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float test[4][2] = {{_SelectCelltest[0], _SelectCelltest[1]}, {6.0, 2.0}, {1.0, 4.0}, {1.0, 5.0}};

                float gsize = floor(_GridSize);
                gsize += _LineSize;

                SetSelectGrid(uv, test);

                if (frac(uv.x * gsize) <= _LineSize || frac(uv.y * gsize) <= _LineSize)
                {
                    _CellColor.w = _LineColor.w;
                    _CellColor = _LineColor;
                }

                return float4(_CellColor.x * _CellColor.w, _CellColor.y * _CellColor.w, _CellColor.z * _CellColor.w, _CellColor.w);
            }
            ENDHLSL
        }

    }
}