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
		[ASEEnd]_CameraF("Camera F", Range( 1 , 2)) = 1.1543

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
			float3 _PositionOffset;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _UseColor_1;
			float _MaxDepthDelta;
			float _UseCam_1;
			float _CameraF;
			float _UseCam_2;
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
				float3 break108 = ( _WorldSpaceCameraPos - _PositionOffset );
				float2 appendResult110 = (float2(break108.x , break108.z));
				float temp_output_112_0 = ( _MaxDepthDelta + length( appendResult110 ) );
				float3 temp_output_12_0_g4929 = _Camera1Rotation;
				float3 break61_g5005 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5015 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4950 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4965 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5000 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5041 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4970 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_13_0_g4929 = temp_output_112_0;
				float temp_output_118_0_g4929 = ( 0.1 * temp_output_13_0_g4929 );
				float temp_output_12_0_g5035 = temp_output_118_0_g4929;
				float temp_output_138_10_g4929 = temp_output_12_0_g5035;
				float3 normalizeResult8_g4968 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4967 = ( ( temp_output_138_10_g4929 * normalizeResult8_g4968 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4929 = _PositionOffset;
				float3 temp_output_9_0_g4929 = _Camera1Position;
				float3 temp_output_10_0_g4967 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4970 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4967 - temp_output_10_0_g4929 ) - temp_output_10_0_g4967 ), float3(0,1,0), break61_g4970.y );
				float3 rotatedValue33_g4970 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4970, float3(1,0,0), break61_g4970.x );
				float3 rotatedValue28_g4970 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4970, float3(0,0,1), break61_g4970.z );
				float3 break36_g4970 = rotatedValue28_g4970;
				float2 appendResult27_g4970 = (float2(break36_g4970.x , break36_g4970.y));
				float4 tex2DNode7_g4970 = tex2D( _D_1, ( ( ( appendResult27_g4970 / _CameraF ) / break36_g4970.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4971 = tex2DNode7_g4970.r;
				float3 break61_g4975 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5026 = ( temp_output_12_0_g5035 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g4929 = temp_output_12_0_g5026;
				float3 normalizeResult8_g4973 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4972 = ( ( temp_output_136_10_g4929 * normalizeResult8_g4973 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4972 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4975 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4972 - temp_output_10_0_g4929 ) - temp_output_10_0_g4972 ), float3(0,1,0), break61_g4975.y );
				float3 rotatedValue33_g4975 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4975, float3(1,0,0), break61_g4975.x );
				float3 rotatedValue28_g4975 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4975, float3(0,0,1), break61_g4975.z );
				float3 break36_g4975 = rotatedValue28_g4975;
				float2 appendResult27_g4975 = (float2(break36_g4975.x , break36_g4975.y));
				float4 tex2DNode7_g4975 = tex2D( _D_1, ( ( ( appendResult27_g4975 / _CameraF ) / break36_g4975.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4976 = tex2DNode7_g4975.r;
				float3 break61_g4990 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5028 = ( temp_output_12_0_g5026 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g4929 = temp_output_12_0_g5028;
				float3 normalizeResult8_g4988 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4987 = ( ( temp_output_137_10_g4929 * normalizeResult8_g4988 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4987 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4990 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4987 - temp_output_10_0_g4929 ) - temp_output_10_0_g4987 ), float3(0,1,0), break61_g4990.y );
				float3 rotatedValue33_g4990 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4990, float3(1,0,0), break61_g4990.x );
				float3 rotatedValue28_g4990 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4990, float3(0,0,1), break61_g4990.z );
				float3 break36_g4990 = rotatedValue28_g4990;
				float2 appendResult27_g4990 = (float2(break36_g4990.x , break36_g4990.y));
				float4 tex2DNode7_g4990 = tex2D( _D_1, ( ( ( appendResult27_g4990 / _CameraF ) / break36_g4990.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4991 = tex2DNode7_g4990.r;
				float3 break61_g4985 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4930 = ( temp_output_12_0_g5028 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g4929 = temp_output_12_0_g4930;
				float3 normalizeResult8_g4983 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4982 = ( ( temp_output_142_10_g4929 * normalizeResult8_g4983 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4982 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4985 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4982 - temp_output_10_0_g4929 ) - temp_output_10_0_g4982 ), float3(0,1,0), break61_g4985.y );
				float3 rotatedValue33_g4985 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4985, float3(1,0,0), break61_g4985.x );
				float3 rotatedValue28_g4985 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4985, float3(0,0,1), break61_g4985.z );
				float3 break36_g4985 = rotatedValue28_g4985;
				float2 appendResult27_g4985 = (float2(break36_g4985.x , break36_g4985.y));
				float4 tex2DNode7_g4985 = tex2D( _D_1, ( ( ( appendResult27_g4985 / _CameraF ) / break36_g4985.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4986 = tex2DNode7_g4985.r;
				float3 break61_g4935 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4931 = ( temp_output_12_0_g4930 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g4929 = temp_output_12_0_g4931;
				float3 normalizeResult8_g4933 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4932 = ( ( temp_output_144_10_g4929 * normalizeResult8_g4933 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4932 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4935 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4932 - temp_output_10_0_g4929 ) - temp_output_10_0_g4932 ), float3(0,1,0), break61_g4935.y );
				float3 rotatedValue33_g4935 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4935, float3(1,0,0), break61_g4935.x );
				float3 rotatedValue28_g4935 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4935, float3(0,0,1), break61_g4935.z );
				float3 break36_g4935 = rotatedValue28_g4935;
				float2 appendResult27_g4935 = (float2(break36_g4935.x , break36_g4935.y));
				float4 tex2DNode7_g4935 = tex2D( _D_1, ( ( ( appendResult27_g4935 / _CameraF ) / break36_g4935.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4936 = tex2DNode7_g4935.r;
				float3 break61_g4960 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5023 = ( temp_output_12_0_g4931 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g4929 = temp_output_12_0_g5023;
				float3 normalizeResult8_g4958 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4957 = ( ( temp_output_146_10_g4929 * normalizeResult8_g4958 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4957 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4960 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4957 - temp_output_10_0_g4929 ) - temp_output_10_0_g4957 ), float3(0,1,0), break61_g4960.y );
				float3 rotatedValue33_g4960 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4960, float3(1,0,0), break61_g4960.x );
				float3 rotatedValue28_g4960 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4960, float3(0,0,1), break61_g4960.z );
				float3 break36_g4960 = rotatedValue28_g4960;
				float2 appendResult27_g4960 = (float2(break36_g4960.x , break36_g4960.y));
				float4 tex2DNode7_g4960 = tex2D( _D_1, ( ( ( appendResult27_g4960 / _CameraF ) / break36_g4960.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4961 = tex2DNode7_g4960.r;
				float3 break61_g4945 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5036 = ( temp_output_12_0_g5023 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_148_10_g4929 = temp_output_12_0_g5036;
				float3 normalizeResult8_g4943 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4942 = ( ( temp_output_148_10_g4929 * normalizeResult8_g4943 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4942 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4945 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4942 - temp_output_10_0_g4929 ) - temp_output_10_0_g4942 ), float3(0,1,0), break61_g4945.y );
				float3 rotatedValue33_g4945 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4945, float3(1,0,0), break61_g4945.x );
				float3 rotatedValue28_g4945 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4945, float3(0,0,1), break61_g4945.z );
				float3 break36_g4945 = rotatedValue28_g4945;
				float2 appendResult27_g4945 = (float2(break36_g4945.x , break36_g4945.y));
				float4 tex2DNode7_g4945 = tex2D( _D_1, ( ( ( appendResult27_g4945 / _CameraF ) / break36_g4945.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4946 = tex2DNode7_g4945.r;
				float3 break61_g5010 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5037 = ( temp_output_12_0_g5036 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_150_10_g4929 = temp_output_12_0_g5037;
				float3 normalizeResult8_g5008 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5007 = ( ( temp_output_150_10_g4929 * normalizeResult8_g5008 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5007 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5010 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5007 - temp_output_10_0_g4929 ) - temp_output_10_0_g5007 ), float3(0,1,0), break61_g5010.y );
				float3 rotatedValue33_g5010 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5010, float3(1,0,0), break61_g5010.x );
				float3 rotatedValue28_g5010 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5010, float3(0,0,1), break61_g5010.z );
				float3 break36_g5010 = rotatedValue28_g5010;
				float2 appendResult27_g5010 = (float2(break36_g5010.x , break36_g5010.y));
				float4 tex2DNode7_g5010 = tex2D( _D_1, ( ( ( appendResult27_g5010 / _CameraF ) / break36_g5010.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5011 = tex2DNode7_g5010.r;
				float3 break61_g5021 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5024 = ( temp_output_12_0_g5037 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_152_10_g4929 = temp_output_12_0_g5024;
				float3 normalizeResult8_g5019 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5018 = ( ( temp_output_152_10_g4929 * normalizeResult8_g5019 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5018 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5021 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5018 - temp_output_10_0_g4929 ) - temp_output_10_0_g5018 ), float3(0,1,0), break61_g5021.y );
				float3 rotatedValue33_g5021 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5021, float3(1,0,0), break61_g5021.x );
				float3 rotatedValue28_g5021 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5021, float3(0,0,1), break61_g5021.z );
				float3 break36_g5021 = rotatedValue28_g5021;
				float2 appendResult27_g5021 = (float2(break36_g5021.x , break36_g5021.y));
				float4 tex2DNode7_g5021 = tex2D( _D_1, ( ( ( appendResult27_g5021 / _CameraF ) / break36_g5021.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5022 = tex2DNode7_g5021.r;
				float3 break61_g4995 = ( ( ( temp_output_12_0_g4929 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5025 = ( temp_output_12_0_g5024 + ( ( temp_output_13_0_g4929 - 0.0 ) * 0.1 ) );
				float temp_output_154_10_g4929 = temp_output_12_0_g5025;
				float3 normalizeResult8_g4993 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4992 = ( ( temp_output_154_10_g4929 * normalizeResult8_g4993 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4992 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4995 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4992 - temp_output_10_0_g4929 ) - temp_output_10_0_g4992 ), float3(0,1,0), break61_g4995.y );
				float3 rotatedValue33_g4995 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4995, float3(1,0,0), break61_g4995.x );
				float3 rotatedValue28_g4995 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4995, float3(0,0,1), break61_g4995.z );
				float3 break36_g4995 = rotatedValue28_g4995;
				float2 appendResult27_g4995 = (float2(break36_g4995.x , break36_g4995.y));
				float4 tex2DNode7_g4995 = tex2D( _D_1, ( ( ( appendResult27_g4995 / _CameraF ) / break36_g4995.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4996 = tex2DNode7_g4995.r;
				float temp_output_349_0_g4929 = ( ( 0.2980392 / temp_output_1_0_g4971 ) >= distance( temp_output_10_0_g4967 , temp_output_24_0_g4967 ) ? ( ( 0.2980392 / temp_output_1_0_g4976 ) >= distance( temp_output_10_0_g4972 , temp_output_24_0_g4972 ) ? ( ( 0.2980392 / temp_output_1_0_g4991 ) >= distance( temp_output_10_0_g4987 , temp_output_24_0_g4987 ) ? ( ( 0.2980392 / temp_output_1_0_g4986 ) >= distance( temp_output_10_0_g4982 , temp_output_24_0_g4982 ) ? ( ( 0.2980392 / temp_output_1_0_g4936 ) >= distance( temp_output_10_0_g4932 , temp_output_24_0_g4932 ) ? ( ( 0.2980392 / temp_output_1_0_g4961 ) >= distance( temp_output_10_0_g4957 , temp_output_24_0_g4957 ) ? ( ( 0.2980392 / temp_output_1_0_g4946 ) >= distance( temp_output_10_0_g4942 , temp_output_24_0_g4942 ) ? ( ( 0.2980392 / temp_output_1_0_g5011 ) >= distance( temp_output_10_0_g5007 , temp_output_24_0_g5007 ) ? ( ( 0.2980392 / temp_output_1_0_g5022 ) >= distance( temp_output_10_0_g5018 , temp_output_24_0_g5018 ) ? ( ( 0.2980392 / temp_output_1_0_g4996 ) >= distance( temp_output_10_0_g4992 , temp_output_24_0_g4992 ) ? 100.0 : temp_output_154_10_g4929 ) : temp_output_152_10_g4929 ) : temp_output_150_10_g4929 ) : temp_output_148_10_g4929 ) : temp_output_146_10_g4929 ) : temp_output_144_10_g4929 ) : temp_output_142_10_g4929 ) : temp_output_137_10_g4929 ) : temp_output_136_10_g4929 ) : temp_output_138_10_g4929 );
				float temp_output_284_0_g4929 = ( temp_output_349_0_g4929 - temp_output_118_0_g4929 );
				float temp_output_286_0_g4929 = ( ( ( ( temp_output_349_0_g4929 - 0.0 ) + temp_output_284_0_g4929 ) / 2 ) + 0.0 );
				float temp_output_7_0_g5032 = temp_output_286_0_g4929;
				float temp_output_337_10_g4929 = temp_output_7_0_g5032;
				float3 normalizeResult8_g5039 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5038 = ( ( temp_output_337_10_g4929 * normalizeResult8_g5039 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5038 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5041 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5038 - temp_output_10_0_g4929 ) - temp_output_10_0_g5038 ), float3(0,1,0), break61_g5041.y );
				float3 rotatedValue33_g5041 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5041, float3(1,0,0), break61_g5041.x );
				float3 rotatedValue28_g5041 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5041, float3(0,0,1), break61_g5041.z );
				float3 break36_g5041 = rotatedValue28_g5041;
				float2 appendResult27_g5041 = (float2(break36_g5041.x , break36_g5041.y));
				float4 tex2DNode7_g5041 = tex2D( _D_1, ( ( ( appendResult27_g5041 / _CameraF ) / break36_g5041.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5042 = tex2DNode7_g5041.r;
				float temp_output_2_0_g5032 = ( ( temp_output_7_0_g5032 - ( temp_output_284_0_g4929 + 0.0 ) ) / 2 );
				float temp_output_8_0_g5032 = ( temp_output_7_0_g5032 + temp_output_2_0_g5032 );
				float temp_output_9_0_g5032 = ( temp_output_7_0_g5032 - temp_output_2_0_g5032 );
				float temp_output_360_0_g4929 = ( ( 0.2980392 / temp_output_1_0_g5042 ) >= distance( temp_output_10_0_g5038 , temp_output_24_0_g5038 ) ? ( temp_output_8_0_g5032 > temp_output_9_0_g5032 ? temp_output_8_0_g5032 : temp_output_9_0_g5032 ) : ( temp_output_8_0_g5032 > temp_output_9_0_g5032 ? temp_output_9_0_g5032 : temp_output_8_0_g5032 ) );
				float temp_output_7_0_g5017 = temp_output_360_0_g4929;
				float temp_output_341_10_g4929 = temp_output_7_0_g5017;
				float3 normalizeResult8_g4998 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4997 = ( ( temp_output_341_10_g4929 * normalizeResult8_g4998 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4997 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5000 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4997 - temp_output_10_0_g4929 ) - temp_output_10_0_g4997 ), float3(0,1,0), break61_g5000.y );
				float3 rotatedValue33_g5000 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5000, float3(1,0,0), break61_g5000.x );
				float3 rotatedValue28_g5000 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5000, float3(0,0,1), break61_g5000.z );
				float3 break36_g5000 = rotatedValue28_g5000;
				float2 appendResult27_g5000 = (float2(break36_g5000.x , break36_g5000.y));
				float4 tex2DNode7_g5000 = tex2D( _D_1, ( ( ( appendResult27_g5000 / _CameraF ) / break36_g5000.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5001 = tex2DNode7_g5000.r;
				float temp_output_2_0_g5017 = ( ( temp_output_7_0_g5017 - temp_output_337_10_g4929 ) / 2 );
				float temp_output_8_0_g5017 = ( temp_output_7_0_g5017 + temp_output_2_0_g5017 );
				float temp_output_9_0_g5017 = ( temp_output_7_0_g5017 - temp_output_2_0_g5017 );
				float temp_output_355_0_g4929 = ( ( 0.2980392 / temp_output_1_0_g5001 ) >= distance( temp_output_10_0_g4997 , temp_output_24_0_g4997 ) ? ( temp_output_8_0_g5017 > temp_output_9_0_g5017 ? temp_output_8_0_g5017 : temp_output_9_0_g5017 ) : ( temp_output_8_0_g5017 > temp_output_9_0_g5017 ? temp_output_9_0_g5017 : temp_output_8_0_g5017 ) );
				float temp_output_7_0_g5030 = temp_output_355_0_g4929;
				float temp_output_335_10_g4929 = temp_output_7_0_g5030;
				float3 normalizeResult8_g4963 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4962 = ( ( temp_output_335_10_g4929 * normalizeResult8_g4963 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4962 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4965 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4962 - temp_output_10_0_g4929 ) - temp_output_10_0_g4962 ), float3(0,1,0), break61_g4965.y );
				float3 rotatedValue33_g4965 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4965, float3(1,0,0), break61_g4965.x );
				float3 rotatedValue28_g4965 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4965, float3(0,0,1), break61_g4965.z );
				float3 break36_g4965 = rotatedValue28_g4965;
				float2 appendResult27_g4965 = (float2(break36_g4965.x , break36_g4965.y));
				float4 tex2DNode7_g4965 = tex2D( _D_1, ( ( ( appendResult27_g4965 / _CameraF ) / break36_g4965.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4966 = tex2DNode7_g4965.r;
				float temp_output_2_0_g5030 = ( ( temp_output_7_0_g5030 - temp_output_341_10_g4929 ) / 2 );
				float temp_output_8_0_g5030 = ( temp_output_7_0_g5030 + temp_output_2_0_g5030 );
				float temp_output_9_0_g5030 = ( temp_output_7_0_g5030 - temp_output_2_0_g5030 );
				float temp_output_348_0_g4929 = ( ( 0.2980392 / temp_output_1_0_g4966 ) >= distance( temp_output_10_0_g4962 , temp_output_24_0_g4962 ) ? ( temp_output_8_0_g5030 > temp_output_9_0_g5030 ? temp_output_8_0_g5030 : temp_output_9_0_g5030 ) : ( temp_output_8_0_g5030 > temp_output_9_0_g5030 ? temp_output_9_0_g5030 : temp_output_8_0_g5030 ) );
				float temp_output_7_0_g5034 = temp_output_348_0_g4929;
				float temp_output_339_10_g4929 = temp_output_7_0_g5034;
				float3 normalizeResult8_g4948 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4947 = ( ( temp_output_339_10_g4929 * normalizeResult8_g4948 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4947 = temp_output_9_0_g4929;
				float3 rotatedValue31_g4950 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4947 - temp_output_10_0_g4929 ) - temp_output_10_0_g4947 ), float3(0,1,0), break61_g4950.y );
				float3 rotatedValue33_g4950 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4950, float3(1,0,0), break61_g4950.x );
				float3 rotatedValue28_g4950 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4950, float3(0,0,1), break61_g4950.z );
				float3 break36_g4950 = rotatedValue28_g4950;
				float2 appendResult27_g4950 = (float2(break36_g4950.x , break36_g4950.y));
				float4 tex2DNode7_g4950 = tex2D( _D_1, ( ( ( appendResult27_g4950 / _CameraF ) / break36_g4950.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g4951 = tex2DNode7_g4950.r;
				float temp_output_2_0_g5034 = ( ( temp_output_7_0_g5034 - temp_output_335_10_g4929 ) / 2 );
				float temp_output_8_0_g5034 = ( temp_output_7_0_g5034 + temp_output_2_0_g5034 );
				float temp_output_9_0_g5034 = ( temp_output_7_0_g5034 - temp_output_2_0_g5034 );
				float temp_output_7_0_g5029 = ( ( 0.2980392 / temp_output_1_0_g4951 ) >= distance( temp_output_10_0_g4947 , temp_output_24_0_g4947 ) ? ( temp_output_8_0_g5034 > temp_output_9_0_g5034 ? temp_output_8_0_g5034 : temp_output_9_0_g5034 ) : ( temp_output_8_0_g5034 > temp_output_9_0_g5034 ? temp_output_9_0_g5034 : temp_output_8_0_g5034 ) );
				float temp_output_334_10_g4929 = temp_output_7_0_g5029;
				float3 normalizeResult8_g5013 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5012 = ( ( temp_output_334_10_g4929 * normalizeResult8_g5013 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5012 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5015 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5012 - temp_output_10_0_g4929 ) - temp_output_10_0_g5012 ), float3(0,1,0), break61_g5015.y );
				float3 rotatedValue33_g5015 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5015, float3(1,0,0), break61_g5015.x );
				float3 rotatedValue28_g5015 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5015, float3(0,0,1), break61_g5015.z );
				float3 break36_g5015 = rotatedValue28_g5015;
				float2 appendResult27_g5015 = (float2(break36_g5015.x , break36_g5015.y));
				float4 tex2DNode7_g5015 = tex2D( _D_1, ( ( ( appendResult27_g5015 / _CameraF ) / break36_g5015.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5016 = tex2DNode7_g5015.r;
				float temp_output_2_0_g5029 = ( ( temp_output_7_0_g5029 - temp_output_339_10_g4929 ) / 2 );
				float temp_output_8_0_g5029 = ( temp_output_7_0_g5029 + temp_output_2_0_g5029 );
				float temp_output_9_0_g5029 = ( temp_output_7_0_g5029 - temp_output_2_0_g5029 );
				float temp_output_7_0_g5033 = ( ( 0.2980392 / temp_output_1_0_g5016 ) >= distance( temp_output_10_0_g5012 , temp_output_24_0_g5012 ) ? ( temp_output_8_0_g5029 > temp_output_9_0_g5029 ? temp_output_8_0_g5029 : temp_output_9_0_g5029 ) : ( temp_output_8_0_g5029 > temp_output_9_0_g5029 ? temp_output_9_0_g5029 : temp_output_8_0_g5029 ) );
				float temp_output_338_10_g4929 = temp_output_7_0_g5033;
				float3 normalizeResult8_g5003 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5002 = ( ( temp_output_338_10_g4929 * normalizeResult8_g5003 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5002 = temp_output_9_0_g4929;
				float3 rotatedValue31_g5005 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5002 - temp_output_10_0_g4929 ) - temp_output_10_0_g5002 ), float3(0,1,0), break61_g5005.y );
				float3 rotatedValue33_g5005 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5005, float3(1,0,0), break61_g5005.x );
				float3 rotatedValue28_g5005 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5005, float3(0,0,1), break61_g5005.z );
				float3 break36_g5005 = rotatedValue28_g5005;
				float2 appendResult27_g5005 = (float2(break36_g5005.x , break36_g5005.y));
				float4 tex2DNode7_g5005 = tex2D( _D_1, ( ( ( appendResult27_g5005 / _CameraF ) / break36_g5005.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5006 = tex2DNode7_g5005.r;
				float temp_output_2_0_g5033 = ( ( temp_output_7_0_g5033 - temp_output_334_10_g4929 ) / 2 );
				float temp_output_8_0_g5033 = ( temp_output_7_0_g5033 + temp_output_2_0_g5033 );
				float temp_output_9_0_g5033 = ( temp_output_7_0_g5033 - temp_output_2_0_g5033 );
				float temp_output_356_0_g4929 = ( ( 0.2980392 / temp_output_1_0_g5006 ) >= distance( temp_output_10_0_g5002 , temp_output_24_0_g5002 ) ? ( temp_output_8_0_g5033 > temp_output_9_0_g5033 ? temp_output_8_0_g5033 : temp_output_9_0_g5033 ) : ( temp_output_8_0_g5033 > temp_output_9_0_g5033 ? temp_output_9_0_g5033 : temp_output_8_0_g5033 ) );
				float temp_output_169_0 = temp_output_356_0_g4929;
				float3 temp_output_12_0_g5050 = _Camera2Rotation;
				float3 break61_g5126 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5136 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5071 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5086 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5121 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5162 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g5091 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_13_0_g5050 = temp_output_112_0;
				float temp_output_118_0_g5050 = ( 0.1 * temp_output_13_0_g5050 );
				float temp_output_12_0_g5156 = temp_output_118_0_g5050;
				float temp_output_138_10_g5050 = temp_output_12_0_g5156;
				float3 normalizeResult8_g5089 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5088 = ( ( temp_output_138_10_g5050 * normalizeResult8_g5089 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5050 = _PositionOffset;
				float3 temp_output_9_0_g5050 = _Camera2Position;
				float3 temp_output_10_0_g5088 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5091 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5088 - temp_output_10_0_g5050 ) - temp_output_10_0_g5088 ), float3(0,1,0), break61_g5091.y );
				float3 rotatedValue33_g5091 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5091, float3(1,0,0), break61_g5091.x );
				float3 rotatedValue28_g5091 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5091, float3(0,0,1), break61_g5091.z );
				float3 break36_g5091 = rotatedValue28_g5091;
				float2 appendResult27_g5091 = (float2(break36_g5091.x , break36_g5091.y));
				float4 tex2DNode7_g5091 = tex2D( _D_2, ( ( ( appendResult27_g5091 / _CameraF ) / break36_g5091.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5092 = tex2DNode7_g5091.r;
				float3 break61_g5096 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5147 = ( temp_output_12_0_g5156 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g5050 = temp_output_12_0_g5147;
				float3 normalizeResult8_g5094 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5093 = ( ( temp_output_136_10_g5050 * normalizeResult8_g5094 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5093 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5096 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5093 - temp_output_10_0_g5050 ) - temp_output_10_0_g5093 ), float3(0,1,0), break61_g5096.y );
				float3 rotatedValue33_g5096 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5096, float3(1,0,0), break61_g5096.x );
				float3 rotatedValue28_g5096 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5096, float3(0,0,1), break61_g5096.z );
				float3 break36_g5096 = rotatedValue28_g5096;
				float2 appendResult27_g5096 = (float2(break36_g5096.x , break36_g5096.y));
				float4 tex2DNode7_g5096 = tex2D( _D_2, ( ( ( appendResult27_g5096 / _CameraF ) / break36_g5096.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5097 = tex2DNode7_g5096.r;
				float3 break61_g5111 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5149 = ( temp_output_12_0_g5147 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g5050 = temp_output_12_0_g5149;
				float3 normalizeResult8_g5109 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5108 = ( ( temp_output_137_10_g5050 * normalizeResult8_g5109 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5108 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5111 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5108 - temp_output_10_0_g5050 ) - temp_output_10_0_g5108 ), float3(0,1,0), break61_g5111.y );
				float3 rotatedValue33_g5111 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5111, float3(1,0,0), break61_g5111.x );
				float3 rotatedValue28_g5111 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5111, float3(0,0,1), break61_g5111.z );
				float3 break36_g5111 = rotatedValue28_g5111;
				float2 appendResult27_g5111 = (float2(break36_g5111.x , break36_g5111.y));
				float4 tex2DNode7_g5111 = tex2D( _D_2, ( ( ( appendResult27_g5111 / _CameraF ) / break36_g5111.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5112 = tex2DNode7_g5111.r;
				float3 break61_g5106 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5051 = ( temp_output_12_0_g5149 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g5050 = temp_output_12_0_g5051;
				float3 normalizeResult8_g5104 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5103 = ( ( temp_output_142_10_g5050 * normalizeResult8_g5104 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5103 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5106 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5103 - temp_output_10_0_g5050 ) - temp_output_10_0_g5103 ), float3(0,1,0), break61_g5106.y );
				float3 rotatedValue33_g5106 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5106, float3(1,0,0), break61_g5106.x );
				float3 rotatedValue28_g5106 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5106, float3(0,0,1), break61_g5106.z );
				float3 break36_g5106 = rotatedValue28_g5106;
				float2 appendResult27_g5106 = (float2(break36_g5106.x , break36_g5106.y));
				float4 tex2DNode7_g5106 = tex2D( _D_2, ( ( ( appendResult27_g5106 / _CameraF ) / break36_g5106.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5107 = tex2DNode7_g5106.r;
				float3 break61_g5056 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5052 = ( temp_output_12_0_g5051 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g5050 = temp_output_12_0_g5052;
				float3 normalizeResult8_g5054 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5053 = ( ( temp_output_144_10_g5050 * normalizeResult8_g5054 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5053 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5056 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5053 - temp_output_10_0_g5050 ) - temp_output_10_0_g5053 ), float3(0,1,0), break61_g5056.y );
				float3 rotatedValue33_g5056 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5056, float3(1,0,0), break61_g5056.x );
				float3 rotatedValue28_g5056 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5056, float3(0,0,1), break61_g5056.z );
				float3 break36_g5056 = rotatedValue28_g5056;
				float2 appendResult27_g5056 = (float2(break36_g5056.x , break36_g5056.y));
				float4 tex2DNode7_g5056 = tex2D( _D_2, ( ( ( appendResult27_g5056 / _CameraF ) / break36_g5056.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5057 = tex2DNode7_g5056.r;
				float3 break61_g5081 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5144 = ( temp_output_12_0_g5052 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g5050 = temp_output_12_0_g5144;
				float3 normalizeResult8_g5079 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5078 = ( ( temp_output_146_10_g5050 * normalizeResult8_g5079 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5078 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5081 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5078 - temp_output_10_0_g5050 ) - temp_output_10_0_g5078 ), float3(0,1,0), break61_g5081.y );
				float3 rotatedValue33_g5081 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5081, float3(1,0,0), break61_g5081.x );
				float3 rotatedValue28_g5081 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5081, float3(0,0,1), break61_g5081.z );
				float3 break36_g5081 = rotatedValue28_g5081;
				float2 appendResult27_g5081 = (float2(break36_g5081.x , break36_g5081.y));
				float4 tex2DNode7_g5081 = tex2D( _D_2, ( ( ( appendResult27_g5081 / _CameraF ) / break36_g5081.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5082 = tex2DNode7_g5081.r;
				float3 break61_g5066 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5157 = ( temp_output_12_0_g5144 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_148_10_g5050 = temp_output_12_0_g5157;
				float3 normalizeResult8_g5064 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5063 = ( ( temp_output_148_10_g5050 * normalizeResult8_g5064 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5063 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5066 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5063 - temp_output_10_0_g5050 ) - temp_output_10_0_g5063 ), float3(0,1,0), break61_g5066.y );
				float3 rotatedValue33_g5066 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5066, float3(1,0,0), break61_g5066.x );
				float3 rotatedValue28_g5066 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5066, float3(0,0,1), break61_g5066.z );
				float3 break36_g5066 = rotatedValue28_g5066;
				float2 appendResult27_g5066 = (float2(break36_g5066.x , break36_g5066.y));
				float4 tex2DNode7_g5066 = tex2D( _D_2, ( ( ( appendResult27_g5066 / _CameraF ) / break36_g5066.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5067 = tex2DNode7_g5066.r;
				float3 break61_g5131 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5158 = ( temp_output_12_0_g5157 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_150_10_g5050 = temp_output_12_0_g5158;
				float3 normalizeResult8_g5129 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5128 = ( ( temp_output_150_10_g5050 * normalizeResult8_g5129 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5128 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5131 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5128 - temp_output_10_0_g5050 ) - temp_output_10_0_g5128 ), float3(0,1,0), break61_g5131.y );
				float3 rotatedValue33_g5131 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5131, float3(1,0,0), break61_g5131.x );
				float3 rotatedValue28_g5131 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5131, float3(0,0,1), break61_g5131.z );
				float3 break36_g5131 = rotatedValue28_g5131;
				float2 appendResult27_g5131 = (float2(break36_g5131.x , break36_g5131.y));
				float4 tex2DNode7_g5131 = tex2D( _D_2, ( ( ( appendResult27_g5131 / _CameraF ) / break36_g5131.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5132 = tex2DNode7_g5131.r;
				float3 break61_g5142 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5145 = ( temp_output_12_0_g5158 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_152_10_g5050 = temp_output_12_0_g5145;
				float3 normalizeResult8_g5140 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5139 = ( ( temp_output_152_10_g5050 * normalizeResult8_g5140 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5139 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5142 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5139 - temp_output_10_0_g5050 ) - temp_output_10_0_g5139 ), float3(0,1,0), break61_g5142.y );
				float3 rotatedValue33_g5142 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5142, float3(1,0,0), break61_g5142.x );
				float3 rotatedValue28_g5142 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5142, float3(0,0,1), break61_g5142.z );
				float3 break36_g5142 = rotatedValue28_g5142;
				float2 appendResult27_g5142 = (float2(break36_g5142.x , break36_g5142.y));
				float4 tex2DNode7_g5142 = tex2D( _D_2, ( ( ( appendResult27_g5142 / _CameraF ) / break36_g5142.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5143 = tex2DNode7_g5142.r;
				float3 break61_g5116 = ( ( ( temp_output_12_0_g5050 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g5146 = ( temp_output_12_0_g5145 + ( ( temp_output_13_0_g5050 - 0.0 ) * 0.1 ) );
				float temp_output_154_10_g5050 = temp_output_12_0_g5146;
				float3 normalizeResult8_g5114 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5113 = ( ( temp_output_154_10_g5050 * normalizeResult8_g5114 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5113 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5116 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5113 - temp_output_10_0_g5050 ) - temp_output_10_0_g5113 ), float3(0,1,0), break61_g5116.y );
				float3 rotatedValue33_g5116 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5116, float3(1,0,0), break61_g5116.x );
				float3 rotatedValue28_g5116 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5116, float3(0,0,1), break61_g5116.z );
				float3 break36_g5116 = rotatedValue28_g5116;
				float2 appendResult27_g5116 = (float2(break36_g5116.x , break36_g5116.y));
				float4 tex2DNode7_g5116 = tex2D( _D_2, ( ( ( appendResult27_g5116 / _CameraF ) / break36_g5116.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5117 = tex2DNode7_g5116.r;
				float temp_output_349_0_g5050 = ( ( 0.2980392 / temp_output_1_0_g5092 ) >= distance( temp_output_10_0_g5088 , temp_output_24_0_g5088 ) ? ( ( 0.2980392 / temp_output_1_0_g5097 ) >= distance( temp_output_10_0_g5093 , temp_output_24_0_g5093 ) ? ( ( 0.2980392 / temp_output_1_0_g5112 ) >= distance( temp_output_10_0_g5108 , temp_output_24_0_g5108 ) ? ( ( 0.2980392 / temp_output_1_0_g5107 ) >= distance( temp_output_10_0_g5103 , temp_output_24_0_g5103 ) ? ( ( 0.2980392 / temp_output_1_0_g5057 ) >= distance( temp_output_10_0_g5053 , temp_output_24_0_g5053 ) ? ( ( 0.2980392 / temp_output_1_0_g5082 ) >= distance( temp_output_10_0_g5078 , temp_output_24_0_g5078 ) ? ( ( 0.2980392 / temp_output_1_0_g5067 ) >= distance( temp_output_10_0_g5063 , temp_output_24_0_g5063 ) ? ( ( 0.2980392 / temp_output_1_0_g5132 ) >= distance( temp_output_10_0_g5128 , temp_output_24_0_g5128 ) ? ( ( 0.2980392 / temp_output_1_0_g5143 ) >= distance( temp_output_10_0_g5139 , temp_output_24_0_g5139 ) ? ( ( 0.2980392 / temp_output_1_0_g5117 ) >= distance( temp_output_10_0_g5113 , temp_output_24_0_g5113 ) ? 100.0 : temp_output_154_10_g5050 ) : temp_output_152_10_g5050 ) : temp_output_150_10_g5050 ) : temp_output_148_10_g5050 ) : temp_output_146_10_g5050 ) : temp_output_144_10_g5050 ) : temp_output_142_10_g5050 ) : temp_output_137_10_g5050 ) : temp_output_136_10_g5050 ) : temp_output_138_10_g5050 );
				float temp_output_284_0_g5050 = ( temp_output_349_0_g5050 - temp_output_118_0_g5050 );
				float temp_output_286_0_g5050 = ( ( ( ( temp_output_349_0_g5050 - 0.0 ) + temp_output_284_0_g5050 ) / 2 ) + 0.0 );
				float temp_output_7_0_g5153 = temp_output_286_0_g5050;
				float temp_output_337_10_g5050 = temp_output_7_0_g5153;
				float3 normalizeResult8_g5160 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5159 = ( ( temp_output_337_10_g5050 * normalizeResult8_g5160 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5159 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5162 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5159 - temp_output_10_0_g5050 ) - temp_output_10_0_g5159 ), float3(0,1,0), break61_g5162.y );
				float3 rotatedValue33_g5162 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5162, float3(1,0,0), break61_g5162.x );
				float3 rotatedValue28_g5162 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5162, float3(0,0,1), break61_g5162.z );
				float3 break36_g5162 = rotatedValue28_g5162;
				float2 appendResult27_g5162 = (float2(break36_g5162.x , break36_g5162.y));
				float4 tex2DNode7_g5162 = tex2D( _D_2, ( ( ( appendResult27_g5162 / _CameraF ) / break36_g5162.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5163 = tex2DNode7_g5162.r;
				float temp_output_2_0_g5153 = ( ( temp_output_7_0_g5153 - ( temp_output_284_0_g5050 + 0.0 ) ) / 2 );
				float temp_output_8_0_g5153 = ( temp_output_7_0_g5153 + temp_output_2_0_g5153 );
				float temp_output_9_0_g5153 = ( temp_output_7_0_g5153 - temp_output_2_0_g5153 );
				float temp_output_360_0_g5050 = ( ( 0.2980392 / temp_output_1_0_g5163 ) >= distance( temp_output_10_0_g5159 , temp_output_24_0_g5159 ) ? ( temp_output_8_0_g5153 > temp_output_9_0_g5153 ? temp_output_8_0_g5153 : temp_output_9_0_g5153 ) : ( temp_output_8_0_g5153 > temp_output_9_0_g5153 ? temp_output_9_0_g5153 : temp_output_8_0_g5153 ) );
				float temp_output_7_0_g5138 = temp_output_360_0_g5050;
				float temp_output_341_10_g5050 = temp_output_7_0_g5138;
				float3 normalizeResult8_g5119 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5118 = ( ( temp_output_341_10_g5050 * normalizeResult8_g5119 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5118 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5121 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5118 - temp_output_10_0_g5050 ) - temp_output_10_0_g5118 ), float3(0,1,0), break61_g5121.y );
				float3 rotatedValue33_g5121 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5121, float3(1,0,0), break61_g5121.x );
				float3 rotatedValue28_g5121 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5121, float3(0,0,1), break61_g5121.z );
				float3 break36_g5121 = rotatedValue28_g5121;
				float2 appendResult27_g5121 = (float2(break36_g5121.x , break36_g5121.y));
				float4 tex2DNode7_g5121 = tex2D( _D_2, ( ( ( appendResult27_g5121 / _CameraF ) / break36_g5121.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5122 = tex2DNode7_g5121.r;
				float temp_output_2_0_g5138 = ( ( temp_output_7_0_g5138 - temp_output_337_10_g5050 ) / 2 );
				float temp_output_8_0_g5138 = ( temp_output_7_0_g5138 + temp_output_2_0_g5138 );
				float temp_output_9_0_g5138 = ( temp_output_7_0_g5138 - temp_output_2_0_g5138 );
				float temp_output_355_0_g5050 = ( ( 0.2980392 / temp_output_1_0_g5122 ) >= distance( temp_output_10_0_g5118 , temp_output_24_0_g5118 ) ? ( temp_output_8_0_g5138 > temp_output_9_0_g5138 ? temp_output_8_0_g5138 : temp_output_9_0_g5138 ) : ( temp_output_8_0_g5138 > temp_output_9_0_g5138 ? temp_output_9_0_g5138 : temp_output_8_0_g5138 ) );
				float temp_output_7_0_g5151 = temp_output_355_0_g5050;
				float temp_output_335_10_g5050 = temp_output_7_0_g5151;
				float3 normalizeResult8_g5084 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5083 = ( ( temp_output_335_10_g5050 * normalizeResult8_g5084 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5083 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5086 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5083 - temp_output_10_0_g5050 ) - temp_output_10_0_g5083 ), float3(0,1,0), break61_g5086.y );
				float3 rotatedValue33_g5086 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5086, float3(1,0,0), break61_g5086.x );
				float3 rotatedValue28_g5086 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5086, float3(0,0,1), break61_g5086.z );
				float3 break36_g5086 = rotatedValue28_g5086;
				float2 appendResult27_g5086 = (float2(break36_g5086.x , break36_g5086.y));
				float4 tex2DNode7_g5086 = tex2D( _D_2, ( ( ( appendResult27_g5086 / _CameraF ) / break36_g5086.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5087 = tex2DNode7_g5086.r;
				float temp_output_2_0_g5151 = ( ( temp_output_7_0_g5151 - temp_output_341_10_g5050 ) / 2 );
				float temp_output_8_0_g5151 = ( temp_output_7_0_g5151 + temp_output_2_0_g5151 );
				float temp_output_9_0_g5151 = ( temp_output_7_0_g5151 - temp_output_2_0_g5151 );
				float temp_output_348_0_g5050 = ( ( 0.2980392 / temp_output_1_0_g5087 ) >= distance( temp_output_10_0_g5083 , temp_output_24_0_g5083 ) ? ( temp_output_8_0_g5151 > temp_output_9_0_g5151 ? temp_output_8_0_g5151 : temp_output_9_0_g5151 ) : ( temp_output_8_0_g5151 > temp_output_9_0_g5151 ? temp_output_9_0_g5151 : temp_output_8_0_g5151 ) );
				float temp_output_7_0_g5155 = temp_output_348_0_g5050;
				float temp_output_339_10_g5050 = temp_output_7_0_g5155;
				float3 normalizeResult8_g5069 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5068 = ( ( temp_output_339_10_g5050 * normalizeResult8_g5069 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5068 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5071 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5068 - temp_output_10_0_g5050 ) - temp_output_10_0_g5068 ), float3(0,1,0), break61_g5071.y );
				float3 rotatedValue33_g5071 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5071, float3(1,0,0), break61_g5071.x );
				float3 rotatedValue28_g5071 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5071, float3(0,0,1), break61_g5071.z );
				float3 break36_g5071 = rotatedValue28_g5071;
				float2 appendResult27_g5071 = (float2(break36_g5071.x , break36_g5071.y));
				float4 tex2DNode7_g5071 = tex2D( _D_2, ( ( ( appendResult27_g5071 / _CameraF ) / break36_g5071.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5072 = tex2DNode7_g5071.r;
				float temp_output_2_0_g5155 = ( ( temp_output_7_0_g5155 - temp_output_335_10_g5050 ) / 2 );
				float temp_output_8_0_g5155 = ( temp_output_7_0_g5155 + temp_output_2_0_g5155 );
				float temp_output_9_0_g5155 = ( temp_output_7_0_g5155 - temp_output_2_0_g5155 );
				float temp_output_7_0_g5150 = ( ( 0.2980392 / temp_output_1_0_g5072 ) >= distance( temp_output_10_0_g5068 , temp_output_24_0_g5068 ) ? ( temp_output_8_0_g5155 > temp_output_9_0_g5155 ? temp_output_8_0_g5155 : temp_output_9_0_g5155 ) : ( temp_output_8_0_g5155 > temp_output_9_0_g5155 ? temp_output_9_0_g5155 : temp_output_8_0_g5155 ) );
				float temp_output_334_10_g5050 = temp_output_7_0_g5150;
				float3 normalizeResult8_g5134 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5133 = ( ( temp_output_334_10_g5050 * normalizeResult8_g5134 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5133 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5136 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5133 - temp_output_10_0_g5050 ) - temp_output_10_0_g5133 ), float3(0,1,0), break61_g5136.y );
				float3 rotatedValue33_g5136 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5136, float3(1,0,0), break61_g5136.x );
				float3 rotatedValue28_g5136 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5136, float3(0,0,1), break61_g5136.z );
				float3 break36_g5136 = rotatedValue28_g5136;
				float2 appendResult27_g5136 = (float2(break36_g5136.x , break36_g5136.y));
				float4 tex2DNode7_g5136 = tex2D( _D_2, ( ( ( appendResult27_g5136 / _CameraF ) / break36_g5136.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5137 = tex2DNode7_g5136.r;
				float temp_output_2_0_g5150 = ( ( temp_output_7_0_g5150 - temp_output_339_10_g5050 ) / 2 );
				float temp_output_8_0_g5150 = ( temp_output_7_0_g5150 + temp_output_2_0_g5150 );
				float temp_output_9_0_g5150 = ( temp_output_7_0_g5150 - temp_output_2_0_g5150 );
				float temp_output_7_0_g5154 = ( ( 0.2980392 / temp_output_1_0_g5137 ) >= distance( temp_output_10_0_g5133 , temp_output_24_0_g5133 ) ? ( temp_output_8_0_g5150 > temp_output_9_0_g5150 ? temp_output_8_0_g5150 : temp_output_9_0_g5150 ) : ( temp_output_8_0_g5150 > temp_output_9_0_g5150 ? temp_output_9_0_g5150 : temp_output_8_0_g5150 ) );
				float temp_output_338_10_g5050 = temp_output_7_0_g5154;
				float3 normalizeResult8_g5124 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g5123 = ( ( temp_output_338_10_g5050 * normalizeResult8_g5124 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g5123 = temp_output_9_0_g5050;
				float3 rotatedValue31_g5126 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g5123 - temp_output_10_0_g5050 ) - temp_output_10_0_g5123 ), float3(0,1,0), break61_g5126.y );
				float3 rotatedValue33_g5126 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g5126, float3(1,0,0), break61_g5126.x );
				float3 rotatedValue28_g5126 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g5126, float3(0,0,1), break61_g5126.z );
				float3 break36_g5126 = rotatedValue28_g5126;
				float2 appendResult27_g5126 = (float2(break36_g5126.x , break36_g5126.y));
				float4 tex2DNode7_g5126 = tex2D( _D_2, ( ( ( appendResult27_g5126 / _CameraF ) / break36_g5126.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_1_0_g5127 = tex2DNode7_g5126.r;
				float temp_output_2_0_g5154 = ( ( temp_output_7_0_g5154 - temp_output_334_10_g5050 ) / 2 );
				float temp_output_8_0_g5154 = ( temp_output_7_0_g5154 + temp_output_2_0_g5154 );
				float temp_output_9_0_g5154 = ( temp_output_7_0_g5154 - temp_output_2_0_g5154 );
				float temp_output_356_0_g5050 = ( ( 0.2980392 / temp_output_1_0_g5127 ) >= distance( temp_output_10_0_g5123 , temp_output_24_0_g5123 ) ? ( temp_output_8_0_g5154 > temp_output_9_0_g5154 ? temp_output_8_0_g5154 : temp_output_9_0_g5154 ) : ( temp_output_8_0_g5154 > temp_output_9_0_g5154 ? temp_output_9_0_g5154 : temp_output_8_0_g5154 ) );
				float temp_output_168_0 = temp_output_356_0_g5050;
				float temp_output_153_0 = max( ( _UseCam_1 > 0.0 ? temp_output_169_0 : 0.0 ) , ( _UseCam_2 > 0.0 ? temp_output_168_0 : 0.0 ) );
				float temp_output_159_0 = ( temp_output_112_0 - temp_output_153_0 );
				float3 break5_g5044 = ( ( ( _Camera1Rotation * 3.141593 ) / 180 ) * -1 );
				float3 normalizeResult8_g5164 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_158_0 = ( ( temp_output_153_0 * normalizeResult8_g5164 ) + _WorldSpaceCameraPos );
				float3 temp_output_53_0_g5044 = ( ( temp_output_158_0 - _PositionOffset ) - _Camera1Position );
				float3 rotatedValue17_g5044 = RotateAroundAxis( float3( 0,0,0 ), temp_output_53_0_g5044, float3(0,1,0), break5_g5044.y );
				float3 rotatedValue12_g5044 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue17_g5044, float3(1,0,0), break5_g5044.x );
				float3 rotatedValue10_g5044 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue12_g5044, float3(0,0,1), break5_g5044.z );
				float3 break3_g5044 = rotatedValue10_g5044;
				float2 appendResult49_g5044 = (float2(break3_g5044.x , break3_g5044.y));
				float2 temp_output_7_0_g5044 = ( ( ( appendResult49_g5044 / _CameraF ) / break3_g5044.z ) + float2( 0.5,0.5 ) );
				float3 break5_g5043 = ( ( ( _Camera2Rotation * 3.141593 ) / 180 ) * -1 );
				float3 temp_output_53_0_g5043 = ( ( temp_output_158_0 - _PositionOffset ) - _Camera2Position );
				float3 rotatedValue17_g5043 = RotateAroundAxis( float3( 0,0,0 ), temp_output_53_0_g5043, float3(0,1,0), break5_g5043.y );
				float3 rotatedValue12_g5043 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue17_g5043, float3(1,0,0), break5_g5043.x );
				float3 rotatedValue10_g5043 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue12_g5043, float3(0,0,1), break5_g5043.z );
				float3 break3_g5043 = rotatedValue10_g5043;
				float2 appendResult49_g5043 = (float2(break3_g5043.x , break3_g5043.y));
				float2 temp_output_7_0_g5043 = ( ( ( appendResult49_g5043 / _CameraF ) / break3_g5043.z ) + float2( 0.5,0.5 ) );
				float4 temp_cast_0 = (( ( temp_output_153_0 - 0.7 ) / ( temp_output_112_0 - 0.7 ) )).xxxx;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( _UseColor_1 > 0.0 ? ( temp_output_159_0 <= 0.1 ? float4( 0,0,0,0 ) : tex2D( _RGB_1, temp_output_7_0_g5044 ) ) : ( _UseColor_2 > 0.0 ? ( temp_output_159_0 <= 0.1 ? float4( 0,0,0,0 ) : tex2D( _RGB_2, temp_output_7_0_g5043 ) ) : temp_cast_0 ) ).rgb;
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
			float3 _PositionOffset;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _UseColor_1;
			float _MaxDepthDelta;
			float _UseCam_1;
			float _CameraF;
			float _UseCam_2;
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
			float3 _PositionOffset;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _UseColor_1;
			float _MaxDepthDelta;
			float _UseCam_1;
			float _CameraF;
			float _UseCam_2;
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
-196;-1027;1920;1006;527.6315;893.0225;1.51014;True;False
Node;AmplifyShaderEditor.TexturePropertyNode;8;-1171.978,156.1476;Inherit;True;Property;_RGB_2;RGB_2;9;0;Create;True;0;0;0;False;0;False;3d7039e2d91fd44f68f4f05c291fb0a7;3d7039e2d91fd44f68f4f05c291fb0a7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Compare;160;1395.403,-842.2052;Inherit;False;5;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;28;-1213.134,653.7977;Inherit;False;Property;_Camera2Rotation;Camera 2 Rotation;12;0;Create;True;0;0;0;False;0;False;0,0,0;0,315,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMaxOpNode;153;284.0412,-240.6069;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;111;-1006.907,-169.4125;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1162.789,372.7456;Inherit;True;Property;_D_2;D_2;10;0;Create;True;0;0;0;False;0;False;008ecc74e3a374dc7b0378989802d355;008ecc74e3a374dc7b0378989802d355;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;155;-375.416,780.5508;Inherit;False;CamDepthToWorldPosition;-1;;5045;a9d725c4349ce4106bfa1039b7647c13;0;1;9;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;74;-367.9774,-1775.448;Inherit;False;CamDepthToWorldPosition;-1;;5047;a9d725c4349ce4106bfa1039b7647c13;0;1;9;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;6;-950.1835,-956.5697;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;110;-1128.907,-165.4125;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;7;-905.4182,156.1476;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;108;-1251.907,-162.4125;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;44;-1052.89,-297.0006;Inherit;False;Property;_MaxDepthDelta;MaxDepthDelta;4;0;Create;True;0;0;0;False;0;False;4;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;167;-135.7876,-8.561789;Inherit;False;Property;_UseCam_2;UseCam_2;3;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;168;-657.749,779.4965;Inherit;False;IterativelyGetDepth;14;;5050;737fc4a0ba92542e0a72347a837a8648;0;5;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;104;-1741.135,-280.0809;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;170;1651.186,182.4345;Inherit;False;Property;_UseColor_2;UseColor_2;1;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;29;-1203.041,860.6336;Inherit;False;Property;_Camera2Position;Camera 2 Position;11;0;Create;True;0;0;0;False;0;False;0,0,0;0.824,1.781,-0.752;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;158;482.2842,-584.1273;Inherit;False;CamDepthToWorldPosition;-1;;5164;a9d725c4349ce4106bfa1039b7647c13;0;1;9;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;161;1168.05,-822.5859;Inherit;False;Constant;_Float2;Float 2;90;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;112;-852.9073,-235.4125;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;5;-1216.744,-956.5697;Inherit;True;Property;_RGB_1;RGB_1;5;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;6e525e0933ba04ebe9d0f3860234333d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;10;-1220.226,-748.0662;Inherit;True;Property;_D_1;D_1;6;0;Create;True;0;0;0;False;0;False;0146383e3995643be92047c1c3fd405d;0146383e3995643be92047c1c3fd405d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;9;-953.6662,-748.0662;Inherit;True;Property;_TextureSample2;Texture Sample 2;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;159;865.9754,-572.1017;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;107;-1395.135,-154.0809;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;117;1390.878,115.315;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;26;-507.2855,-659.1292;Inherit;False;F256ToDepth;-1;;4928;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;-896.2289,372.7456;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;31;-1175.32,-1381.268;Inherit;False;Property;_Camera1Position;Camera 1 Position;7;0;Create;True;0;0;0;False;0;False;0,0,0;-0.026,1.63,-1.063;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;63;824.549,-1107.144;Inherit;False;SingleCameraMapping;189;;5044;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;27;-2199.773,-433.9232;Inherit;False;Property;_PositionOffset;PositionOffset;13;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Compare;166;27.21982,-10.22895;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;115;1372.663,-17.81841;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;93;1598.331,52.01149;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;169;-617.7129,-1675.456;Inherit;False;IterativelyGetDepth;14;;4929;737fc4a0ba92542e0a72347a837a8648;0;5;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;162;1814.608,-5.811478;Inherit;False;Property;_UseColor_1;UseColor_1;0;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;163;1952.608,-5.811478;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;165;41.3006,-612.7036;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;30;-1178.169,-1538.857;Inherit;False;Property;_Camera1Rotation;Camera 1 Rotation;8;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;164;-96.69938,-612.7036;Inherit;False;Property;_UseCam_1;UseCam_1;2;1;[Toggle];Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;154;967.4815,260.9085;Inherit;False;SingleCameraMapping;189;;5043;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.Compare;171;1802.501,181.2142;Inherit;False;2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;116;1178.055,77.08279;Inherit;False;Constant;_Float0;Float 0;50;0;Create;True;0;0;0;False;0;False;0.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;172;1370.615,330.1912;Inherit;False;5;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2188.991,-3.530464;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;NovelView;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;160;3;63;0
WireConnection;153;0;165;0
WireConnection;153;1;166;0
WireConnection;111;0;110;0
WireConnection;155;9;168;0
WireConnection;74;9;169;0
WireConnection;6;0;5;0
WireConnection;110;0;108;0
WireConnection;110;1;108;2
WireConnection;7;0;8;0
WireConnection;108;0;107;0
WireConnection;168;13;112;0
WireConnection;168;10;27;0
WireConnection;168;12;28;0
WireConnection;168;9;29;0
WireConnection;168;11;12;0
WireConnection;158;9;153;0
WireConnection;112;0;44;0
WireConnection;112;1;111;0
WireConnection;9;0;10;0
WireConnection;159;0;112;0
WireConnection;159;1;153;0
WireConnection;107;0;104;0
WireConnection;107;1;27;0
WireConnection;117;0;112;0
WireConnection;117;1;116;0
WireConnection;26;1;9;1
WireConnection;11;0;12;0
WireConnection;63;55;5;0
WireConnection;63;79;10;0
WireConnection;63;56;158;0
WireConnection;63;57;27;0
WireConnection;63;60;30;0
WireConnection;63;61;31;0
WireConnection;166;0;167;0
WireConnection;166;2;168;0
WireConnection;115;0;153;0
WireConnection;115;1;116;0
WireConnection;93;0;115;0
WireConnection;93;1;117;0
WireConnection;169;13;112;0
WireConnection;169;10;27;0
WireConnection;169;12;30;0
WireConnection;169;9;31;0
WireConnection;169;11;10;0
WireConnection;163;0;162;0
WireConnection;163;2;160;0
WireConnection;163;3;171;0
WireConnection;165;0;164;0
WireConnection;165;2;169;0
WireConnection;154;55;8;0
WireConnection;154;79;12;0
WireConnection;154;56;158;0
WireConnection;154;57;27;0
WireConnection;154;60;28;0
WireConnection;154;61;29;0
WireConnection;171;0;170;0
WireConnection;171;2;172;0
WireConnection;171;3;93;0
WireConnection;172;0;159;0
WireConnection;172;1;161;0
WireConnection;172;3;154;0
WireConnection;1;2;163;0
ASEEND*/
//CHKSM=82F4F583D07EFED398FB75DCA056594D1F041317