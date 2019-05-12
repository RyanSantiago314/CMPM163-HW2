
Shader "Custom/TrueToon"
{
    Properties
    {   
        _Color ("Color", Color) = (1, 1, 1, 1) //The color of our object
        _Shininess ("Shininess", Float) = 32 //Shininess
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1) //Specular highlights color
        _LineColor("Line Color", Color) = (1, 1, 1, 1) //The color of our object
        _Outline("Outline", Float) = 0
        _Emissiveness("Emmissiveness", Range(0,10)) = 0
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
            float4 _LineColor;
            uniform float _Emissiveness;

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
                return _LineColor * _Emissiveness;
            }



            ENDCG
        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" } //Important! In Unity, point lights are calculated in the the ForwardAdd pass
            // Blend One One //Turn on additive blending if you have more than one point light
            Stencil 
            {
                Ref 4
                Comp always
                Pass replace
                ZFail keep
            }
          
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
           
            uniform float4 _LightColor0; //From UnityCG
            uniform float4 _Color; 
            uniform float4 _SpecColor;
            uniform float _Shininess;          
          
            struct appdata
            {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
            };

            struct v2f
            {
                    float4 vertex : SV_POSITION;
                    float3 normalInWorldCoords : NORMAL;       
                    float3 vertexInWorldCoords : TEXCOORD1;
            };

 
           v2f vert(appdata v)
           { 
                v2f o;
                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal in WORLD coords
                o.vertex = UnityObjectToClipPos(v.vertex); 
                
              

                return o;
           }

           fixed4 frag(v2f i) : SV_Target
           {
                
                float3 P = i.vertexInWorldCoords.xyz;
                float3 N = normalize(i.normalInWorldCoords);
                float3 V = normalize(_WorldSpaceCameraPos - P);
                float3 L = normalize(_WorldSpaceLightPos0.xyz - P);
                float3 H = normalize(L + V);
                
                float3 Kd = _Color.rgb; //Color of object
                float3 Ka = UNITY_LIGHTMODEL_AMBIENT.rgb; //Ambient light
                //float3 Ka = float3(0,0,0); //UNITY_LIGHTMODEL_AMBIENT.rgb; //Ambient light
                float3 Ks = _SpecColor.rgb; //Color of specular highlighting
                float3 Kl = _LightColor0.rgb; //Color of light
                
                
                const float A = 0.3; //0.5;
                const float B = 0.6; //1.0;
                const float C = 0.9;
                
                
                //AMBIENT LIGHT 
                float3 ambient = Ka;
                
               
              
                //DIFFUSE LIGHT
                float diffuseVal = max(dot(N, L), 0);
                float lightIntensity = diffuseVal;
                
                
                float stepVal = 0.02;
                
                /*
                //Cel shading
                 if (diffuseVal < A) diffuseVal = A;
                 else if (diffuseVal < B) diffuseVal = B;
                 else if (diffuseVal < C) diffuseVal = C;
                 else diffuseVal = 1.0;
                 lightIntensity = diffuseVal;
                 */
                 
                 
                 
                 //Cel shading with smoothstep (emulating transitions between color values in a 1d texture ramp)
                 
                 
                 
                if (diffuseVal >= 0 && diffuseVal < stepVal) diffuseVal = 0 + A;// *smoothstep(0, stepVal, diffuseVal);
                 else if (diffuseVal < A) diffuseVal = A;
                 else if (diffuseVal >= A && diffuseVal < A + stepVal) diffuseVal = A + (B - A);// *smoothstep(A, A + stepVal, diffuseVal);
                 else if (diffuseVal < B) diffuseVal = B;
                 else if (diffuseVal >= B && diffuseVal < B + stepVal) diffuseVal = B + (C - B);// *smoothstep(B, B + stepVal, diffuseVal);
                 else if (diffuseVal < C) diffuseVal = C;
                 else if (diffuseVal >= C && diffuseVal < C + stepVal) diffuseVal = C + (1.0 - C);// *smoothstep(C, C + stepVal, diffuseVal);
                 else diffuseVal = 1.0; 
                 
                 
                 lightIntensity = diffuseVal; 
                 float3 diffuse = Kd * Kl * lightIntensity;
                
                
                //SPECULAR LIGHT
                float specularVal = pow(max(dot(N,H), 0), _Shininess);
                
                if (diffuseVal <= 0) {
                    specularVal = 0;
                }
                
                specularVal = smoothstep(0.25, 0.25 + stepVal, specularVal);
                float3 specular = Ks * Kl * specularVal;
                
                //FINAL COLOR OF FRAGMENT
                return float4(ambient + diffuse + specular, 1.0);
                

            }
            ENDCG  
        }
        // X Ray Pass
        Pass
        {
            Tags
            {
                "Queue" = "Transparent"
            }
            // Won't draw where it sees ref value 4
            Cull Front // draw back faces
            ZWrite OFF
            ZTest Always
            Stencil
            {
                Ref 3
                Comp Greater
                Fail keep
                Pass replace
            }
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Properties
            uniform float4 _LineColor;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(v2f i) : COLOR
            {
                return float4(_LineColor.rgb, 1);
            }

            ENDCG
        }

            
    }
}
