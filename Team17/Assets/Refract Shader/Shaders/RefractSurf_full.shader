// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Refractive/RefractSurf_full" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MainTexFactor ("Albedo Factor", Range(0,1)) = 1
		_NormalMapIntensity ("Normal Intensity", Float) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_GlossinessMap("Smoothness Map", 2D) = "white" {}
		_GlossinessMapFactor("Smoothness map Factor", Range(0,1)) = 1
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_IOR ("Index Of Refraction", Float) = 1.4
		_CA ("Chromatic Abbreviation", Float) = 0.1
		_FresnelIntensity ("Fresnel Intensity", Float) = 1
		_FresnelPower ("Fresnel Power", Float) = 1
		_EmissiveColor("Emissive Color", Color) = (0,0,0,0)
		_EmissiveMap("Emissive Map", 2D) = "black" {}
		_EmissiveMapFactor("Emissive Map Factor", Range(0,1)) = 1
		_EmissiveMultiplier("Emissive Multiplier", Float) = 1
	}
	SubShader {
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 100

		GrabPass{
		
		}
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _GlossinessMap;
		sampler2D _EmissiveMap;
		sampler2D _CameraDepthTexture;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float2 uv_GlossinessMap;
			float2 uv_EmissiveMap;
			float4 screenPos;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
		};

		half _MainTexFactor;
		half _GlossinessMapFactor;
		half _EmissiveMapFactor;
		half _EmissiveMultiplier;
		half _NormalMapIntensity;
		half _Glossiness;
		half _Metallic;
		half _IOR;
		half _CA;
		half _FresnelIntensity;
		half _FresnelPower;
		fixed4 _Color;
		fixed4 _EmissiveColor;
		sampler2D _GrabTexture;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float3 Tex2DprojBlurred( sampler2D tex, float4 coord, float blur ) {
			float3 result = float3(0,0,0);
			int c = 0;
			for (int x = -4; x <= 4; x++) {
				for (int y = -4; y <= 4; y++) {
					result += tex2Dproj(
						tex, 
						coord + float4(
							(x/_ScreenParams.x)*blur,
							(y / _ScreenParams.y)*blur,
							0,0
						)
					).rgb;
					c++;
				}
			}

			result /= c;

			return result;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			
			o.Normal = lerp( float3(0,0,1), UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap)), _NormalMapIntensity);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness * lerp( 1.0 , tex2D(_GlossinessMap, IN.uv_GlossinessMap).r, _GlossinessMapFactor)-0.0001;
			float blur = (1 - (o.Smoothness)) * 16 * IN.screenPos.w;
			o.Alpha = 1;

			/* Construct per fragment view space basis vectors */
			float3 camZ = normalize( _WorldSpaceCameraPos - IN.worldPos );
			float3 camY = float3(UNITY_MATRIX_V[1][0], UNITY_MATRIX_V[1][1], UNITY_MATRIX_V[1][2]);
			float3 camX = normalize( cross(camZ, camY ));
			
			

			/* put basis vectors into matrix */
			float4x4 fragmentViewBasis = float4x4(
				camX.x,camX.y,camX.z,0,
				camY.x,camY.y,camY.z,0,
				camZ.x,camZ.y,camZ.z,0,
				0,0,0,1
			);

			
			/* calculating displacement offset vector */
			float2 dispVec = mul(fragmentViewBasis, float4(WorldNormalVector(IN, o.Normal), 0.0)).xy;
			/* correct dispVec for screen aspect ratio */
			dispVec.x *= (_ScreenParams.y/ _ScreenParams.x);
			/* apply fresnel to increase/decrease distortion near shallow angles */
			float fresnel = pow( 1-max(dot(WorldNormalVector(IN, o.Normal), camZ),0.0), _FresnelPower ) * _FresnelIntensity;
			dispVec *= fresnel; 
			float3 dispBG = float3(0,0,0);
			float3 BG = tex2Dproj( _GrabTexture, IN.screenPos ).rgb;
			float d = Tex2DprojBlurred(_CameraDepthTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5, 0, 0), blur).r;
				if (_CA <= 0) {
					dispBG = Tex2DprojBlurred(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5, 0, 0), blur).rgb;
				}
				else {
					float f = _CA * IN.screenPos.w;
					float bgR = Tex2DprojBlurred(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(f / 10, 0), 0, 0), blur).r;
					d = max( d, Tex2DprojBlurred(_CameraDepthTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(f / 10, 0), 0, 0), blur).r);
					float bgG = Tex2DprojBlurred(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(-f / 10, 0), 0, 0), blur).b;
					d = max(d, Tex2DprojBlurred(_CameraDepthTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(-f / 10, 0), 0, 0), blur).r);
					float bgB = Tex2DprojBlurred(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(0, 0), 0, 0), blur).g;

					dispBG = float3(bgR, bgB, bgG);
				}

			
			float dm = d < LinearEyeDepth( IN.screenPos.w );
			
			o.Albedo = lerp(BG, dispBG, (1.0-_Color.a) * dm);
			o.Albedo *= lerp( float3(1,1,1), tex2D(_MainTex, IN.uv_MainTex).rgb, _MainTexFactor );
			o.Albedo *= _Color.rgb;
			
			//o.Albedo = float3(dm,dm,dm);

			o.Emission = ( _EmissiveColor * lerp( float4(1,1,1,1), tex2D(_EmissiveMap, IN.uv_EmissiveMap), _EmissiveMapFactor) ).rgb;
			o.Emission *= _EmissiveMultiplier;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
