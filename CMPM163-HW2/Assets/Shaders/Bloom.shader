Shader "Custom/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseTex ("Texture", 2D) = "white" {}
        _Steps ("Steps", Float) = 3
        
    }
    SubShader
    {
        //Bright pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            uniform float4 _MainTex_TexelSize; //special value
          
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D( _MainTex, i.uv).rgb;
                //Find Luminance
                float brightness = dot(col, float3(.2126, .7152, .0722));

                if (brightness > 1.0)
                    return float4(col, 1.0);
                else
                    return float4(0, 0, 0, 1);
                
            }
            ENDCG
        }
        
        // Blur pass - This is a box blur which affect the performance. Try implementing an efficent blur 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            uniform float4 _MainTex_TexelSize; //special value
            uniform float _Steps;
            
            sampler2D _MainTex;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                float2 texel = float2(
                    _MainTex_TexelSize.x, 
                    _MainTex_TexelSize.y 
                );
        
        
                float3 avg = 0.0;
        
                int steps = ((int)_Steps) * 2 + 1;
                if (steps < 0) {
                    avg = tex2D( _MainTex, i.uv).rgb;
                } else {
        
                int x, y;
        
                for ( x = -steps/2; x <=steps/2 ; x++) {
                    for (int y = -steps/2; y <= steps/2; y++) {
                        avg += tex2D( _MainTex, i.uv + texel * float2( x, y ) ).rgb;
                    }
                }
        
                avg /= steps * steps;
            }             
        
            return float4(avg, 1.0);
               
            }
            ENDCG
        }
        
        //Combine pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            
            sampler2D _MainTex;
            sampler2D _BaseTex;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                //Combine _MainTex color and _BaseTex color
                float4 main = tex2D(_MainTex, i.uv);
                float4 blur = tex2D(_BaseTex, i.uv);
                return blur + main;
            }
            ENDCG
        }
    }
}
