﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "SGF/AlphaTest"
{
    Properties
    {
        _Color("Main Tint",Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _CutOff("Alpha CutOff",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RendetType"="TransParentCutout" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CutOff;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // Screen Clip
                float4 pos : SV_POSITION;
                float3 worldNormal: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float2 uv: TEXCOORD2;
            };

           

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // 矩阵变换
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed4 texColor = tex2D(_MainTex,i.uv);
                
                // alpha test
                clip(texColor.a - _CutOff);
                
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));
                
                return fixed4(ambient + diffuse , 1.0);
            }
            ENDCG
        }
    }
    
    FallBack "Transparent/Count/Vertexlit"
}
