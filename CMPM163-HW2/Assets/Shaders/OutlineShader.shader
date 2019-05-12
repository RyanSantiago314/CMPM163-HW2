Shader "Custom/OutlineShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Outline ("Outline", Float) = 0
    }
    SubShader
    {

        Pass
        {
            Cull Front

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Outline;

            struct appdata
            {
                float4 position: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };
            struct v2f
            {
                float4 position: SV_POSITION;
                float2 uv: TEXCOORD0;
            };

            sampler _MainTex;

            v2f vert(appdata v)
            {
                v2f o;
                v.position += float4(v.normal, 1.0) * _Outline;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                return o;            
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                float4 c = tex2D(_MainTex, i.uv);
                return float4(0, 0, 0, 0);
            }



            ENDCG
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 position: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };
            struct v2f
            {
                float4 position: SV_POSITION;
                float2 uv: TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i): SV_TARGET
            {
                return float4(1, 1, 1, 1);
            }

            ENDCG
        }
    }
}
