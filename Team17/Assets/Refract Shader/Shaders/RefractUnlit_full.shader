Shader "Refractive/RefractUnlit_full"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_MainTexFactor("Albedo Factor", Range(0,1)) = 1
		_NormalMapIntensity("Normal Intensity", Float) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_GlossinessMap("Smoothness Map", 2D) = "white" {}
		_GlossinessMapFactor("Smoothness map Factor", Range(0,1)) = 1
		_IOR("Index Of Refraction", Float) = 1.4
		_CA("Chromatic Abbreviation", Float) = 0.1
		_FresnelIntensity("Fresnel Intensity", Float) = 1
		_FresnelPower("Fresnel Power", Float) = 1
	}
	SubShader
	{
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 100
		
		GrabPass{

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
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD5;
				float4 screenPos : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};


			sampler2D _GlossinessMap;
			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;
			sampler2D _NormalMap;
			float4 _MainTex_ST;
			float4 _GlossinessMap_ST;
			float4 _NormalMap_ST;
			
			half _NormalMapIntensity;
			half _MainTexFactor;
			half _GlossinessMapFactor;
			half _Glossiness;
			half _IOR;
			half _CA;
			half _FresnelIntensity;
			half _FresnelPower;
			fixed4 _Color;
			sampler2D _GrabTexture;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul( UNITY_MATRIX_M, v.vertex ).xyz;
				o.worldNormal = mul(UNITY_MATRIX_M, float4(v.normal,0.0)).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.uv, _GlossinessMap);
				o.uv2 = TRANSFORM_TEX(v.uv, _NormalMap);
				o.screenPos = ComputeScreenPos(o.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			float3 Tex2DprojBlurred(sampler2D tex, float4 coord, float blur) {
				float3 result = float3(0, 0, 0);
				int c = 0;
				for (int x = -4; x <= 4; x++) {
					for (int y = -4; y <= 4; y++) {
						result += tex2Dproj(
							tex,
							coord + float4(
							(x / _ScreenParams.x)*blur,
								(y / _ScreenParams.y)*blur,
								0, 0
								)
						).rgb;
						c++;
					}
				}
				result /= c;
				return result;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				float gloss = _Glossiness * lerp(1.0, tex2D(_GlossinessMap, i.uv1).r, _GlossinessMapFactor) - 0.0001;
				float blur = (1 - (gloss)) * 16 * i.screenPos.w;
				
				/* Construct per fragment view space basis vectors */
				float3 camZ = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 camY = float3(UNITY_MATRIX_V[1][0], UNITY_MATRIX_V[1][1], UNITY_MATRIX_V[1][2]);
				float3 camX = normalize(cross(camZ, camY));



				/* put basis vectors into matrix */
				float4x4 fragmentViewBasis = float4x4(
					camX.x, camX.y, camX.z, 0,
					camY.x, camY.y, camY.z, 0,
					camZ.x, camZ.y, camZ.z, 0,
					0, 0, 0, 1
					);


				/* calculating displacement offset vector */
				float2 dispVec = mul(fragmentViewBasis, float4(i.worldNormal, 0.0)).xy - mul( fragmentViewBasis, float4(UnpackNormal(tex2D(_NormalMap, i.uv2) * _NormalMapIntensity), 0.0)).xy;
				/* correct dispVec for screen aspect ratio */
				dispVec.x *= (_ScreenParams.y / _ScreenParams.x);
				/* apply fresnel to increase/decrease distortion near shallow angles */
				float fresnel = pow(1 - max(dot(i.worldNormal, camZ), 0.0), _FresnelPower) * _FresnelIntensity;
				dispVec *= fresnel;
				float3 dispBG = float3(0, 0, 0);
				float3 BG = tex2Dproj(_GrabTexture, i.screenPos).rgb;
				float d = Tex2DprojBlurred(_CameraDepthTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5, 0, 0), blur).r;
				if (_CA <= 0) {
					dispBG = Tex2DprojBlurred(_GrabTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5, 0, 0), blur).rgb;
				}
				else {
					float f = _CA * i.screenPos.w;
					float bgR = Tex2DprojBlurred(_GrabTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(f / 10, 0), 0, 0), blur).r;
					d = max(d, Tex2DprojBlurred(_CameraDepthTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(f / 10, 0), 0, 0), blur).r);
					float bgG = Tex2DprojBlurred(_GrabTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(-f / 10, 0), 0, 0), blur).b;
					d = max(d, Tex2DprojBlurred(_CameraDepthTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(-f / 10, 0), 0, 0), blur).r);
					float bgB = Tex2DprojBlurred(_GrabTexture, i.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(0, 0), 0, 0), blur).g;

					dispBG = float3(bgR, bgB, bgG);
				}


				float dm = d < LinearEyeDepth(i.screenPos.w);

				fixed4 finalCol = float4( lerp(col.rgb, dispBG, (1.0 - col.a) * dm), 1.0 );
				finalCol.rgb *= lerp(float3(1, 1, 1), tex2D(_MainTex, i.uv).rgb, _MainTexFactor);
				finalCol.rgb *= _Color.rgb;

				UNITY_APPLY_FOG(i.fogCoord, finalCol);
				return finalCol;
			}
			ENDCG
		}
	}
}
