// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DepthToRender"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin][Toggle]_ShowDepthOnly("Show Depth Only", Float) = 0
		[Toggle]_ShowNormalOnly("Show Normal Only", Float) = 0
		_InputColorCameraF("Input Color Camera F", Range( 1 , 2)) = 1.1543
		_NormalCoeff("Normal Coeff", Range( 0 , 5)) = 1.5
		_DepthK("Depth K", Float) = 0.2966
		_DepthB("Depth B", Float) = 0.022267
		_OcculusionTolerance("Occulusion Tolerance", Range( 0.05 , 0.3)) = 0.05
		[Toggle]_DropOcculusion("Drop Occulusion", Float) = 1
		_Alpha("Alpha", Range( 0 , 1)) = 1
		_NormalCalculateDelta("NormalCalculateDelta", Range( 0.0001 , 0.04)) = 0.01
		_BackgroundColor("BackgroundColor", Color) = (0.3490566,0.3490566,0.3490566,0)
		_SomulateDepthCamF("SomulateDepthCamF", Range( 0.5 , 2)) = 0
		_CamOutPosition("CamOutPosition", Vector) = (0,0,0,0)
		_CamOutRotation("CamOutRotation", Vector) = (0,0,0,0)
		_RGB_1("RGB_1", 2D) = "white" {}
		_D_1("D_1", 2D) = "white" {}
		_RGB_2("RGB_2", 2D) = "white" {}
		_D_2("D_2", 2D) = "white" {}
		_Camera1Position("Camera 1 Position", Vector) = (0,0,0,0)
		_Camera2Rotation("Camera 2 Rotation", Vector) = (0,0,0,0)
		_Camera1Rotation("Camera 1 Rotation", Vector) = (0,0,0,0)
		_Camera2Position("Camera 2 Position", Vector) = (0,0,0,0)
		_D_new("D_new", 2D) = "white" {}
		_PositionOffset("PositionOffset", Vector) = (0,0,0,0)
		[ASEEnd]_EmptyWeight("EmptyWeight", Range( 0 , 1)) = 0.01

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BackgroundColor;
			float3 _Camera1Rotation;
			float3 _Camera2Rotation;
			float3 _CamOutRotation;
			float3 _PositionOffset;
			float3 _CamOutPosition;
			float3 _Camera2Position;
			float3 _Camera1Position;
			float _NormalCoeff;
			float _NormalCalculateDelta;
			float _OcculusionTolerance;
			float _DropOcculusion;
			float _ShowNormalOnly;
			float _InputColorCameraF;
			float _EmptyWeight;
			float _DepthK;
			float _SomulateDepthCamF;
			float _ShowDepthOnly;
			float _DepthB;
			float _Alpha;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _D_new;
			sampler2D _D_1;
			sampler2D _RGB_1;
			sampler2D _D_2;
			sampler2D _RGB_2;


			float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
			{
				original -= center;
				float C = cos( angle );
				float S = sin( angle );
				float t = 1 - C;
				float m00 = t * u.x * u.x + C;
				float m01 = t * u.x * u.y - S * u.z;
				float m02 = t * u.x * u.z + S * u.y;
				float m10 = t * u.x * u.y + S * u.z;
				float m11 = t * u.y * u.y + C;
				float m12 = t * u.y * u.z - S * u.x;
				float m20 = t * u.x * u.z - S * u.y;
				float m21 = t * u.y * u.z + S * u.x;
				float m22 = t * u.z * u.z + C;
				float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
				return mul( finalMatrix, original ) + center;
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float3 break35_g6254 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g6254 = RotateAroundAxis( float3( 0,0,0 ), ( ( WorldPosition - _PositionOffset ) - _CamOutPosition ), float3(0,1,0), break35_g6254.y );
				float3 rotatedValue39_g6254 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g6254, float3(1,0,0), break35_g6254.x );
				float3 rotatedValue33_g6254 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g6254, float3(0,0,1), break35_g6254.z );
				float3 break44_g6254 = rotatedValue33_g6254;
				float2 appendResult31_g6254 = (float2(break44_g6254.x , break44_g6254.y));
				float2 temp_output_222_0 = ( ( ( appendResult31_g6254 / _SomulateDepthCamF ) / break44_g6254.z ) + float2( 0.5,0.5 ) );
				float4 tex2DNode162 = tex2D( _D_new, temp_output_222_0 );
				float temp_output_1_0_g6319 = tex2DNode162.r;
				float temp_output_313_0 = ( 0.2980392 / temp_output_1_0_g6319 );
				float3 break26_g6257 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g6257 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g6257.z );
				float3 rotatedValue16_g6257 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g6257, float3(1,0,0), break26_g6257.x );
				float3 rotatedValue14_g6257 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g6257, float3(0,1,0), break26_g6257.y );
				float3 normalizeResult30_g6257 = normalize( rotatedValue14_g6257 );
				float3 temp_output_31_0_g6257 = _CamOutPosition;
				float3 normalizeResult8_g6257 = normalize( ( WorldPosition - temp_output_31_0_g6257 ) );
				float dotResult29_g6257 = dot( normalizeResult30_g6257 , normalizeResult8_g6257 );
				float3 temp_output_223_0 = ( ( ( temp_output_313_0 / dotResult29_g6257 ) * normalizeResult8_g6257 ) + temp_output_31_0_g6257 );
				float3 temp_output_56_0_g6321 = temp_output_223_0;
				float3 temp_output_57_0_g6321 = _PositionOffset;
				float3 temp_output_61_0_g6321 = _Camera1Position;
				float3 temp_output_53_0_g6321 = ( ( temp_output_56_0_g6321 - temp_output_57_0_g6321 ) - temp_output_61_0_g6321 );
				float3 break35_g6322 = ( ( ( _Camera1Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g6322 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g6321 - temp_output_57_0_g6321 ) - temp_output_61_0_g6321 ), float3(0,1,0), break35_g6322.y );
				float3 rotatedValue39_g6322 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g6322, float3(1,0,0), break35_g6322.x );
				float3 rotatedValue33_g6322 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g6322, float3(0,0,1), break35_g6322.z );
				float3 break44_g6322 = rotatedValue33_g6322;
				float2 appendResult31_g6322 = (float2(break44_g6322.x , break44_g6322.y));
				float2 temp_output_162_0_g6321 = ( ( ( appendResult31_g6322 / _InputColorCameraF ) / break44_g6322.z ) + float2( 0.5,0.5 ) );
				float4 tex2DNode80_g6321 = tex2D( _D_1, temp_output_162_0_g6321 );
				float3 break95_g6281 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float2 appendResult275 = (float2(_NormalCalculateDelta , 0.0));
				float2 temp_output_240_0 = ( temp_output_222_0 + appendResult275 );
				float temp_output_1_0_g6318 = tex2D( _D_new, temp_output_240_0 ).r;
				float temp_output_66_0_g6281 = ( 0.2980392 / temp_output_1_0_g6318 );
				float3 appendResult73_g6281 = (float3(( ( ( temp_output_240_0 - float2( 0.5,0.5 ) ) * temp_output_66_0_g6281 ) * _SomulateDepthCamF ) , temp_output_66_0_g6281));
				float3 rotatedValue97_g6281 = RotateAroundAxis( float3( 0,0,0 ), appendResult73_g6281, float3(0,0,1), break95_g6281.z );
				float3 rotatedValue86_g6281 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue97_g6281, float3(1,0,0), break95_g6281.x );
				float3 rotatedValue84_g6281 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue86_g6281, float3(0,1,0), break95_g6281.y );
				float3 break95_g6277 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float temp_output_278_0 = ( _NormalCalculateDelta * -1.0 );
				float2 appendResult274 = (float2(0.0 , temp_output_278_0));
				float2 temp_output_241_0 = ( temp_output_222_0 + appendResult274 );
				float temp_output_1_0_g6317 = tex2D( _D_new, temp_output_241_0 ).r;
				float temp_output_66_0_g6277 = ( 0.2980392 / temp_output_1_0_g6317 );
				float3 appendResult73_g6277 = (float3(( ( ( temp_output_241_0 - float2( 0.5,0.5 ) ) * temp_output_66_0_g6277 ) * _SomulateDepthCamF ) , temp_output_66_0_g6277));
				float3 rotatedValue97_g6277 = RotateAroundAxis( float3( 0,0,0 ), appendResult73_g6277, float3(0,0,1), break95_g6277.z );
				float3 rotatedValue86_g6277 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue97_g6277, float3(1,0,0), break95_g6277.x );
				float3 rotatedValue84_g6277 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue86_g6277, float3(0,1,0), break95_g6277.y );
				float3 temp_output_259_0 = ( ( ( rotatedValue84_g6281 + _CamOutPosition ) + _PositionOffset ) - ( ( rotatedValue84_g6277 + _CamOutPosition ) + _PositionOffset ) );
				float3 break95_g6280 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float2 appendResult273 = (float2(_NormalCalculateDelta , 0.0));
				float temp_output_1_0_g6320 = tex2D( _D_new, temp_output_222_0 ).r;
				float temp_output_66_0_g6280 = ( 0.2980392 / temp_output_1_0_g6320 );
				float3 appendResult73_g6280 = (float3(( ( ( ( temp_output_222_0 + appendResult273 ) - float2( 0.5,0.5 ) ) * temp_output_66_0_g6280 ) * _SomulateDepthCamF ) , temp_output_66_0_g6280));
				float3 rotatedValue97_g6280 = RotateAroundAxis( float3( 0,0,0 ), appendResult73_g6280, float3(0,0,1), break95_g6280.z );
				float3 rotatedValue86_g6280 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue97_g6280, float3(1,0,0), break95_g6280.x );
				float3 rotatedValue84_g6280 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue86_g6280, float3(0,1,0), break95_g6280.y );
				float3 break95_g6275 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float2 appendResult276 = (float2(temp_output_278_0 , 0.0));
				float2 temp_output_243_0 = ( temp_output_222_0 + appendResult276 );
				float temp_output_1_0_g6316 = tex2D( _D_new, temp_output_243_0 ).r;
				float temp_output_66_0_g6275 = ( 0.2980392 / temp_output_1_0_g6316 );
				float3 appendResult73_g6275 = (float3(( ( ( temp_output_243_0 - float2( 0.5,0.5 ) ) * temp_output_66_0_g6275 ) * _SomulateDepthCamF ) , temp_output_66_0_g6275));
				float3 rotatedValue97_g6275 = RotateAroundAxis( float3( 0,0,0 ), appendResult73_g6275, float3(0,0,1), break95_g6275.z );
				float3 rotatedValue86_g6275 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue97_g6275, float3(1,0,0), break95_g6275.x );
				float3 rotatedValue84_g6275 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue86_g6275, float3(0,1,0), break95_g6275.y );
				float3 temp_output_258_0 = ( ( ( rotatedValue84_g6280 + _CamOutPosition ) + _PositionOffset ) - ( ( rotatedValue84_g6275 + _CamOutPosition ) + _PositionOffset ) );
				float3 normalizeResult261 = normalize( cross( temp_output_259_0 , temp_output_258_0 ) );
				float3 temp_output_265_0 = ( normalizeResult261 + float3( 0,0,0 ) );
				float3 normalizeResult20_g6321 = normalize( temp_output_53_0_g6321 );
				float dotResult71_g6321 = dot( temp_output_265_0 , ( -1 * normalizeResult20_g6321 ) );
				float clampResult99_g6321 = clamp( dotResult71_g6321 , 0.0 , 1.0 );
				float clampResult111_g6321 = clamp( pow( clampResult99_g6321 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_315_62 = ( abs( ( length( temp_output_53_0_g6321 ) - ( ( _DepthK / tex2DNode80_g6321.r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g6321 : 0.0 );
				float3 temp_output_56_0_g6313 = temp_output_223_0;
				float3 temp_output_57_0_g6313 = _PositionOffset;
				float3 temp_output_61_0_g6313 = _Camera2Position;
				float3 temp_output_53_0_g6313 = ( ( temp_output_56_0_g6313 - temp_output_57_0_g6313 ) - temp_output_61_0_g6313 );
				float3 break35_g6314 = ( ( ( _Camera2Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g6314 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g6313 - temp_output_57_0_g6313 ) - temp_output_61_0_g6313 ), float3(0,1,0), break35_g6314.y );
				float3 rotatedValue39_g6314 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g6314, float3(1,0,0), break35_g6314.x );
				float3 rotatedValue33_g6314 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g6314, float3(0,0,1), break35_g6314.z );
				float3 break44_g6314 = rotatedValue33_g6314;
				float2 appendResult31_g6314 = (float2(break44_g6314.x , break44_g6314.y));
				float2 temp_output_162_0_g6313 = ( ( ( appendResult31_g6314 / _InputColorCameraF ) / break44_g6314.z ) + float2( 0.5,0.5 ) );
				float4 tex2DNode80_g6313 = tex2D( _D_2, temp_output_162_0_g6313 );
				float3 normalizeResult20_g6313 = normalize( temp_output_53_0_g6313 );
				float dotResult71_g6313 = dot( temp_output_265_0 , ( -1 * normalizeResult20_g6313 ) );
				float clampResult99_g6313 = clamp( dotResult71_g6313 , 0.0 , 1.0 );
				float clampResult111_g6313 = clamp( pow( clampResult99_g6313 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_309_62 = ( abs( ( length( temp_output_53_0_g6313 ) - ( ( _DepthK / tex2DNode80_g6313.r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g6313 : 0.0 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( _ShowNormalOnly == 0.0 ? ( _ShowDepthOnly == 0.0 ? ( temp_output_313_0 >= 100.0 ? _BackgroundColor : ( ( ( temp_output_315_62 * tex2D( _RGB_1, temp_output_162_0_g6321 ) ) + ( temp_output_309_62 * tex2D( _RGB_2, temp_output_162_0_g6313 ) ) + ( _EmptyWeight * _BackgroundColor ) ) / ( temp_output_315_62 + temp_output_309_62 + _EmptyWeight ) ) ) : ( pow( max( ( tex2DNode162 + -0.25 ) , float4( 0,0,0,0 ) ) , 3.0 ) * 100.0 ) ) : float4( temp_output_265_0 , 0.0 ) ).rgb;
				float Alpha = ( ( 0 + 1 ) * _Alpha );
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BackgroundColor;
			float3 _Camera1Rotation;
			float3 _Camera2Rotation;
			float3 _CamOutRotation;
			float3 _PositionOffset;
			float3 _CamOutPosition;
			float3 _Camera2Position;
			float3 _Camera1Position;
			float _NormalCoeff;
			float _NormalCalculateDelta;
			float _OcculusionTolerance;
			float _DropOcculusion;
			float _ShowNormalOnly;
			float _InputColorCameraF;
			float _EmptyWeight;
			float _DepthK;
			float _SomulateDepthCamF;
			float _ShowDepthOnly;
			float _DepthB;
			float _Alpha;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = ( ( 0 + 1 ) * _Alpha );
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BackgroundColor;
			float3 _Camera1Rotation;
			float3 _Camera2Rotation;
			float3 _CamOutRotation;
			float3 _PositionOffset;
			float3 _CamOutPosition;
			float3 _Camera2Position;
			float3 _Camera1Position;
			float _NormalCoeff;
			float _NormalCalculateDelta;
			float _OcculusionTolerance;
			float _DropOcculusion;
			float _ShowNormalOnly;
			float _InputColorCameraF;
			float _EmptyWeight;
			float _DepthK;
			float _SomulateDepthCamF;
			float _ShowDepthOnly;
			float _DepthB;
			float _Alpha;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = ( ( 0 + 1 ) * _Alpha );
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18912
2560;0;2560;1371;2883.164;1925.914;4.632093;True;False
Node;AmplifyShaderEditor.RangedFloatNode;228;2168.984,543.8082;Inherit;False;Property;_Alpha;Alpha;28;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;262;-971.4815,978.0989;Inherit;False;2070.279;1374.249;Calculate Normal;25;276;274;273;275;242;240;243;241;261;254;259;256;258;269;257;268;267;270;260;255;265;277;278;279;280;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;225;-951.4252,338.9973;Inherit;False;1047.872;479.1362;Calculate Depth At Current Pixel;4;179;163;162;222;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;175;2237.169,315.5773;Inherit;False;2;2;0;INT;0;False;1;INT;1;False;1;INT;0
Node;AmplifyShaderEditor.CommentaryNode;224;2254.002,-591.3254;Inherit;False;713.1982;596.9813;Cut Off Background;3;209;208;207;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;285;1627.622,-104.6521;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;230;2384.662,191.8896;Inherit;False;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;3;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;264;3636.687,-398.8475;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;256;-108.8295,1861.916;Inherit;False;CameraUVDepthToWorldPose;24;;6281;42ac843fedfdbdb46a6d27eb7070463f;0;6;65;FLOAT2;0,0;False;66;FLOAT;0;False;102;FLOAT3;0,0,0;False;99;FLOAT3;0,0,0;False;96;FLOAT3;0,0,0;False;70;FLOAT;1.1543;False;1;FLOAT3;104
Node;AmplifyShaderEditor.DynamicAppendNode;274;-785.6127,1211.691;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;273;-694.6127,1096.691;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;242;-343.9635,1070.277;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;255;-760.4313,1861.916;Inherit;False;CameraUVDepthToWorldPose;24;;6277;42ac843fedfdbdb46a6d27eb7070463f;0;6;65;FLOAT2;0,0;False;66;FLOAT;0;False;102;FLOAT3;0,0,0;False;99;FLOAT3;0,0,0;False;96;FLOAT3;0,0,0;False;70;FLOAT;1.1543;False;1;FLOAT3;104
Node;AmplifyShaderEditor.Vector3Node;197;-1661.892,470.1374;Inherit;False;Property;_CamOutRotation;CamOutRotation;33;0;Create;True;0;0;0;False;0;False;0,0,0;0,332.0523,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;254;-424.2793,1595.81;Inherit;False;CameraUVDepthToWorldPose;24;;6280;42ac843fedfdbdb46a6d27eb7070463f;0;6;65;FLOAT2;0,0;False;66;FLOAT;0;False;102;FLOAT3;0,0,0;False;99;FLOAT3;0,0,0;False;96;FLOAT3;0,0,0;False;70;FLOAT;1.1543;False;1;FLOAT3;104
Node;AmplifyShaderEditor.CrossProductOpNode;260;738.5176,1910.261;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;236;1872.671,246.2998;Inherit;False;Constant;_Float4;Float 4;16;0;Create;True;0;0;0;False;0;False;-0.25;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;237;2217.671,136.2998;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;275;-588.6127,1201.691;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;276;-687.6127,1307.691;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;267;62.04317,1026.216;Inherit;True;Property;_TextureSample2;Texture Sample 2;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;279;459.276,1754.901;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;270;65.51119,1282.921;Inherit;True;Property;_TextureSample5;Texture Sample 5;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;313;-118.1819,462.3508;Inherit;False;F256ToDepth;0;;6319;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;312;902.8022,1162.431;Inherit;False;F256ToDepth;0;;6318;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;311;635.8953,1166.648;Inherit;False;F256ToDepth;0;;6317;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;310;772.1322,1281.957;Inherit;False;F256ToDepth;0;;6316;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;309;1337.355,-110.7148;Inherit;False;SingleCameraMapping;5;;6313;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;297;662.7538,79.87646;Inherit;True;Property;_D_2;D_2;41;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;008ecc74e3a374dc7b0378989802d355;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleDivideOpNode;291;2089.993,-256.5041;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;269;-97.7545,1159.17;Inherit;True;Property;_TextureSample4;Texture Sample 4;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;243;-336.568,1307.994;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;280;450.276,2069.901;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;265;895.0337,1560.81;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;278;-931.1108,1196.283;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;240;-220.9456,1177.134;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;257;-411.4462,2152.331;Inherit;False;CameraUVDepthToWorldPose;24;;6275;42ac843fedfdbdb46a6d27eb7070463f;0;6;65;FLOAT2;0,0;False;66;FLOAT;0;False;102;FLOAT3;0,0,0;False;99;FLOAT3;0,0,0;False;96;FLOAT3;0,0,0;False;70;FLOAT;1.1543;False;1;FLOAT3;104
Node;AmplifyShaderEditor.SimpleAddOpNode;241;-431.1143,1189.24;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-1,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;314;774.6699,1036.566;Inherit;False;F256ToDepth;0;;6320;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;277;-969.1108,1028.283;Inherit;False;Property;_NormalCalculateDelta;NormalCalculateDelta;29;0;Create;True;0;0;0;False;0;False;0.01;0.003;0.0001;0.04;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;162;-412.0383,457.8;Inherit;True;Property;_Depthj;Depthj;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;268;273.1627,1150.516;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;239;3230.13,-390.874;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;169;939.8244,-356.8259;Inherit;False;Property;_Camera1Position;Camera 1 Position;42;0;Create;True;0;0;0;False;0;False;0,0,0;0,1.8,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;179;-914.2109,624.9706;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;235;2061.418,147.3004;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;290;1934.993,-131.5041;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;168;936.9754,-514.4147;Inherit;False;Property;_Camera1Rotation;Camera 1 Rotation;44;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;196;-1672.639,318.8962;Inherit;False;Property;_CamOutPosition;CamOutPosition;32;0;Create;True;0;0;0;False;0;False;0,0,0;0.443,1.827,-0.835;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;231;2720.642,174.8254;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;258;311.9174,1752.561;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;287;1650.915,300.7698;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;222;-727.4288,625.5374;Inherit;False;WorldPoseToCameraUV;34;;6254;be95621c7f5bc49b282fe3fca847dbd7;0;5;63;FLOAT3;0,0,0;False;56;FLOAT3;0,0,0;False;22;FLOAT3;0,0,0;False;64;FLOAT;1.1543;False;62;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;296;919.7538,-723.1235;Inherit;True;Property;_D_1;D_1;39;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;0146383e3995643be92047c1c3fd405d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;284;1671.922,-613.7521;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;209;2354.844,-459.0572;Inherit;False;Property;_BackgroundColor;BackgroundColor;30;0;Create;True;0;0;0;False;0;False;0.3490566,0.3490566,0.3490566,0;0.3490561,0.3490561,0.3490561,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;223;282.2451,95.90737;Inherit;False;CamDepthToWorldPosition;-1;;6257;a9d725c4349ce4106bfa1039b7647c13;0;3;9;FLOAT;0;False;27;FLOAT3;0,0,0;False;31;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;289;1362.993,314.4959;Inherit;False;Property;_EmptyWeight;EmptyWeight;48;0;Create;True;0;0;0;False;0;False;0.01;0.001;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;232;2385.642,81.82544;Float;False;Constant;_Float1;Float 1;16;0;Create;True;0;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;198;-1733.582,625.7181;Inherit;False;Property;_SomulateDepthCamF;SomulateDepthCamF;31;0;Create;True;0;0;0;False;0;False;0;0.955;0.5;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;238;3037.13,-500.874;Inherit;False;Property;_ShowDepthOnly;Show Depth Only;3;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;170;-1652.17,160.8371;Inherit;False;Property;_PositionOffset;PositionOffset;47;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;227;2584.617,350.9117;Inherit;False;2;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;172;883.8409,119.2805;Inherit;False;Property;_Camera2Rotation;Camera 2 Rotation;43;0;Create;True;0;0;0;False;0;False;0,0,0;0,315,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;263;3440.687,-506.8475;Inherit;False;Property;_ShowNormalOnly;Show Normal Only;4;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;259;297.5175,2070.061;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;315;1369.28,-612.3074;Inherit;False;SingleCameraMapping;5;;6321;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;208;2634.239,-405.2954;Inherit;False;Constant;_Float2;Float 2;13;0;Create;True;0;0;0;False;0;False;100;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;166;919.8513,-914.9819;Inherit;True;Property;_RGB_1;RGB_1;38;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;6e525e0933ba04ebe9d0f3860234333d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleAddOpNode;286;1929.115,-339.3301;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;261;904.6271,1907.464;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;163;-698.9647,409.2388;Inherit;True;Property;_D_new;D_new;46;0;Create;True;0;0;0;False;0;False;0146383e3995643be92047c1c3fd405d;556df4fd703fd1044b99de202bc57d36;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector3Node;171;883.004,270.5617;Inherit;False;Property;_Camera2Position;Camera 2 Position;45;0;Create;True;0;0;0;False;0;False;0,0,0;0.824,1.781,-0.752;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Compare;207;2697.103,-230.2889;Inherit;False;3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;226;875.116,-97.71014;Inherit;True;Property;_RGB_2;RGB_2;40;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;3d7039e2d91fd44f68f4f05c291fb0a7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;624.3956,470.9371;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;3872.389,-94.2753;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;DepthToRender;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;285;0;309;62
WireConnection;285;1;309;0
WireConnection;230;0;237;0
WireConnection;264;0;263;0
WireConnection;264;2;239;0
WireConnection;264;3;265;0
WireConnection;256;65;240;0
WireConnection;256;66;312;0
WireConnection;256;102;170;0
WireConnection;256;99;196;0
WireConnection;256;96;197;0
WireConnection;256;70;198;0
WireConnection;274;1;278;0
WireConnection;273;0;277;0
WireConnection;242;0;222;0
WireConnection;242;1;273;0
WireConnection;255;65;241;0
WireConnection;255;66;311;0
WireConnection;255;102;170;0
WireConnection;255;99;196;0
WireConnection;255;96;197;0
WireConnection;255;70;198;0
WireConnection;254;65;242;0
WireConnection;254;66;314;0
WireConnection;254;102;170;0
WireConnection;254;99;196;0
WireConnection;254;96;197;0
WireConnection;254;70;198;0
WireConnection;260;0;259;0
WireConnection;260;1;258;0
WireConnection;237;0;235;0
WireConnection;275;0;277;0
WireConnection;276;0;278;0
WireConnection;267;0;163;0
WireConnection;267;1;222;0
WireConnection;279;0;258;0
WireConnection;270;0;163;0
WireConnection;270;1;243;0
WireConnection;313;1;162;0
WireConnection;312;1;268;0
WireConnection;311;1;269;0
WireConnection;310;1;270;0
WireConnection;309;55;226;0
WireConnection;309;79;297;0
WireConnection;309;56;223;0
WireConnection;309;57;170;0
WireConnection;309;59;265;0
WireConnection;309;60;172;0
WireConnection;309;61;171;0
WireConnection;291;0;286;0
WireConnection;291;1;290;0
WireConnection;269;0;163;0
WireConnection;269;1;241;0
WireConnection;243;0;222;0
WireConnection;243;1;276;0
WireConnection;280;0;259;0
WireConnection;265;0;261;0
WireConnection;278;0;277;0
WireConnection;240;0;222;0
WireConnection;240;1;275;0
WireConnection;257;65;243;0
WireConnection;257;66;310;0
WireConnection;257;102;170;0
WireConnection;257;99;196;0
WireConnection;257;96;197;0
WireConnection;257;70;198;0
WireConnection;241;0;222;0
WireConnection;241;1;274;0
WireConnection;314;1;267;0
WireConnection;162;0;163;0
WireConnection;162;1;222;0
WireConnection;268;0;163;0
WireConnection;268;1;240;0
WireConnection;239;0;238;0
WireConnection;239;2;207;0
WireConnection;239;3;231;0
WireConnection;235;0;162;0
WireConnection;235;1;236;0
WireConnection;290;0;315;62
WireConnection;290;1;309;62
WireConnection;290;2;289;0
WireConnection;231;0;230;0
WireConnection;231;1;232;0
WireConnection;258;0;254;104
WireConnection;258;1;257;104
WireConnection;287;0;289;0
WireConnection;287;1;209;0
WireConnection;222;63;179;0
WireConnection;222;56;170;0
WireConnection;222;22;197;0
WireConnection;222;64;198;0
WireConnection;222;62;196;0
WireConnection;284;0;315;62
WireConnection;284;1;315;0
WireConnection;223;9;313;0
WireConnection;223;27;197;0
WireConnection;223;31;196;0
WireConnection;227;0;175;0
WireConnection;227;1;228;0
WireConnection;259;0;256;104
WireConnection;259;1;255;104
WireConnection;315;55;166;0
WireConnection;315;79;296;0
WireConnection;315;56;223;0
WireConnection;315;57;170;0
WireConnection;315;59;265;0
WireConnection;315;60;168;0
WireConnection;315;61;169;0
WireConnection;286;0;284;0
WireConnection;286;1;285;0
WireConnection;286;2;287;0
WireConnection;261;0;260;0
WireConnection;207;0;313;0
WireConnection;207;1;208;0
WireConnection;207;2;209;0
WireConnection;207;3;291;0
WireConnection;1;2;264;0
WireConnection;1;3;227;0
ASEEND*/
//CHKSM=7CF3237092537A2C639FFA68A2D965B3D6DC77B1