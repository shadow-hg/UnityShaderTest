Shader "Unlit/S01"
{
    Properties{
        _max("Max",vector) = (0.1,1,1,1)
        }
    Subshader{
        Pass{
            Name "BasePass"
            Tags{"LightMode" = "ForwardBase" "RenderType" = "Opaque" }
            
            ZWrite on
            Blend off
            Cull back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            fixed4 _max;
            float4 _LightColor0;

            struct a2v
            {
                float4 vertex : POSITION ;
                float3 normal : NORMAL ;
                
            };

            struct v2f
            {
                float4 pos : SV_POSITION ;
                float3 WldNormal : TEXCOORD0;
                
                SHADOW_COORDS(2)
                
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.WldNormal = UnityObjectToWorldNormal(v.normal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{

                fixed3 diffuse = saturate(dot(normalize(_WorldSpaceLightPos0),normalize(i.WldNormal)));
                fixed shadow = LIGHT_ATTENUATION(i);
                

                diffuse = lerp(_max.x,_max.y,diffuse*shadow) + UNITY_LIGHTMODEL_AMBIENT * _LightColor0;

                return fixed4(diffuse,1);
                
            }
            
            ENDHLSL
            
            }
        Pass{
            Name "BasePass"
            Tags{"LightMode" = "ForwardAdd" "RenderType" = "Opaque" }
            
            
            Blend one one
            Cull back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullShadows

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            fixed4 _max;
            float4 _LightColor0;

            struct a2v
            {
                float4 vertex : POSITION ;
                float3 normal : NORMAL ;
                
            };

            struct v2f
            {
                float4 pos : SV_POSITION ;
                float3 WldNormal : TEXCOORD0;
                
                LIGHTING_COORDS(1,2)
                
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.WldNormal = UnityObjectToWorldNormal(v.normal);

                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag(v2f i):SV_Target{

                fixed3 diffuse = saturate(dot(normalize(_WorldSpaceLightPos0),normalize(i.WldNormal)));
                
                float atten = LIGHT_ATTENUATION(i);

                diffuse = lerp(_max.x,_max.y,diffuse * atten) ;

                return fixed4(diffuse,1);
                
            }
            
            ENDHLSL
            
            }
        }
    fallback "Diffuse"
}
