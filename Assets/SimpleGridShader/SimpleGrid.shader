Shader "URP/SimpleGrid"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _LineColor ("Line Color", Color) = (1,1,1,1)
        _CellColor ("Cell Color", Color) = (0,0,0,0)
        _SelectedColor ("Selected Color", Color) = (1,0,0,1)
        [IntRange] _GridSize("Grid Size", Range(1,100)) = 10
        _LineSize("Line Size", Range(0,1)) = 0.15
        [IntRange] _SelectCell("Select Cell Toggle ( 0 = False , 1 = True )", Range(0,1)) = 0.0
        [IntRange] _SelectedCellX("Selected Cell X", Range(0,100)) = 0.0
        [IntRange] _SelectedCellY("Selected Cell Y", Range(0,100)) = 0.0
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
        float _SelectedCellX;
        float _SelectedCellY;
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

                _SelectedCellX = floor(_SelectedCellX);
                _SelectedCellY = floor(_SelectedCellY);

                float4 c = float4(0.0, 0.0, 0.0, 0.0);
                float brightness = 1.;

                float gsize = floor(_GridSize);
                gsize += _LineSize;
                float2 id;

                id.x = floor(uv.x / (1.0 / gsize));
                id.y = floor(uv.y / (1.0 / gsize));

                float4 color = _CellColor;
                brightness = _CellColor.w;


                if (round(_SelectCell) == 1.0 && id.x == _SelectedCellX && id.y == _SelectedCellY)
                {
                    brightness = _SelectedColor.w;
                    color = _SelectedColor;
                }

                if (frac(uv.x * gsize) <= _LineSize || frac(uv.y * gsize) <= _LineSize)
                {
                    brightness = _LineColor.w;
                    color = _LineColor;
                }

                if (brightness == 0.0)
                {
                    clip(c.a - 1.0);
                }

                return float4(color.x * brightness, color.y * brightness, color.z * brightness, brightness);
            }
            ENDHLSL
        }

    }
}