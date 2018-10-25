// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Refractive/RefractSurf_noGloss" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMapIntensity ("Normal Intensity", Float) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_IOR ("Index Of Refraction", Float) = 1.4
		_CA ("Chromatic Abbreviation", Float) = 0.1
		_FresnelIntensity ("Fresnel Intensity", Float) = 1
		_FresnelPower ("Fresnel Power", Float) = 1
	}
	SubShader {
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 200

		GrabPass{
		
		}
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalMap;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float4 screenPos;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
		};

		half _NormalMapIntensity;
		half _Metallic;
		half _IOR;
		half _CA;
		half _FresnelIntensity;
		half _FresnelPower;
		fixed4 _Color;
		sampler2D _GrabTexture;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			
			o.Normal = lerp( float3(0,0,1), UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap)), _NormalMapIntensity);
			o.Metallic = _Metallic;
			o.Smoothness = 1;
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

				if (_CA <= 0) {
					float3 dispBG = tex2Dproj(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5, 0, 0)).rgb;
					o.Albedo = dispBG;
				}
				else {
					float f = _CA * IN.screenPos.w;
					float bgR = tex2Dproj(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(f / 10, 0), 0, 0)).r;
					float bgG = tex2Dproj(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(-f / 10, 0), 0, 0)).b;
					float bgB = tex2Dproj(_GrabTexture, IN.screenPos + float4(-dispVec*(_IOR - 1)*0.5 + float2(0, 0), 0, 0)).g;
					o.Albedo = float3(bgR, bgB, bgG);
				}

			o.Albedo *= tex2D(_MainTex, IN.uv_MainTex).rgb;
			o.Albedo *= _Color;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
