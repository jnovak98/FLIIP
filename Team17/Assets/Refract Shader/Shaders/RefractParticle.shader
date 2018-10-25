Shader "Refractive/RefractParticle"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex ("Mask texture", 2D) = "white" {}
		_NormalMapIntensity("Normal Intensity", Float) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
	}
	SubShader
	{
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		LOD 100
		
		GrabPass{
			"_GrabTexture"
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD2;
				float4 screenPos : TEXCOORD1;
				float4 color : TEXCOORD3;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _NormalMap;
			float4 _MainTex_ST;
			float4 _NormalMap_ST;
			
			half _NormalMapIntensity;
			half _IOR;
			half _CA;
			fixed4 _Color;
			sampler2D _GrabTexture;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.uv, _NormalMap);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float mask = tex2D(_MainTex, i.uv).a * i.color.a;
				float3 tint = tex2D(_MainTex, i.uv).rgb * _Color.rgb * i.color.rgb;
				float2 normal = UnpackNormal(tex2D(_NormalMap, i.uv1)).xy * _NormalMapIntensity;
				float3 bg = tex2Dproj(_GrabTexture, i.screenPos + float4( normal * mask,0,0 )).rgb;
				fixed4 color = float4( bg * tint, mask );
				return color;
			}
			ENDCG
		}
	}
}
