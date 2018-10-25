// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//Transparent refraction/reflection


Shader "CG Shaders/Phong/Phong Texture Refractive"
{
	Properties
	{
		
		_specularPower ("Specular Power", Range(1.0, 50.0)) = 10
		_specularPower (" ", Float) = 10
		_specularColor("Specular Color", Color) = (1,1,1,1)
		_normalMap("Normal / Specular (A)", 2D) = "bump" {}
		_glassColor("Glass Color", Color) = (1,1,1,1)
		//cube map
		_CubeMap ("Cube", Cube) = "" {}
		_refractiveIndex ("Refractive Index", Range(1.0, 3.0)) = 1.0
		_refractiveIndex (" ", Float) = 1.0
		_reflectionPower ("Reflection Power", Range(1.0, 10.0)) = 3.0
		_reflectionPower (" ", Float) = 3.0
		_reflectionBias ("Reflection Bias", Range(0.0, 1.0)) = 0.1
		_reflectionBias (" ", Float) = 0.1
		_reflectionIntensity ("Reflection Brightness", Range(1.0, 5.0)) = 3.0
		_reflectionIntensity (" ", Float) = 3.0
		_Opacity ("Opacity", Range(0.0, 1.0)) = 1.0
		_Opacity (" ", Float) = 1.0
		
		
	}
	SubShader
	{
	Tags {"Queue" = "Transparent" } 
		Pass
		{
			Tags { "LightMode" = "ForwardBase" } 
			
            // don't write to depth buffer in order not to occlude other objects
			ZWrite Off 
			
			Blend SrcAlpha OneMinusSrcAlpha 
			
			CGPROGRAM
			
			#pragma vertex vShader
			#pragma fragment pShader
			#include "UnityCG.cginc"
			#pragma multi_compile_fwdbase
			
			uniform fixed3 _glassColor;				
			uniform half _specularPower;
			uniform fixed3 _specularColor;
			uniform sampler2D _normalMap;
			uniform half4 _normalMap_ST;	
			//cubemap
			uniform half _FrenselPower;
			uniform fixed4 _rimColor;
			uniform samplerCUBE _CubeMap;			
			uniform fixed _refractiveIndex;				
			uniform half _reflectionPower;
			uniform fixed _reflectionBias;
			uniform half _reflectionIntensity;
			uniform fixed _Opacity;
			
			struct app2vert {
				float4 vertex 	: 	POSITION;
				fixed2 texCoord : 	TEXCOORD0;
				fixed4 normal 	:	NORMAL;
				fixed4 tangent : TANGENT;
				
			};
			struct vert2Pixel
			{
				float4 pos 						: 	SV_POSITION;
				fixed2 uvs						:	TEXCOORD0;
				fixed3 normalDir						:	TEXCOORD1;	
				fixed3 binormalDir					:	TEXCOORD2;	
				fixed3 tangentDir					:	TEXCOORD3;	
				half3 posWorld						:	TEXCOORD4;	
				fixed3 viewDir						:	TEXCOORD5;
				fixed3 lighting						:	TEXCOORD6;
			};
			
			fixed lambert(fixed3 N, fixed3 L)
			{
				return saturate(dot(N, L));
			}
			fixed frensel(fixed3 V, fixed3 N, half P)
			{	
				return pow(1 - saturate(dot(V,N)), P);
			}
			fixed phong(fixed3 R, fixed3 L)
			{
				return pow(saturate(dot(R, L)), _specularPower);
			}
			vert2Pixel vShader(app2vert IN)
			{
				vert2Pixel OUT;
				float4x4 WorldViewProjection = UNITY_MATRIX_MVP;
				float4x4 WorldInverseTranspose = unity_WorldToObject; 
				float4x4 World = unity_ObjectToWorld;
							
				OUT.pos = mul(WorldViewProjection, IN.vertex);
				OUT.uvs = IN.texCoord;					
				OUT.normalDir = normalize(mul(IN.normal, WorldInverseTranspose).xyz);
				OUT.tangentDir = normalize(mul(IN.tangent, WorldInverseTranspose).xyz);
				OUT.binormalDir = normalize(cross(OUT.normalDir, OUT.tangentDir)); 
				OUT.posWorld = mul(World, IN.vertex).xyz;
				OUT.viewDir = normalize( OUT.posWorld - _WorldSpaceCameraPos);

				//vertex lights
				fixed3 vertexLighting = fixed3(0.0, 0.0, 0.0);
				#ifdef VERTEXLIGHT_ON
				 for (int index = 0; index < 4; index++)
					{    						
						half3 vertexToLightSource = half3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]) - OUT.posWorld;
						fixed attenuation  = (1.0/ length(vertexToLightSource)) *.5;	
						fixed3 diffuse = unity_LightColor[index].xyz * lambert(OUT.normalDir, normalize(vertexToLightSource)) * attenuation;
						vertexLighting = vertexLighting + diffuse;
					}
				vertexLighting = saturate( vertexLighting );
				#endif
				OUT.lighting = vertexLighting ;
				
				return OUT;
			}
			
			fixed4 pShader(vert2Pixel IN): COLOR
			{
				half2 normalUVs = TRANSFORM_TEX(IN.uvs, _normalMap);
				fixed4 normalD = tex2D(_normalMap, normalUVs);
				normalD.xyz = (normalD.xyz * 2) - 1;
							
				//half3 normalDir = half3(2.0 * normalSample.xy - float2(1.0), 0.0);
				//deriving the z component
				//normalDir.z = sqrt(1.0 - dot(normalDir, normalDir));
               // alternatively you can approximate deriving the z component without sqrt like so:  
				//normalDir.z = 1.0 - 0.5 * dot(normalDir, normalDir);
				
				fixed3 normalDir = normalD.xyz;	
				fixed specMap = normalD.w;
				normalDir = normalize((normalDir.x * IN.tangentDir) + (normalDir.y * IN.binormalDir) + (normalDir.z * IN.normalDir));
	
				//pull out the reflection vector calculation as we use it twice
				fixed3 reflectionV = reflect(IN.viewDir , normalDir); 
	
				//Main Light calculation - includes directional lights
				//similarly to reflection we do not add rim light, since it would interfere with proper reflection/refraction
				//In fact to save instructions, I cut diffuse and ambient light altogether 
				//If you wanted to texture dirty stains or something you might need diffuse for that
				half3 pixelToLightSource =_WorldSpaceLightPos0.xyz - (IN.posWorld*_WorldSpaceLightPos0.w);
				fixed attenuation  = lerp(1.0, 1.0/ length(pixelToLightSource), _WorldSpaceLightPos0.w);				
				fixed3 lightDirection = normalize(pixelToLightSource);
				fixed specularHighlight = phong(reflectionV ,lightDirection)*attenuation;
					
				//refraction
				fixed3 refractDir = refract(IN.viewDir, normalDir, 1.0 / _refractiveIndex);
				
				//unity's default skybox has a flipped x component
				//you can enable a reversal to match up with it
				//or you can use my custom skybox shader which fixes the issue there
				
				//refractDir *= fixed3(-1,1,1);
				
				fixed3 refractSample = texCUBE(_CubeMap, refractDir );
				refractSample *= _glassColor;
				
				//reflection
				fixed3 reflection = texCUBE(_CubeMap, reflectionV).xyz;
				reflection *= _reflectionIntensity;

				// Compute the reflection vs refraction mask
				
				fixed3 reflectionFactor = _reflectionBias +frensel(normalDir, -IN.viewDir, _reflectionPower);
				fixed3 totalRvsR = lerp( refractSample, reflection, saturate(reflectionFactor));
				
				fixed4 outColor;									
				fixed3 specular = (specularHighlight * _specularColor * specMap);
				outColor = fixed4( totalRvsR  + specular,_Opacity);
				return outColor;
			}
			
			ENDCG
		}	
		
		//the second pass for additional lights
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" } 
			Blend One One 
			
			CGPROGRAM
			#pragma vertex vShader
			#pragma fragment pShader
			#include "UnityCG.cginc"
			
			uniform fixed3 _glassColor;	
			uniform half _specularPower;
			uniform fixed3 _specularColor;
			uniform sampler2D _normalMap;
			uniform half4 _normalMap_ST;		
			uniform half _alphaFrenselPower;
			uniform fixed _alphaFrenselBias;
			uniform fixed _Opacity;			
			
			
			
			struct app2vert {
				float4 vertex 	: 	POSITION;
				fixed2 texCoord : 	TEXCOORD0;
				fixed4 normal 	:	NORMAL;
				fixed4 tangent : TANGENT;
			};
			struct vert2Pixel
			{
				float4 pos 						: 	SV_POSITION;
				fixed2 uvs						:	TEXCOORD0;	
				fixed3 normalDir						:	TEXCOORD1;	
				fixed3 binormalDir					:	TEXCOORD2;	
				fixed3 tangentDir					:	TEXCOORD3;	
				half3 posWorld						:	TEXCOORD4;	
				fixed3 viewDir						:	TEXCOORD5;
				fixed4 lighting					:	TEXCOORD6;	
			};
			
			fixed lambert(fixed3 N, fixed3 L)
			{
				return saturate(dot(N, L));
			}			
			fixed frensel(fixed3 V, fixed3 N, half P)
			{	
				return pow(1 - saturate(dot(V,N)), P);
			}
			fixed phong(fixed3 R, fixed3 L)
			{
				return pow(saturate(dot(R, L)), _specularPower);
			}
			vert2Pixel vShader(app2vert IN)
			{
				vert2Pixel OUT;
				float4x4 WorldViewProjection = UNITY_MATRIX_MVP;
				float4x4 WorldInverseTranspose = unity_WorldToObject; 
				float4x4 World = unity_ObjectToWorld;
				
				OUT.pos = mul(WorldViewProjection, IN.vertex);
				OUT.uvs = IN.texCoord;	
				
				OUT.normalDir = normalize(mul(IN.normal, WorldInverseTranspose).xyz);
				OUT.tangentDir = normalize(mul(IN.tangent, WorldInverseTranspose).xyz);
				OUT.binormalDir = normalize(cross(OUT.normalDir, OUT.tangentDir)); 
				OUT.posWorld = mul(World, IN.vertex).xyz;
				OUT.viewDir = normalize( OUT.posWorld -_WorldSpaceCameraPos );
				return OUT;
			}
			fixed4 pShader(vert2Pixel IN): COLOR
			{
				half2 normalUVs = TRANSFORM_TEX(IN.uvs, _normalMap);
				fixed4 normalD = tex2D(_normalMap, normalUVs);
				normalD.xyz = (normalD.xyz * 2) - 1;
				
				//half3 normalDir = half3(2.0 * normalSample.xy - float2(1.0), 0.0);
				//deriving the z component
				//normalDir.z = sqrt(1.0 - dot(normalDir, normalDir));
               // alternatively you can approximate deriving the z component without sqrt like so: 
				//normalDir.z = 1.0 - 0.5 * dot(normalDir, normalDir);
				
				//pull the alpha out for spec before modification
				fixed3 normalDir = normalD.xyz;	
				fixed specMap = normalD.w;
				normalDir = normalize((normalDir.x * IN.tangentDir) + (normalDir.y * IN.binormalDir) + (normalDir.z * IN.normalDir));
						
				//pull out the reflection vector calculation as we use it twice
				fixed3 reflectionV = reflect(IN.viewDir , normalDir); 
	
				//Fill lights
				half3 pixelToLightSource =_WorldSpaceLightPos0.xyz - (IN.posWorld*_WorldSpaceLightPos0.w);
				fixed attenuation  = lerp(1.0, 1.0/ length(pixelToLightSource), _WorldSpaceLightPos0.w);				
				fixed3 lightDirection = normalize(pixelToLightSource);
				//specular highlight
				fixed specularHighlight = phong(reflectionV ,lightDirection)*attenuation;
				
				fixed4 outColor;							
				fixed3 specular = specularHighlight * _specularColor * specMap;
				outColor = fixed4(specular*_Opacity,1);
				return outColor;
			}
			
			ENDCG
		}	
		
	}
}