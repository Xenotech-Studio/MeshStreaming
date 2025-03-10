// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "NovelView"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin][Toggle]_UseColor_1("UseColor_1", Float) = 0
		[Toggle]_UseColor_2("UseColor_2", Float) = 0
		[Toggle]_UseCam_1("UseCam_1", Float) = 0
		[Toggle]_UseCam_2("UseCam_2", Float) = 0
		_MaxDepthDelta("MaxDepthDelta", Float) = 4
		_RGB_1("RGB_1", 2D) = "white" {}
		_D_1("D_1", 2D) = "white" {}
		_Camera1Position("Camera 1 Position", Vector) = (0,0,0,0)
		_Camera1Rotation("Camera 1 Rotation", Vector) = (0,0,0,0)
		_RGB_2("RGB_2", 2D) = "white" {}
		_D_2("D_2", 2D) = "white" {}
		_Camera2Position("Camera 2 Position", Vector) = (0,0,0,0)
		_Camera2Rotation("Camera 2 Rotation", Vector) = (0,0,0,0)
		_PositionOffset("PositionOffset", Vector) = (0,0,0,0)
		_CameraF("Camera F", Range( 1 , 2)) = 1.1543
		[Toggle]_Sub1("Sub1", Float) = 0
		[Toggle]_Sub2("Sub2", Float) = 0
		[Toggle]_Sub3("Sub3", Float) = 0
		_CamOutRotation("CamOutRotation", Vector) = (0,0,0,0)
		_CamOutPosition("CamOutPosition", Vector) = (0,0,0,0)
		[ASEEnd]_InputColorCameraF("Input Color Camera F", Range( 1 , 2)) = 1.1543

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

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
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
			
			Blend One Zero, One Zero
			ZWrite On
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
			float3 _Camera1Rotation;
			float3 _Camera2Position;
			float3 _CamOutPosition;
			float3 _PositionOffset;
			float3 _Camera2Rotation;
			float3 _Camera1Position;
			float3 _CamOutRotation;
			float _UseCam_2;
			float _CameraF;
			float _UseColor_1;
			float _Sub3;
			float _Sub2;
			float _Sub1;
			float _UseCam_1;
			float _MaxDepthDelta;
			float _InputColorCameraF;
			float _UseColor_2;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _D_1;
			sampler2D _D_2;
			sampler2D _RGB_1;
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
				float3 break108 = ( _CamOutPosition - _PositionOffset );
				float2 appendResult110 = (float2(break108.x , break108.z));
				float temp_output_112_0 = ( _MaxDepthDelta + length( appendResult110 ) );
				float3 temp_output_12_0_g1235 = _Camera1Rotation;
				float3 break61_g1284 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1308 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1260 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1324 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_13_0_g1235 = temp_output_112_0;
				float temp_output_118_0_g1235 = ( 0.1 * temp_output_13_0_g1235 );
				float temp_output_12_0_g1249 = temp_output_118_0_g1235;
				float temp_output_138_10_g1235 = temp_output_12_0_g1249;
				float3 temp_output_419_0_g1235 = _CamOutRotation;
				float3 break26_g1323 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1323 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1323.z );
				float3 rotatedValue16_g1323 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1323, float3(1,0,0), break26_g1323.x );
				float3 rotatedValue14_g1323 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1323, float3(0,1,0), break26_g1323.y );
				float3 normalizeResult30_g1323 = normalize( rotatedValue14_g1323 );
				float3 temp_output_418_0_g1235 = _CamOutPosition;
				float3 temp_output_31_0_g1323 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1323 = normalize( ( WorldPosition - temp_output_31_0_g1323 ) );
				float dotResult29_g1323 = dot( normalizeResult30_g1323 , normalizeResult8_g1323 );
				float3 temp_output_24_0_g1322 = ( ( ( temp_output_138_10_g1235 / dotResult29_g1323 ) * normalizeResult8_g1323 ) + temp_output_31_0_g1323 );
				float3 temp_output_10_0_g1235 = _PositionOffset;
				float3 temp_output_9_0_g1235 = _Camera1Position;
				float3 temp_output_10_0_g1322 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1324 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1322 - temp_output_10_0_g1235 ) - temp_output_10_0_g1322 ), float3(0,1,0), break61_g1324.y );
				float3 rotatedValue33_g1324 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1324, float3(1,0,0), break61_g1324.x );
				float3 rotatedValue28_g1324 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1324, float3(0,0,1), break61_g1324.z );
				float3 break36_g1324 = rotatedValue28_g1324;
				float2 appendResult27_g1324 = (float2(break36_g1324.x , break36_g1324.y));
				float4 tex2DNode7_g1324 = tex2D( _D_1, ( ( ( appendResult27_g1324 / _CameraF ) / break36_g1324.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1325 = tex2DNode7_g1324.r;
				float3 break61_g1288 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1238 = ( temp_output_12_0_g1249 + ( ( temp_output_13_0_g1235 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g1235 = temp_output_12_0_g1238;
				float3 break26_g1287 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1287 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1287.z );
				float3 rotatedValue16_g1287 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1287, float3(1,0,0), break26_g1287.x );
				float3 rotatedValue14_g1287 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1287, float3(0,1,0), break26_g1287.y );
				float3 normalizeResult30_g1287 = normalize( rotatedValue14_g1287 );
				float3 temp_output_31_0_g1287 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1287 = normalize( ( WorldPosition - temp_output_31_0_g1287 ) );
				float dotResult29_g1287 = dot( normalizeResult30_g1287 , normalizeResult8_g1287 );
				float3 temp_output_24_0_g1286 = ( ( ( temp_output_136_10_g1235 / dotResult29_g1287 ) * normalizeResult8_g1287 ) + temp_output_31_0_g1287 );
				float3 temp_output_10_0_g1286 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1288 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1286 - temp_output_10_0_g1235 ) - temp_output_10_0_g1286 ), float3(0,1,0), break61_g1288.y );
				float3 rotatedValue33_g1288 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1288, float3(1,0,0), break61_g1288.x );
				float3 rotatedValue28_g1288 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1288, float3(0,0,1), break61_g1288.z );
				float3 break36_g1288 = rotatedValue28_g1288;
				float2 appendResult27_g1288 = (float2(break36_g1288.x , break36_g1288.y));
				float4 tex2DNode7_g1288 = tex2D( _D_1, ( ( ( appendResult27_g1288 / _CameraF ) / break36_g1288.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1289 = tex2DNode7_g1288.r;
				float3 break61_g1300 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1240 = ( temp_output_12_0_g1238 + ( ( temp_output_13_0_g1235 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g1235 = temp_output_12_0_g1240;
				float3 break26_g1299 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1299 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1299.z );
				float3 rotatedValue16_g1299 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1299, float3(1,0,0), break26_g1299.x );
				float3 rotatedValue14_g1299 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1299, float3(0,1,0), break26_g1299.y );
				float3 normalizeResult30_g1299 = normalize( rotatedValue14_g1299 );
				float3 temp_output_31_0_g1299 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1299 = normalize( ( WorldPosition - temp_output_31_0_g1299 ) );
				float dotResult29_g1299 = dot( normalizeResult30_g1299 , normalizeResult8_g1299 );
				float3 temp_output_24_0_g1298 = ( ( ( temp_output_137_10_g1235 / dotResult29_g1299 ) * normalizeResult8_g1299 ) + temp_output_31_0_g1299 );
				float3 temp_output_10_0_g1298 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1300 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1298 - temp_output_10_0_g1235 ) - temp_output_10_0_g1298 ), float3(0,1,0), break61_g1300.y );
				float3 rotatedValue33_g1300 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1300, float3(1,0,0), break61_g1300.x );
				float3 rotatedValue28_g1300 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1300, float3(0,0,1), break61_g1300.z );
				float3 break36_g1300 = rotatedValue28_g1300;
				float2 appendResult27_g1300 = (float2(break36_g1300.x , break36_g1300.y));
				float4 tex2DNode7_g1300 = tex2D( _D_1, ( ( ( appendResult27_g1300 / _CameraF ) / break36_g1300.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1301 = tex2DNode7_g1300.r;
				float3 break61_g1296 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1253 = ( temp_output_12_0_g1240 + ( ( temp_output_13_0_g1235 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g1235 = temp_output_12_0_g1253;
				float3 break26_g1295 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1295 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1295.z );
				float3 rotatedValue16_g1295 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1295, float3(1,0,0), break26_g1295.x );
				float3 rotatedValue14_g1295 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1295, float3(0,1,0), break26_g1295.y );
				float3 normalizeResult30_g1295 = normalize( rotatedValue14_g1295 );
				float3 temp_output_31_0_g1295 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1295 = normalize( ( WorldPosition - temp_output_31_0_g1295 ) );
				float dotResult29_g1295 = dot( normalizeResult30_g1295 , normalizeResult8_g1295 );
				float3 temp_output_24_0_g1294 = ( ( ( temp_output_142_10_g1235 / dotResult29_g1295 ) * normalizeResult8_g1295 ) + temp_output_31_0_g1295 );
				float3 temp_output_10_0_g1294 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1296 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1294 - temp_output_10_0_g1235 ) - temp_output_10_0_g1294 ), float3(0,1,0), break61_g1296.y );
				float3 rotatedValue33_g1296 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1296, float3(1,0,0), break61_g1296.x );
				float3 rotatedValue28_g1296 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1296, float3(0,0,1), break61_g1296.z );
				float3 break36_g1296 = rotatedValue28_g1296;
				float2 appendResult27_g1296 = (float2(break36_g1296.x , break36_g1296.y));
				float4 tex2DNode7_g1296 = tex2D( _D_1, ( ( ( appendResult27_g1296 / _CameraF ) / break36_g1296.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1297 = tex2DNode7_g1296.r;
				float3 break61_g1268 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1251 = ( temp_output_12_0_g1253 + ( ( temp_output_13_0_g1235 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g1235 = temp_output_12_0_g1251;
				float3 break26_g1267 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1267 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1267.z );
				float3 rotatedValue16_g1267 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1267, float3(1,0,0), break26_g1267.x );
				float3 rotatedValue14_g1267 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1267, float3(0,1,0), break26_g1267.y );
				float3 normalizeResult30_g1267 = normalize( rotatedValue14_g1267 );
				float3 temp_output_31_0_g1267 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1267 = normalize( ( WorldPosition - temp_output_31_0_g1267 ) );
				float dotResult29_g1267 = dot( normalizeResult30_g1267 , normalizeResult8_g1267 );
				float3 temp_output_24_0_g1266 = ( ( ( temp_output_144_10_g1235 / dotResult29_g1267 ) * normalizeResult8_g1267 ) + temp_output_31_0_g1267 );
				float3 temp_output_10_0_g1266 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1268 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1266 - temp_output_10_0_g1235 ) - temp_output_10_0_g1266 ), float3(0,1,0), break61_g1268.y );
				float3 rotatedValue33_g1268 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1268, float3(1,0,0), break61_g1268.x );
				float3 rotatedValue28_g1268 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1268, float3(0,0,1), break61_g1268.z );
				float3 break36_g1268 = rotatedValue28_g1268;
				float2 appendResult27_g1268 = (float2(break36_g1268.x , break36_g1268.y));
				float4 tex2DNode7_g1268 = tex2D( _D_1, ( ( ( appendResult27_g1268 / _CameraF ) / break36_g1268.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1269 = tex2DNode7_g1268.r;
				float3 break61_g1328 = ( ( ( temp_output_12_0_g1235 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1248 = ( temp_output_12_0_g1251 + ( ( temp_output_13_0_g1235 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g1235 = temp_output_12_0_g1248;
				float3 break26_g1327 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1327 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1327.z );
				float3 rotatedValue16_g1327 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1327, float3(1,0,0), break26_g1327.x );
				float3 rotatedValue14_g1327 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1327, float3(0,1,0), break26_g1327.y );
				float3 normalizeResult30_g1327 = normalize( rotatedValue14_g1327 );
				float3 temp_output_31_0_g1327 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1327 = normalize( ( WorldPosition - temp_output_31_0_g1327 ) );
				float dotResult29_g1327 = dot( normalizeResult30_g1327 , normalizeResult8_g1327 );
				float3 temp_output_24_0_g1326 = ( ( ( temp_output_146_10_g1235 / dotResult29_g1327 ) * normalizeResult8_g1327 ) + temp_output_31_0_g1327 );
				float3 temp_output_10_0_g1326 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1328 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1326 - temp_output_10_0_g1235 ) - temp_output_10_0_g1326 ), float3(0,1,0), break61_g1328.y );
				float3 rotatedValue33_g1328 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1328, float3(1,0,0), break61_g1328.x );
				float3 rotatedValue28_g1328 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1328, float3(0,0,1), break61_g1328.z );
				float3 break36_g1328 = rotatedValue28_g1328;
				float2 appendResult27_g1328 = (float2(break36_g1328.x , break36_g1328.y));
				float4 tex2DNode7_g1328 = tex2D( _D_1, ( ( ( appendResult27_g1328 / _CameraF ) / break36_g1328.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1329 = tex2DNode7_g1328.r;
				float temp_output_417_0_g1235 = ( ( 0.2980392 / temp_output_1_0_g1325 ) >= distance( temp_output_10_0_g1322 , temp_output_24_0_g1322 ) ? ( ( 0.2980392 / temp_output_1_0_g1289 ) >= distance( temp_output_10_0_g1286 , temp_output_24_0_g1286 ) ? ( ( 0.2980392 / temp_output_1_0_g1301 ) >= distance( temp_output_10_0_g1298 , temp_output_24_0_g1298 ) ? ( ( 0.2980392 / temp_output_1_0_g1297 ) >= distance( temp_output_10_0_g1294 , temp_output_24_0_g1294 ) ? ( ( 0.2980392 / temp_output_1_0_g1269 ) >= distance( temp_output_10_0_g1266 , temp_output_24_0_g1266 ) ? ( ( 0.2980392 / temp_output_1_0_g1329 ) >= distance( temp_output_10_0_g1326 , temp_output_24_0_g1326 ) ? 100.0 : temp_output_146_10_g1235 ) : temp_output_144_10_g1235 ) : temp_output_142_10_g1235 ) : temp_output_137_10_g1235 ) : temp_output_136_10_g1235 ) : temp_output_138_10_g1235 );
				float temp_output_284_0_g1235 = ( temp_output_417_0_g1235 - temp_output_118_0_g1235 );
				float temp_output_286_0_g1235 = ( ( ( ( temp_output_417_0_g1235 - 0.0 ) + temp_output_284_0_g1235 ) / 2 ) + 0.0 );
				float temp_output_7_0_g1250 = temp_output_286_0_g1235;
				float temp_output_337_10_g1235 = temp_output_7_0_g1250;
				float3 break26_g1259 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1259 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1259.z );
				float3 rotatedValue16_g1259 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1259, float3(1,0,0), break26_g1259.x );
				float3 rotatedValue14_g1259 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1259, float3(0,1,0), break26_g1259.y );
				float3 normalizeResult30_g1259 = normalize( rotatedValue14_g1259 );
				float3 temp_output_31_0_g1259 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1259 = normalize( ( WorldPosition - temp_output_31_0_g1259 ) );
				float dotResult29_g1259 = dot( normalizeResult30_g1259 , normalizeResult8_g1259 );
				float3 temp_output_24_0_g1258 = ( ( ( temp_output_337_10_g1235 / dotResult29_g1259 ) * normalizeResult8_g1259 ) + temp_output_31_0_g1259 );
				float3 temp_output_10_0_g1258 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1260 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1258 - temp_output_10_0_g1235 ) - temp_output_10_0_g1258 ), float3(0,1,0), break61_g1260.y );
				float3 rotatedValue33_g1260 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1260, float3(1,0,0), break61_g1260.x );
				float3 rotatedValue28_g1260 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1260, float3(0,0,1), break61_g1260.z );
				float3 break36_g1260 = rotatedValue28_g1260;
				float2 appendResult27_g1260 = (float2(break36_g1260.x , break36_g1260.y));
				float4 tex2DNode7_g1260 = tex2D( _D_1, ( ( ( appendResult27_g1260 / _CameraF ) / break36_g1260.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1261 = tex2DNode7_g1260.r;
				float temp_output_2_0_g1250 = ( ( temp_output_7_0_g1250 - ( temp_output_284_0_g1235 + 0.0 ) ) / 2 );
				float temp_output_8_0_g1250 = ( temp_output_7_0_g1250 + temp_output_2_0_g1250 );
				float temp_output_9_0_g1250 = ( temp_output_7_0_g1250 - temp_output_2_0_g1250 );
				float temp_output_400_0_g1235 = ( ( 0.2980392 / temp_output_1_0_g1261 ) >= distance( temp_output_10_0_g1258 , temp_output_24_0_g1258 ) ? ( temp_output_8_0_g1250 > temp_output_9_0_g1250 ? temp_output_8_0_g1250 : temp_output_9_0_g1250 ) : ( temp_output_8_0_g1250 > temp_output_9_0_g1250 ? temp_output_9_0_g1250 : temp_output_8_0_g1250 ) );
				float temp_output_7_0_g1252 = temp_output_400_0_g1235;
				float temp_output_341_10_g1235 = temp_output_7_0_g1252;
				float3 break26_g1307 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1307 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1307.z );
				float3 rotatedValue16_g1307 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1307, float3(1,0,0), break26_g1307.x );
				float3 rotatedValue14_g1307 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1307, float3(0,1,0), break26_g1307.y );
				float3 normalizeResult30_g1307 = normalize( rotatedValue14_g1307 );
				float3 temp_output_31_0_g1307 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1307 = normalize( ( WorldPosition - temp_output_31_0_g1307 ) );
				float dotResult29_g1307 = dot( normalizeResult30_g1307 , normalizeResult8_g1307 );
				float3 temp_output_24_0_g1306 = ( ( ( temp_output_341_10_g1235 / dotResult29_g1307 ) * normalizeResult8_g1307 ) + temp_output_31_0_g1307 );
				float3 temp_output_10_0_g1306 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1308 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1306 - temp_output_10_0_g1235 ) - temp_output_10_0_g1306 ), float3(0,1,0), break61_g1308.y );
				float3 rotatedValue33_g1308 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1308, float3(1,0,0), break61_g1308.x );
				float3 rotatedValue28_g1308 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1308, float3(0,0,1), break61_g1308.z );
				float3 break36_g1308 = rotatedValue28_g1308;
				float2 appendResult27_g1308 = (float2(break36_g1308.x , break36_g1308.y));
				float4 tex2DNode7_g1308 = tex2D( _D_1, ( ( ( appendResult27_g1308 / _CameraF ) / break36_g1308.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1309 = tex2DNode7_g1308.r;
				float temp_output_2_0_g1252 = ( ( temp_output_7_0_g1252 - temp_output_337_10_g1235 ) / 2 );
				float temp_output_8_0_g1252 = ( temp_output_7_0_g1252 + temp_output_2_0_g1252 );
				float temp_output_9_0_g1252 = ( temp_output_7_0_g1252 - temp_output_2_0_g1252 );
				float temp_output_413_0_g1235 = ( ( 0.2980392 / temp_output_1_0_g1309 ) >= distance( temp_output_10_0_g1306 , temp_output_24_0_g1306 ) ? ( temp_output_8_0_g1252 > temp_output_9_0_g1252 ? temp_output_8_0_g1252 : temp_output_9_0_g1252 ) : ( temp_output_8_0_g1252 > temp_output_9_0_g1252 ? temp_output_9_0_g1252 : temp_output_8_0_g1252 ) );
				float temp_output_7_0_g1242 = temp_output_413_0_g1235;
				float temp_output_335_10_g1235 = temp_output_7_0_g1242;
				float3 break26_g1283 = ( ( ( temp_output_419_0_g1235 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1283 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1283.z );
				float3 rotatedValue16_g1283 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1283, float3(1,0,0), break26_g1283.x );
				float3 rotatedValue14_g1283 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1283, float3(0,1,0), break26_g1283.y );
				float3 normalizeResult30_g1283 = normalize( rotatedValue14_g1283 );
				float3 temp_output_31_0_g1283 = temp_output_418_0_g1235;
				float3 normalizeResult8_g1283 = normalize( ( WorldPosition - temp_output_31_0_g1283 ) );
				float dotResult29_g1283 = dot( normalizeResult30_g1283 , normalizeResult8_g1283 );
				float3 temp_output_24_0_g1282 = ( ( ( temp_output_335_10_g1235 / dotResult29_g1283 ) * normalizeResult8_g1283 ) + temp_output_31_0_g1283 );
				float3 temp_output_10_0_g1282 = temp_output_9_0_g1235;
				float3 rotatedValue31_g1284 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1282 - temp_output_10_0_g1235 ) - temp_output_10_0_g1282 ), float3(0,1,0), break61_g1284.y );
				float3 rotatedValue33_g1284 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1284, float3(1,0,0), break61_g1284.x );
				float3 rotatedValue28_g1284 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1284, float3(0,0,1), break61_g1284.z );
				float3 break36_g1284 = rotatedValue28_g1284;
				float2 appendResult27_g1284 = (float2(break36_g1284.x , break36_g1284.y));
				float4 tex2DNode7_g1284 = tex2D( _D_1, ( ( ( appendResult27_g1284 / _CameraF ) / break36_g1284.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1285 = tex2DNode7_g1284.r;
				float temp_output_2_0_g1242 = ( ( temp_output_7_0_g1242 - temp_output_341_10_g1235 ) / 2 );
				float temp_output_8_0_g1242 = ( temp_output_7_0_g1242 + temp_output_2_0_g1242 );
				float temp_output_9_0_g1242 = ( temp_output_7_0_g1242 - temp_output_2_0_g1242 );
				float temp_output_407_0_g1235 = ( ( 0.2980392 / temp_output_1_0_g1285 ) >= distance( temp_output_10_0_g1282 , temp_output_24_0_g1282 ) ? ( temp_output_8_0_g1242 > temp_output_9_0_g1242 ? temp_output_8_0_g1242 : temp_output_9_0_g1242 ) : ( temp_output_8_0_g1242 > temp_output_9_0_g1242 ? temp_output_9_0_g1242 : temp_output_8_0_g1242 ) );
				float temp_output_191_0 = ( _Sub1 > 0.0 ? ( _Sub2 > 0.0 ? ( _Sub3 > 0.0 ? temp_output_407_0_g1235 : temp_output_413_0_g1235 ) : temp_output_400_0_g1235 ) : temp_output_286_0_g1235 );
				float3 temp_output_12_0_g1140 = _Camera2Rotation;
				float3 break61_g1189 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1213 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1165 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g1229 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_13_0_g1140 = temp_output_112_0;
				float temp_output_118_0_g1140 = ( 0.1 * temp_output_13_0_g1140 );
				float temp_output_12_0_g1154 = temp_output_118_0_g1140;
				float temp_output_138_10_g1140 = temp_output_12_0_g1154;
				float3 temp_output_419_0_g1140 = _CamOutRotation;
				float3 break26_g1228 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1228 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1228.z );
				float3 rotatedValue16_g1228 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1228, float3(1,0,0), break26_g1228.x );
				float3 rotatedValue14_g1228 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1228, float3(0,1,0), break26_g1228.y );
				float3 normalizeResult30_g1228 = normalize( rotatedValue14_g1228 );
				float3 temp_output_418_0_g1140 = _CamOutPosition;
				float3 temp_output_31_0_g1228 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1228 = normalize( ( WorldPosition - temp_output_31_0_g1228 ) );
				float dotResult29_g1228 = dot( normalizeResult30_g1228 , normalizeResult8_g1228 );
				float3 temp_output_24_0_g1227 = ( ( ( temp_output_138_10_g1140 / dotResult29_g1228 ) * normalizeResult8_g1228 ) + temp_output_31_0_g1228 );
				float3 temp_output_10_0_g1140 = _PositionOffset;
				float3 temp_output_9_0_g1140 = _Camera2Position;
				float3 temp_output_10_0_g1227 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1229 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1227 - temp_output_10_0_g1140 ) - temp_output_10_0_g1227 ), float3(0,1,0), break61_g1229.y );
				float3 rotatedValue33_g1229 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1229, float3(1,0,0), break61_g1229.x );
				float3 rotatedValue28_g1229 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1229, float3(0,0,1), break61_g1229.z );
				float3 break36_g1229 = rotatedValue28_g1229;
				float2 appendResult27_g1229 = (float2(break36_g1229.x , break36_g1229.y));
				float4 tex2DNode7_g1229 = tex2D( _D_2, ( ( ( appendResult27_g1229 / _CameraF ) / break36_g1229.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1230 = tex2DNode7_g1229.r;
				float3 break61_g1193 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1143 = ( temp_output_12_0_g1154 + ( ( temp_output_13_0_g1140 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g1140 = temp_output_12_0_g1143;
				float3 break26_g1192 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1192 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1192.z );
				float3 rotatedValue16_g1192 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1192, float3(1,0,0), break26_g1192.x );
				float3 rotatedValue14_g1192 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1192, float3(0,1,0), break26_g1192.y );
				float3 normalizeResult30_g1192 = normalize( rotatedValue14_g1192 );
				float3 temp_output_31_0_g1192 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1192 = normalize( ( WorldPosition - temp_output_31_0_g1192 ) );
				float dotResult29_g1192 = dot( normalizeResult30_g1192 , normalizeResult8_g1192 );
				float3 temp_output_24_0_g1191 = ( ( ( temp_output_136_10_g1140 / dotResult29_g1192 ) * normalizeResult8_g1192 ) + temp_output_31_0_g1192 );
				float3 temp_output_10_0_g1191 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1193 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1191 - temp_output_10_0_g1140 ) - temp_output_10_0_g1191 ), float3(0,1,0), break61_g1193.y );
				float3 rotatedValue33_g1193 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1193, float3(1,0,0), break61_g1193.x );
				float3 rotatedValue28_g1193 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1193, float3(0,0,1), break61_g1193.z );
				float3 break36_g1193 = rotatedValue28_g1193;
				float2 appendResult27_g1193 = (float2(break36_g1193.x , break36_g1193.y));
				float4 tex2DNode7_g1193 = tex2D( _D_2, ( ( ( appendResult27_g1193 / _CameraF ) / break36_g1193.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1194 = tex2DNode7_g1193.r;
				float3 break61_g1205 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1145 = ( temp_output_12_0_g1143 + ( ( temp_output_13_0_g1140 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g1140 = temp_output_12_0_g1145;
				float3 break26_g1204 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1204 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1204.z );
				float3 rotatedValue16_g1204 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1204, float3(1,0,0), break26_g1204.x );
				float3 rotatedValue14_g1204 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1204, float3(0,1,0), break26_g1204.y );
				float3 normalizeResult30_g1204 = normalize( rotatedValue14_g1204 );
				float3 temp_output_31_0_g1204 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1204 = normalize( ( WorldPosition - temp_output_31_0_g1204 ) );
				float dotResult29_g1204 = dot( normalizeResult30_g1204 , normalizeResult8_g1204 );
				float3 temp_output_24_0_g1203 = ( ( ( temp_output_137_10_g1140 / dotResult29_g1204 ) * normalizeResult8_g1204 ) + temp_output_31_0_g1204 );
				float3 temp_output_10_0_g1203 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1205 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1203 - temp_output_10_0_g1140 ) - temp_output_10_0_g1203 ), float3(0,1,0), break61_g1205.y );
				float3 rotatedValue33_g1205 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1205, float3(1,0,0), break61_g1205.x );
				float3 rotatedValue28_g1205 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1205, float3(0,0,1), break61_g1205.z );
				float3 break36_g1205 = rotatedValue28_g1205;
				float2 appendResult27_g1205 = (float2(break36_g1205.x , break36_g1205.y));
				float4 tex2DNode7_g1205 = tex2D( _D_2, ( ( ( appendResult27_g1205 / _CameraF ) / break36_g1205.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1206 = tex2DNode7_g1205.r;
				float3 break61_g1201 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1158 = ( temp_output_12_0_g1145 + ( ( temp_output_13_0_g1140 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g1140 = temp_output_12_0_g1158;
				float3 break26_g1200 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1200 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1200.z );
				float3 rotatedValue16_g1200 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1200, float3(1,0,0), break26_g1200.x );
				float3 rotatedValue14_g1200 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1200, float3(0,1,0), break26_g1200.y );
				float3 normalizeResult30_g1200 = normalize( rotatedValue14_g1200 );
				float3 temp_output_31_0_g1200 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1200 = normalize( ( WorldPosition - temp_output_31_0_g1200 ) );
				float dotResult29_g1200 = dot( normalizeResult30_g1200 , normalizeResult8_g1200 );
				float3 temp_output_24_0_g1199 = ( ( ( temp_output_142_10_g1140 / dotResult29_g1200 ) * normalizeResult8_g1200 ) + temp_output_31_0_g1200 );
				float3 temp_output_10_0_g1199 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1201 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1199 - temp_output_10_0_g1140 ) - temp_output_10_0_g1199 ), float3(0,1,0), break61_g1201.y );
				float3 rotatedValue33_g1201 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1201, float3(1,0,0), break61_g1201.x );
				float3 rotatedValue28_g1201 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1201, float3(0,0,1), break61_g1201.z );
				float3 break36_g1201 = rotatedValue28_g1201;
				float2 appendResult27_g1201 = (float2(break36_g1201.x , break36_g1201.y));
				float4 tex2DNode7_g1201 = tex2D( _D_2, ( ( ( appendResult27_g1201 / _CameraF ) / break36_g1201.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1202 = tex2DNode7_g1201.r;
				float3 break61_g1173 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1156 = ( temp_output_12_0_g1158 + ( ( temp_output_13_0_g1140 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g1140 = temp_output_12_0_g1156;
				float3 break26_g1172 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1172 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1172.z );
				float3 rotatedValue16_g1172 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1172, float3(1,0,0), break26_g1172.x );
				float3 rotatedValue14_g1172 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1172, float3(0,1,0), break26_g1172.y );
				float3 normalizeResult30_g1172 = normalize( rotatedValue14_g1172 );
				float3 temp_output_31_0_g1172 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1172 = normalize( ( WorldPosition - temp_output_31_0_g1172 ) );
				float dotResult29_g1172 = dot( normalizeResult30_g1172 , normalizeResult8_g1172 );
				float3 temp_output_24_0_g1171 = ( ( ( temp_output_144_10_g1140 / dotResult29_g1172 ) * normalizeResult8_g1172 ) + temp_output_31_0_g1172 );
				float3 temp_output_10_0_g1171 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1173 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1171 - temp_output_10_0_g1140 ) - temp_output_10_0_g1171 ), float3(0,1,0), break61_g1173.y );
				float3 rotatedValue33_g1173 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1173, float3(1,0,0), break61_g1173.x );
				float3 rotatedValue28_g1173 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1173, float3(0,0,1), break61_g1173.z );
				float3 break36_g1173 = rotatedValue28_g1173;
				float2 appendResult27_g1173 = (float2(break36_g1173.x , break36_g1173.y));
				float4 tex2DNode7_g1173 = tex2D( _D_2, ( ( ( appendResult27_g1173 / _CameraF ) / break36_g1173.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1174 = tex2DNode7_g1173.r;
				float3 break61_g1233 = ( ( ( temp_output_12_0_g1140 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g1153 = ( temp_output_12_0_g1156 + ( ( temp_output_13_0_g1140 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g1140 = temp_output_12_0_g1153;
				float3 break26_g1232 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1232 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1232.z );
				float3 rotatedValue16_g1232 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1232, float3(1,0,0), break26_g1232.x );
				float3 rotatedValue14_g1232 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1232, float3(0,1,0), break26_g1232.y );
				float3 normalizeResult30_g1232 = normalize( rotatedValue14_g1232 );
				float3 temp_output_31_0_g1232 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1232 = normalize( ( WorldPosition - temp_output_31_0_g1232 ) );
				float dotResult29_g1232 = dot( normalizeResult30_g1232 , normalizeResult8_g1232 );
				float3 temp_output_24_0_g1231 = ( ( ( temp_output_146_10_g1140 / dotResult29_g1232 ) * normalizeResult8_g1232 ) + temp_output_31_0_g1232 );
				float3 temp_output_10_0_g1231 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1233 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1231 - temp_output_10_0_g1140 ) - temp_output_10_0_g1231 ), float3(0,1,0), break61_g1233.y );
				float3 rotatedValue33_g1233 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1233, float3(1,0,0), break61_g1233.x );
				float3 rotatedValue28_g1233 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1233, float3(0,0,1), break61_g1233.z );
				float3 break36_g1233 = rotatedValue28_g1233;
				float2 appendResult27_g1233 = (float2(break36_g1233.x , break36_g1233.y));
				float4 tex2DNode7_g1233 = tex2D( _D_2, ( ( ( appendResult27_g1233 / _CameraF ) / break36_g1233.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1234 = tex2DNode7_g1233.r;
				float temp_output_417_0_g1140 = ( ( 0.2980392 / temp_output_1_0_g1230 ) >= distance( temp_output_10_0_g1227 , temp_output_24_0_g1227 ) ? ( ( 0.2980392 / temp_output_1_0_g1194 ) >= distance( temp_output_10_0_g1191 , temp_output_24_0_g1191 ) ? ( ( 0.2980392 / temp_output_1_0_g1206 ) >= distance( temp_output_10_0_g1203 , temp_output_24_0_g1203 ) ? ( ( 0.2980392 / temp_output_1_0_g1202 ) >= distance( temp_output_10_0_g1199 , temp_output_24_0_g1199 ) ? ( ( 0.2980392 / temp_output_1_0_g1174 ) >= distance( temp_output_10_0_g1171 , temp_output_24_0_g1171 ) ? ( ( 0.2980392 / temp_output_1_0_g1234 ) >= distance( temp_output_10_0_g1231 , temp_output_24_0_g1231 ) ? 100.0 : temp_output_146_10_g1140 ) : temp_output_144_10_g1140 ) : temp_output_142_10_g1140 ) : temp_output_137_10_g1140 ) : temp_output_136_10_g1140 ) : temp_output_138_10_g1140 );
				float temp_output_284_0_g1140 = ( temp_output_417_0_g1140 - temp_output_118_0_g1140 );
				float temp_output_286_0_g1140 = ( ( ( ( temp_output_417_0_g1140 - 0.0 ) + temp_output_284_0_g1140 ) / 2 ) + 0.0 );
				float temp_output_7_0_g1155 = temp_output_286_0_g1140;
				float temp_output_337_10_g1140 = temp_output_7_0_g1155;
				float3 break26_g1164 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1164 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1164.z );
				float3 rotatedValue16_g1164 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1164, float3(1,0,0), break26_g1164.x );
				float3 rotatedValue14_g1164 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1164, float3(0,1,0), break26_g1164.y );
				float3 normalizeResult30_g1164 = normalize( rotatedValue14_g1164 );
				float3 temp_output_31_0_g1164 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1164 = normalize( ( WorldPosition - temp_output_31_0_g1164 ) );
				float dotResult29_g1164 = dot( normalizeResult30_g1164 , normalizeResult8_g1164 );
				float3 temp_output_24_0_g1163 = ( ( ( temp_output_337_10_g1140 / dotResult29_g1164 ) * normalizeResult8_g1164 ) + temp_output_31_0_g1164 );
				float3 temp_output_10_0_g1163 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1165 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1163 - temp_output_10_0_g1140 ) - temp_output_10_0_g1163 ), float3(0,1,0), break61_g1165.y );
				float3 rotatedValue33_g1165 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1165, float3(1,0,0), break61_g1165.x );
				float3 rotatedValue28_g1165 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1165, float3(0,0,1), break61_g1165.z );
				float3 break36_g1165 = rotatedValue28_g1165;
				float2 appendResult27_g1165 = (float2(break36_g1165.x , break36_g1165.y));
				float4 tex2DNode7_g1165 = tex2D( _D_2, ( ( ( appendResult27_g1165 / _CameraF ) / break36_g1165.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1166 = tex2DNode7_g1165.r;
				float temp_output_2_0_g1155 = ( ( temp_output_7_0_g1155 - ( temp_output_284_0_g1140 + 0.0 ) ) / 2 );
				float temp_output_8_0_g1155 = ( temp_output_7_0_g1155 + temp_output_2_0_g1155 );
				float temp_output_9_0_g1155 = ( temp_output_7_0_g1155 - temp_output_2_0_g1155 );
				float temp_output_400_0_g1140 = ( ( 0.2980392 / temp_output_1_0_g1166 ) >= distance( temp_output_10_0_g1163 , temp_output_24_0_g1163 ) ? ( temp_output_8_0_g1155 > temp_output_9_0_g1155 ? temp_output_8_0_g1155 : temp_output_9_0_g1155 ) : ( temp_output_8_0_g1155 > temp_output_9_0_g1155 ? temp_output_9_0_g1155 : temp_output_8_0_g1155 ) );
				float temp_output_7_0_g1157 = temp_output_400_0_g1140;
				float temp_output_341_10_g1140 = temp_output_7_0_g1157;
				float3 break26_g1212 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1212 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1212.z );
				float3 rotatedValue16_g1212 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1212, float3(1,0,0), break26_g1212.x );
				float3 rotatedValue14_g1212 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1212, float3(0,1,0), break26_g1212.y );
				float3 normalizeResult30_g1212 = normalize( rotatedValue14_g1212 );
				float3 temp_output_31_0_g1212 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1212 = normalize( ( WorldPosition - temp_output_31_0_g1212 ) );
				float dotResult29_g1212 = dot( normalizeResult30_g1212 , normalizeResult8_g1212 );
				float3 temp_output_24_0_g1211 = ( ( ( temp_output_341_10_g1140 / dotResult29_g1212 ) * normalizeResult8_g1212 ) + temp_output_31_0_g1212 );
				float3 temp_output_10_0_g1211 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1213 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1211 - temp_output_10_0_g1140 ) - temp_output_10_0_g1211 ), float3(0,1,0), break61_g1213.y );
				float3 rotatedValue33_g1213 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1213, float3(1,0,0), break61_g1213.x );
				float3 rotatedValue28_g1213 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1213, float3(0,0,1), break61_g1213.z );
				float3 break36_g1213 = rotatedValue28_g1213;
				float2 appendResult27_g1213 = (float2(break36_g1213.x , break36_g1213.y));
				float4 tex2DNode7_g1213 = tex2D( _D_2, ( ( ( appendResult27_g1213 / _CameraF ) / break36_g1213.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1214 = tex2DNode7_g1213.r;
				float temp_output_2_0_g1157 = ( ( temp_output_7_0_g1157 - temp_output_337_10_g1140 ) / 2 );
				float temp_output_8_0_g1157 = ( temp_output_7_0_g1157 + temp_output_2_0_g1157 );
				float temp_output_9_0_g1157 = ( temp_output_7_0_g1157 - temp_output_2_0_g1157 );
				float temp_output_413_0_g1140 = ( ( 0.2980392 / temp_output_1_0_g1214 ) >= distance( temp_output_10_0_g1211 , temp_output_24_0_g1211 ) ? ( temp_output_8_0_g1157 > temp_output_9_0_g1157 ? temp_output_8_0_g1157 : temp_output_9_0_g1157 ) : ( temp_output_8_0_g1157 > temp_output_9_0_g1157 ? temp_output_9_0_g1157 : temp_output_8_0_g1157 ) );
				float temp_output_7_0_g1147 = temp_output_413_0_g1140;
				float temp_output_335_10_g1140 = temp_output_7_0_g1147;
				float3 break26_g1188 = ( ( ( temp_output_419_0_g1140 * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g1188 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g1188.z );
				float3 rotatedValue16_g1188 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g1188, float3(1,0,0), break26_g1188.x );
				float3 rotatedValue14_g1188 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g1188, float3(0,1,0), break26_g1188.y );
				float3 normalizeResult30_g1188 = normalize( rotatedValue14_g1188 );
				float3 temp_output_31_0_g1188 = temp_output_418_0_g1140;
				float3 normalizeResult8_g1188 = normalize( ( WorldPosition - temp_output_31_0_g1188 ) );
				float dotResult29_g1188 = dot( normalizeResult30_g1188 , normalizeResult8_g1188 );
				float3 temp_output_24_0_g1187 = ( ( ( temp_output_335_10_g1140 / dotResult29_g1188 ) * normalizeResult8_g1188 ) + temp_output_31_0_g1188 );
				float3 temp_output_10_0_g1187 = temp_output_9_0_g1140;
				float3 rotatedValue31_g1189 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g1187 - temp_output_10_0_g1140 ) - temp_output_10_0_g1187 ), float3(0,1,0), break61_g1189.y );
				float3 rotatedValue33_g1189 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g1189, float3(1,0,0), break61_g1189.x );
				float3 rotatedValue28_g1189 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g1189, float3(0,0,1), break61_g1189.z );
				float3 break36_g1189 = rotatedValue28_g1189;
				float2 appendResult27_g1189 = (float2(break36_g1189.x , break36_g1189.y));
				float4 tex2DNode7_g1189 = tex2D( _D_2, ( ( ( appendResult27_g1189 / _CameraF ) / break36_g1189.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g1190 = tex2DNode7_g1189.r;
				float temp_output_2_0_g1147 = ( ( temp_output_7_0_g1147 - temp_output_341_10_g1140 ) / 2 );
				float temp_output_8_0_g1147 = ( temp_output_7_0_g1147 + temp_output_2_0_g1147 );
				float temp_output_9_0_g1147 = ( temp_output_7_0_g1147 - temp_output_2_0_g1147 );
				float temp_output_407_0_g1140 = ( ( 0.2980392 / temp_output_1_0_g1190 ) >= distance( temp_output_10_0_g1187 , temp_output_24_0_g1187 ) ? ( temp_output_8_0_g1147 > temp_output_9_0_g1147 ? temp_output_8_0_g1147 : temp_output_9_0_g1147 ) : ( temp_output_8_0_g1147 > temp_output_9_0_g1147 ? temp_output_9_0_g1147 : temp_output_8_0_g1147 ) );
				float temp_output_190_0 = ( _Sub1 > 0.0 ? ( _Sub2 > 0.0 ? ( _Sub3 > 0.0 ? temp_output_407_0_g1140 : temp_output_413_0_g1140 ) : temp_output_400_0_g1140 ) : temp_output_286_0_g1140 );
				float temp_output_153_0 = max( ( _UseCam_1 > 0.0 ? temp_output_191_0 : 0.0 ) , ( _UseCam_2 > 0.0 ? temp_output_190_0 : 0.0 ) );
				float temp_output_159_0 = ( temp_output_112_0 - temp_output_153_0 );
				float3 break35_g6180 = ( ( ( _Camera1Rotation * 3.141593 ) / 180 ) * -1 );
				float3 break26_g6186 = ( ( ( _CamOutRotation * 3.141593 ) / 180 ) * 1 );
				float3 rotatedValue19_g6186 = RotateAroundAxis( float3( 0,0,0 ), float3(0,0,1), float3(0,0,1), break26_g6186.z );
				float3 rotatedValue16_g6186 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue19_g6186, float3(1,0,0), break26_g6186.x );
				float3 rotatedValue14_g6186 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue16_g6186, float3(0,1,0), break26_g6186.y );
				float3 normalizeResult30_g6186 = normalize( rotatedValue14_g6186 );
				float3 temp_output_31_0_g6186 = _CamOutPosition;
				float3 normalizeResult8_g6186 = normalize( ( WorldPosition - temp_output_31_0_g6186 ) );
				float dotResult29_g6186 = dot( normalizeResult30_g6186 , normalizeResult8_g6186 );
				float3 temp_output_158_0 = ( ( ( temp_output_153_0 / dotResult29_g6186 ) * normalizeResult8_g6186 ) + temp_output_31_0_g6186 );
				float3 temp_output_56_0_g6179 = temp_output_158_0;
				float3 temp_output_57_0_g6179 = _PositionOffset;
				float3 temp_output_61_0_g6179 = _Camera1Position;
				float3 rotatedValue37_g6180 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g6179 - temp_output_57_0_g6179 ) - temp_output_61_0_g6179 ), float3(0,1,0), break35_g6180.y );
				float3 rotatedValue39_g6180 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g6180, float3(1,0,0), break35_g6180.x );
				float3 rotatedValue33_g6180 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g6180, float3(0,0,1), break35_g6180.z );
				float3 break44_g6180 = rotatedValue33_g6180;
				float2 appendResult31_g6180 = (float2(break44_g6180.x , break44_g6180.y));
				float2 temp_output_162_0_g6179 = ( ( ( appendResult31_g6180 / _InputColorCameraF ) / break44_g6180.z ) + float2( 0.5,0.5 ) );
				float3 break35_g6183 = ( ( ( _Camera2Rotation * 3.141593 ) / 180 ) * -1 );
				float3 temp_output_56_0_g6182 = temp_output_158_0;
				float3 temp_output_57_0_g6182 = _PositionOffset;
				float3 temp_output_61_0_g6182 = _Camera2Position;
				float3 rotatedValue37_g6183 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g6182 - temp_output_57_0_g6182 ) - temp_output_61_0_g6182 ), float3(0,1,0), break35_g6183.y );
				float3 rotatedValue39_g6183 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g6183, float3(1,0,0), break35_g6183.x );
				float3 rotatedValue33_g6183 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g6183, float3(0,0,1), break35_g6183.z );
				float3 break44_g6183 = rotatedValue33_g6183;
				float2 appendResult31_g6183 = (float2(break44_g6183.x , break44_g6183.y));
				float2 temp_output_162_0_g6182 = ( ( ( appendResult31_g6183 / _InputColorCameraF ) / break44_g6183.z ) + float2( 0.5,0.5 ) );
				float4 temp_cast_0 = (( ( temp_output_153_0 - 0.7 ) / ( temp_output_112_0 - 0.7 ) )).xxxx;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( _UseColor_1 > 0.0 ? ( temp_output_159_0 <= 0.1 ? float4( 0,0,0,0 ) : tex2D( _RGB_1, temp_output_162_0_g6179 ) ) : ( _UseColor_2 > 0.0 ? ( temp_output_159_0 <= 0.1 ? float4( 0,0,0,0 ) : tex2D( _RGB_2, temp_output_162_0_g6182 ) ) : temp_cast_0 ) ).rgb;
				float Alpha = 1;
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
			float3 _Camera1Rotation;
			float3 _Camera2Position;
			float3 _CamOutPosition;
			float3 _PositionOffset;
			float3 _Camera2Rotation;
			float3 _Camera1Position;
			float3 _CamOutRotation;
			float _UseCam_2;
			float _CameraF;
			float _UseColor_1;
			float _Sub3;
			float _Sub2;
			float _Sub1;
			float _UseCam_1;
			float _MaxDepthDelta;
			float _InputColorCameraF;
			float _UseColor_2;
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

				
				float Alpha = 1;
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
			float3 _Camera1Rotation;
			float3 _Camera2Position;
			float3 _CamOutPosition;
			float3 _PositionOffset;
			float3 _Camera2Rotation;
			float3 _Camera1Position;
			float3 _CamOutRotation;
			float _UseCam_2;
			float _CameraF;
			float _UseColor_1;
			float _Sub3;
			float _Sub2;
			float _Sub1;
			float _UseCam_1;
			float _MaxDepthDelta;
			float _InputColorCameraF;
			float _UseColor_2;
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

				
				float Alpha = 1;
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
3011;9;1459;992;589.1417;656.9197;1.274328;True;True
Node;AmplifyShaderEditor.TexturePropertyNode;8;-1171.978,156.1476;Inherit;True;Property;_RGB_2;RGB_2;9;0;Create;True;0;0;0;False;0;False;3d7039e2d91fd44f68f4f05c291fb0a7;3d7039e2d91fd44f68f4f05c291fb0a7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;26;-507.2855,-659.1292;Inherit;False;F256ToDepth;-1;;6181;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1162.789,372.7456;Inherit;True;Property;_D_2;D_2;10;0;Create;True;0;0;0;False;0;False;008ecc74e3a374dc7b0378989802d355;008ecc74e3a374dc7b0378989802d355;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.BreakToComponentsNode;108;-1251.907,-162.4125;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.FunctionNode;154;967.4815,260.9085;Inherit;False;SingleCameraMapping;191;;6182;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;30;-1178.169,-1538.857;Inherit;False;Property;_Camera1Rotation;Camera 1 Rotation;8;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;170;1651.186,182.4345;Inherit;False;Property;_UseColor_2;UseColor_2;1;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;-896.2289,372.7456;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;159;865.9754,-572.1017;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;107;-1395.135,-154.0809;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;116;1178.055,77.08279;Inherit;False;Constant;_Float0;Float 0;50;0;Create;True;0;0;0;False;0;False;0.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;9;-953.6662,-748.0662;Inherit;True;Property;_TextureSample2;Texture Sample 2;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;186;-1847.283,-107.0775;Inherit;False;Property;_CamOutPosition;CamOutPosition;190;0;Create;True;0;0;0;False;0;False;0,0,0;0.423,1.8,-0.703;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;31;-1175.32,-1381.268;Inherit;False;Property;_Camera1Position;Camera 1 Position;7;0;Create;True;0;0;0;False;0;False;0,0,0;0,1.8,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;162;1814.608,-5.811478;Inherit;False;Property;_UseColor_1;UseColor_1;0;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;171;1802.501,181.2142;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;115;1372.663,-17.81841;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;93;1598.331,52.01149;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;117;1390.878,115.315;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;5;-1216.744,-956.5697;Inherit;True;Property;_RGB_1;RGB_1;5;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;6e525e0933ba04ebe9d0f3860234333d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Compare;166;27.21982,-10.22895;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;172;1370.615,330.1912;Inherit;False;5;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;110;-1128.907,-165.4125;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;190;-657.749,779.4965;Inherit;False;IterativelyGetDepth;14;;1140;737fc4a0ba92542e0a72347a837a8648;0;7;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;418;FLOAT3;0,0,0;False;419;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;153;284.0412,-240.6069;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;74;-367.9774,-1775.448;Inherit;False;CamDepthToWorldPosition;-1;;6185;a9d725c4349ce4106bfa1039b7647c13;0;3;9;FLOAT;0;False;27;FLOAT3;0,0,0;False;31;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;163;1952.608,-5.811478;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;164;-96.69938,-612.7036;Inherit;False;Property;_UseCam_1;UseCam_1;2;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;10;-1220.226,-748.0662;Inherit;True;Property;_D_1;D_1;6;0;Create;True;0;0;0;False;0;False;0146383e3995643be92047c1c3fd405d;0146383e3995643be92047c1c3fd405d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;155;-375.416,780.5508;Inherit;False;CamDepthToWorldPosition;-1;;6184;a9d725c4349ce4106bfa1039b7647c13;0;3;9;FLOAT;0;False;27;FLOAT3;0,0,0;False;31;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;158;482.2842,-584.1273;Inherit;False;CamDepthToWorldPosition;-1;;6186;a9d725c4349ce4106bfa1039b7647c13;0;3;9;FLOAT;0;False;27;FLOAT3;0,0,0;False;31;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-135.7876,-8.561789;Inherit;False;Property;_UseCam_2;UseCam_2;3;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;28;-1213.134,653.7977;Inherit;False;Property;_Camera2Rotation;Camera 2 Rotation;12;0;Create;True;0;0;0;False;0;False;0,0,0;0,315,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LengthOpNode;111;-1006.907,-169.4125;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;160;1395.403,-842.2052;Inherit;False;5;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;27;-2199.773,-433.9232;Inherit;False;Property;_PositionOffset;PositionOffset;13;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;29;-1203.041,860.6336;Inherit;False;Property;_Camera2Position;Camera 2 Position;11;0;Create;True;0;0;0;False;0;False;0,0,0;0.824,1.781,-0.752;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;63;824.549,-1107.144;Inherit;False;SingleCameraMapping;191;;6179;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;7;-905.4182,156.1476;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Compare;165;41.3006,-612.7036;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-950.1835,-956.5697;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;161;1168.05,-822.5859;Inherit;False;Constant;_Float2;Float 2;90;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;112;-852.9073,-235.4125;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-1052.89,-297.0006;Inherit;False;Property;_MaxDepthDelta;MaxDepthDelta;4;0;Create;True;0;0;0;False;0;False;4;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;191;-616.7129,-1675.456;Inherit;False;IterativelyGetDepth;14;;1235;737fc4a0ba92542e0a72347a837a8648;0;7;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;418;FLOAT3;0,0,0;False;419;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;187;-1852.359,60.78791;Inherit;False;Property;_CamOutRotation;CamOutRotation;189;0;Create;True;0;0;0;False;0;False;0,0,0;0,328.9644,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2188.991,-3.530464;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;NovelView;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;26;1;9;1
WireConnection;108;0;107;0
WireConnection;154;55;8;0
WireConnection;154;79;12;0
WireConnection;154;56;158;0
WireConnection;154;57;27;0
WireConnection;154;60;28;0
WireConnection;154;61;29;0
WireConnection;11;0;12;0
WireConnection;159;0;112;0
WireConnection;159;1;153;0
WireConnection;107;0;186;0
WireConnection;107;1;27;0
WireConnection;9;0;10;0
WireConnection;171;0;170;0
WireConnection;171;2;172;0
WireConnection;171;3;93;0
WireConnection;115;0;153;0
WireConnection;115;1;116;0
WireConnection;93;0;115;0
WireConnection;93;1;117;0
WireConnection;117;0;112;0
WireConnection;117;1;116;0
WireConnection;166;0;167;0
WireConnection;166;2;190;0
WireConnection;172;0;159;0
WireConnection;172;1;161;0
WireConnection;172;3;154;0
WireConnection;110;0;108;0
WireConnection;110;1;108;2
WireConnection;190;13;112;0
WireConnection;190;10;27;0
WireConnection;190;12;28;0
WireConnection;190;9;29;0
WireConnection;190;11;12;0
WireConnection;190;418;186;0
WireConnection;190;419;187;0
WireConnection;153;0;165;0
WireConnection;153;1;166;0
WireConnection;74;9;191;0
WireConnection;163;0;162;0
WireConnection;163;2;160;0
WireConnection;163;3;171;0
WireConnection;155;9;190;0
WireConnection;158;9;153;0
WireConnection;158;27;187;0
WireConnection;158;31;186;0
WireConnection;111;0;110;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;160;3;63;0
WireConnection;63;55;5;0
WireConnection;63;79;10;0
WireConnection;63;56;158;0
WireConnection;63;57;27;0
WireConnection;63;60;30;0
WireConnection;63;61;31;0
WireConnection;7;0;8;0
WireConnection;165;0;164;0
WireConnection;165;2;191;0
WireConnection;6;0;5;0
WireConnection;112;0;44;0
WireConnection;112;1;111;0
WireConnection;191;13;112;0
WireConnection;191;10;27;0
WireConnection;191;12;30;0
WireConnection;191;9;31;0
WireConnection;191;11;10;0
WireConnection;191;418;186;0
WireConnection;191;419;187;0
WireConnection;1;2;163;0
ASEEND*/
//CHKSM=44443AEE3420DB359A2F6B663786424658C3242D