// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "PDT Shaders/SimpleGrid"
{
    Properties
    {
        _LineColor ("Line Color", Color) = (1,1,1,1)
        _CellColor ("Cell Color", Color) = (0,0,0,0)
        _SelectedColor ("Selected Color", Color) = (1,0,0,1)
        [PerRendererData] _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [IntRange] _GridSize("Grid Size", Range(1,100)) = 10
        _LineSize("Line Size", Range(0,1)) = 0.15
        [IntRange] _SelectCell("Select Cell Toggle ( 0 = False , 1 = True )", Range(0,1)) = 0.0
        [IntRange] _SelectedCellX("Selected Cell X", Range(0,100)) = 0.0
        [IntRange] _SelectedCellY("Selected Cell Y", Range(0,100)) = 0.0
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "Queue"="AlphaTest" "RenderType"="TransparentCutout"
            }
            LOD 200


            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag
            #include <UnityCG.cginc>
            #include <UnityShaderUtilities.cginc>

            // Use shader model 3.0 target, to get nicer looking lighting
            // #pragma target 3.0

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half _Glossiness = 0.0;
            half _Metallic = 0.0;
            float4 _LineColor;
            float4 _CellColor;
            float4 _SelectedColor;

            float _GridSize;
            float _LineSize;

            float _SelectCell;
            float _SelectedCellX;
            float _SelectedCellY;

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

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                _SelectedCellX = floor(_SelectedCellX);
                _SelectedCellY = floor(_SelectedCellY);

                fixed4 c = float4(0.0, 0.0, 0.0, 0.0);
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

                //Clip transparent spots using alpha cutout
                if (brightness == 0.0)
                {
                    clip(c.a - 1.0);
                }

                return fixed4(color.x * brightness, color.y * brightness, color.z * brightness, brightness);
            }
            ENDCG

        }



    }
    //    FallBack "Diffuse"
}