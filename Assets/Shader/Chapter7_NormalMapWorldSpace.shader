﻿Shader "SGF/NormalMapTangentSpace"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        
        _BumpMap("Normal Map",2D) = "white"{}
        _BumpScale("Bump Scale",float) = 1.0
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Tags { "LightModel"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
         

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
               float4 pos : SV_POSITION;
               float4 uv :  TEXCOORD0;
               float4 TtoW0 : TEXCOORD1;
               float4 TtoW1 : TEXCOORD2;
               float4 TtoW2 : TEXCOORD3;
            };

         

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                
                float3 worldPos = mul(_Object2World,v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTargent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTargent) * v.tangent.w;
                
                // comput the matrix that transform directions from tangent space to world space
                // put the world position in w component for optimization
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                
                // comput the light and view dir in world space
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceView(worldPos));
                
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));
                
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
                
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,tangentLightDir));
                
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(bump,halfDir)),_Gloss);
                
                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
}