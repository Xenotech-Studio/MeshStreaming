// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "NovelView"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[ASEBegin]_RGB_1("RGB_1", 2D) = "white" {}
		_CameraF("Camera F", Range( 1 , 2)) = 1.1543
		_DepthB("Depth B", Float) = 0.022267
		_DepthK("Depth K", Float) = 0.2966
		_MaxDepthDelta("MaxDepthDelta", Float) = 4
		_RGB_2("RGB_2", 2D) = "white" {}
		_D_1("D_1", 2D) = "white" {}
		_D_2("D_2", 2D) = "white" {}
		_Camera2Position("Camera 2 Position", Vector) = (0,0,0,0)
		_Camera1Position("Camera 1 Position", Vector) = (0,0,0,0)
		_Camera1Rotation("Camera 1 Rotation", Vector) = (0,0,0,0)
		_Camera2Rotation("Camera 2 Rotation", Vector) = (0,0,0,0)
		[ASEEnd]_PositionOffset("PositionOffset", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

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
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _RGB_2_ST;
			float4 _RGB_1_ST;
			float3 _Camera1Rotation;
			float3 _PositionOffset;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _DepthK;
			float _MaxDepthDelta;
			float _CameraF;
			float _DepthB;
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
			sampler2D _RGB_2;
			sampler2D _RGB_1;


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

				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
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
				float4 ase_texcoord : TEXCOORD0;

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
				o.ase_texcoord = v.ase_texcoord;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
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
				float3 temp_output_12_0_g4110 = _Camera1Rotation;
				float3 break61_g4137 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4120 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4202 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4212 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4132 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4149 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4196 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4217 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4155 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float3 break108 = ( _WorldSpaceCameraPos - _PositionOffset );
				float2 appendResult110 = (float2(break108.x , break108.z));
				float temp_output_112_0 = ( _MaxDepthDelta + length( appendResult110 ) );
				float temp_output_13_0_g4110 = temp_output_112_0;
				float temp_output_118_0_g4110 = ( 0.1 * temp_output_13_0_g4110 );
				float temp_output_12_0_g4168 = temp_output_118_0_g4110;
				float temp_output_138_10_g4110 = temp_output_12_0_g4168;
				float3 normalizeResult8_g4153 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4152 = ( ( temp_output_138_10_g4110 * normalizeResult8_g4153 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4110 = _PositionOffset;
				float3 temp_output_9_0_g4110 = _Camera1Position;
				float3 temp_output_10_0_g4152 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4155 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4152 - temp_output_10_0_g4110 ) - temp_output_10_0_g4152 ), float3(0,1,0), break61_g4155.y );
				float3 rotatedValue33_g4155 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4155, float3(1,0,0), break61_g4155.x );
				float3 rotatedValue28_g4155 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4155, float3(0,0,1), break61_g4155.z );
				float3 break36_g4155 = rotatedValue28_g4155;
				float2 appendResult27_g4155 = (float2(break36_g4155.x , break36_g4155.y));
				float4 tex2DNode7_g4155 = tex2D( _D_1, ( ( ( appendResult27_g4155 / _CameraF ) / break36_g4155.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4160 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4139 = ( temp_output_12_0_g4168 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g4110 = temp_output_12_0_g4139;
				float3 normalizeResult8_g4158 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4157 = ( ( temp_output_136_10_g4110 * normalizeResult8_g4158 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4157 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4160 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4157 - temp_output_10_0_g4110 ) - temp_output_10_0_g4157 ), float3(0,1,0), break61_g4160.y );
				float3 rotatedValue33_g4160 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4160, float3(1,0,0), break61_g4160.x );
				float3 rotatedValue28_g4160 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4160, float3(0,0,1), break61_g4160.z );
				float3 break36_g4160 = rotatedValue28_g4160;
				float2 appendResult27_g4160 = (float2(break36_g4160.x , break36_g4160.y));
				float4 tex2DNode7_g4160 = tex2D( _D_1, ( ( ( appendResult27_g4160 / _CameraF ) / break36_g4160.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4184 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4151 = ( temp_output_12_0_g4139 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g4110 = temp_output_12_0_g4151;
				float3 normalizeResult8_g4182 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4181 = ( ( temp_output_137_10_g4110 * normalizeResult8_g4182 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4181 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4184 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4181 - temp_output_10_0_g4110 ) - temp_output_10_0_g4181 ), float3(0,1,0), break61_g4184.y );
				float3 rotatedValue33_g4184 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4184, float3(1,0,0), break61_g4184.x );
				float3 rotatedValue28_g4184 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4184, float3(0,0,1), break61_g4184.z );
				float3 break36_g4184 = rotatedValue28_g4184;
				float2 appendResult27_g4184 = (float2(break36_g4184.x , break36_g4184.y));
				float4 tex2DNode7_g4184 = tex2D( _D_1, ( ( ( appendResult27_g4184 / _CameraF ) / break36_g4184.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4179 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4192 = ( temp_output_12_0_g4151 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g4110 = temp_output_12_0_g4192;
				float3 normalizeResult8_g4177 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4176 = ( ( temp_output_142_10_g4110 * normalizeResult8_g4177 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4176 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4179 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4176 - temp_output_10_0_g4110 ) - temp_output_10_0_g4176 ), float3(0,1,0), break61_g4179.y );
				float3 rotatedValue33_g4179 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4179, float3(1,0,0), break61_g4179.x );
				float3 rotatedValue28_g4179 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4179, float3(0,0,1), break61_g4179.z );
				float3 break36_g4179 = rotatedValue28_g4179;
				float2 appendResult27_g4179 = (float2(break36_g4179.x , break36_g4179.y));
				float4 tex2DNode7_g4179 = tex2D( _D_1, ( ( ( appendResult27_g4179 / _CameraF ) / break36_g4179.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4114 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4198 = ( temp_output_12_0_g4192 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g4110 = temp_output_12_0_g4198;
				float3 normalizeResult8_g4112 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4111 = ( ( temp_output_144_10_g4110 * normalizeResult8_g4112 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4111 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4114 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4111 - temp_output_10_0_g4110 ) - temp_output_10_0_g4111 ), float3(0,1,0), break61_g4114.y );
				float3 rotatedValue33_g4114 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4114, float3(1,0,0), break61_g4114.x );
				float3 rotatedValue28_g4114 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4114, float3(0,0,1), break61_g4114.z );
				float3 break36_g4114 = rotatedValue28_g4114;
				float2 appendResult27_g4114 = (float2(break36_g4114.x , break36_g4114.y));
				float4 tex2DNode7_g4114 = tex2D( _D_1, ( ( ( appendResult27_g4114 / _CameraF ) / break36_g4114.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4144 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4116 = ( temp_output_12_0_g4198 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g4110 = temp_output_12_0_g4116;
				float3 normalizeResult8_g4142 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4141 = ( ( temp_output_146_10_g4110 * normalizeResult8_g4142 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4141 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4144 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4141 - temp_output_10_0_g4110 ) - temp_output_10_0_g4141 ), float3(0,1,0), break61_g4144.y );
				float3 rotatedValue33_g4144 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4144, float3(1,0,0), break61_g4144.x );
				float3 rotatedValue28_g4144 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4144, float3(0,0,1), break61_g4144.z );
				float3 break36_g4144 = rotatedValue28_g4144;
				float2 appendResult27_g4144 = (float2(break36_g4144.x , break36_g4144.y));
				float4 tex2DNode7_g4144 = tex2D( _D_1, ( ( ( appendResult27_g4144 / _CameraF ) / break36_g4144.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4125 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4174 = ( temp_output_12_0_g4116 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_148_10_g4110 = temp_output_12_0_g4174;
				float3 normalizeResult8_g4123 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4122 = ( ( temp_output_148_10_g4110 * normalizeResult8_g4123 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4122 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4125 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4122 - temp_output_10_0_g4110 ) - temp_output_10_0_g4122 ), float3(0,1,0), break61_g4125.y );
				float3 rotatedValue33_g4125 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4125, float3(1,0,0), break61_g4125.x );
				float3 rotatedValue28_g4125 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4125, float3(0,0,1), break61_g4125.z );
				float3 break36_g4125 = rotatedValue28_g4125;
				float2 appendResult27_g4125 = (float2(break36_g4125.x , break36_g4125.y));
				float4 tex2DNode7_g4125 = tex2D( _D_1, ( ( ( appendResult27_g4125 / _CameraF ) / break36_g4125.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4207 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4175 = ( temp_output_12_0_g4174 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_150_10_g4110 = temp_output_12_0_g4175;
				float3 normalizeResult8_g4205 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4204 = ( ( temp_output_150_10_g4110 * normalizeResult8_g4205 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4204 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4207 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4204 - temp_output_10_0_g4110 ) - temp_output_10_0_g4204 ), float3(0,1,0), break61_g4207.y );
				float3 rotatedValue33_g4207 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4207, float3(1,0,0), break61_g4207.x );
				float3 rotatedValue28_g4207 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4207, float3(0,0,1), break61_g4207.z );
				float3 break36_g4207 = rotatedValue28_g4207;
				float2 appendResult27_g4207 = (float2(break36_g4207.x , break36_g4207.y));
				float4 tex2DNode7_g4207 = tex2D( _D_1, ( ( ( appendResult27_g4207 / _CameraF ) / break36_g4207.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4222 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4127 = ( temp_output_12_0_g4175 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_152_10_g4110 = temp_output_12_0_g4127;
				float3 normalizeResult8_g4220 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4219 = ( ( temp_output_152_10_g4110 * normalizeResult8_g4220 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4219 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4222 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4219 - temp_output_10_0_g4110 ) - temp_output_10_0_g4219 ), float3(0,1,0), break61_g4222.y );
				float3 rotatedValue33_g4222 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4222, float3(1,0,0), break61_g4222.x );
				float3 rotatedValue28_g4222 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4222, float3(0,0,1), break61_g4222.z );
				float3 break36_g4222 = rotatedValue28_g4222;
				float2 appendResult27_g4222 = (float2(break36_g4222.x , break36_g4222.y));
				float4 tex2DNode7_g4222 = tex2D( _D_1, ( ( ( appendResult27_g4222 / _CameraF ) / break36_g4222.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4189 = ( ( ( temp_output_12_0_g4110 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4128 = ( temp_output_12_0_g4127 + ( ( temp_output_13_0_g4110 - 0.0 ) * 0.1 ) );
				float temp_output_154_10_g4110 = temp_output_12_0_g4128;
				float3 normalizeResult8_g4187 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4186 = ( ( temp_output_154_10_g4110 * normalizeResult8_g4187 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4186 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4189 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4186 - temp_output_10_0_g4110 ) - temp_output_10_0_g4186 ), float3(0,1,0), break61_g4189.y );
				float3 rotatedValue33_g4189 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4189, float3(1,0,0), break61_g4189.x );
				float3 rotatedValue28_g4189 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4189, float3(0,0,1), break61_g4189.z );
				float3 break36_g4189 = rotatedValue28_g4189;
				float2 appendResult27_g4189 = (float2(break36_g4189.x , break36_g4189.y));
				float4 tex2DNode7_g4189 = tex2D( _D_1, ( ( ( appendResult27_g4189 / _CameraF ) / break36_g4189.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_281_0_g4110 = ( ( ( _DepthK / tex2DNode7_g4155.r ) + _DepthB ) >= distance( temp_output_10_0_g4152 , temp_output_24_0_g4152 ) ? ( ( ( _DepthK / tex2DNode7_g4160.r ) + _DepthB ) >= distance( temp_output_10_0_g4157 , temp_output_24_0_g4157 ) ? ( ( ( _DepthK / tex2DNode7_g4184.r ) + _DepthB ) >= distance( temp_output_10_0_g4181 , temp_output_24_0_g4181 ) ? ( ( ( _DepthK / tex2DNode7_g4179.r ) + _DepthB ) >= distance( temp_output_10_0_g4176 , temp_output_24_0_g4176 ) ? ( ( ( _DepthK / tex2DNode7_g4114.r ) + _DepthB ) >= distance( temp_output_10_0_g4111 , temp_output_24_0_g4111 ) ? ( ( ( _DepthK / tex2DNode7_g4144.r ) + _DepthB ) >= distance( temp_output_10_0_g4141 , temp_output_24_0_g4141 ) ? ( ( ( _DepthK / tex2DNode7_g4125.r ) + _DepthB ) >= distance( temp_output_10_0_g4122 , temp_output_24_0_g4122 ) ? ( ( ( _DepthK / tex2DNode7_g4207.r ) + _DepthB ) >= distance( temp_output_10_0_g4204 , temp_output_24_0_g4204 ) ? ( ( ( _DepthK / tex2DNode7_g4222.r ) + _DepthB ) >= distance( temp_output_10_0_g4219 , temp_output_24_0_g4219 ) ? ( ( ( _DepthK / tex2DNode7_g4189.r ) + _DepthB ) >= distance( temp_output_10_0_g4186 , temp_output_24_0_g4186 ) ? 100.0 : temp_output_154_10_g4110 ) : temp_output_152_10_g4110 ) : temp_output_150_10_g4110 ) : temp_output_148_10_g4110 ) : temp_output_146_10_g4110 ) : temp_output_144_10_g4110 ) : temp_output_142_10_g4110 ) : temp_output_137_10_g4110 ) : temp_output_136_10_g4110 ) : temp_output_138_10_g4110 );
				float temp_output_284_0_g4110 = ( temp_output_281_0_g4110 - temp_output_118_0_g4110 );
				float temp_output_286_0_g4110 = ( ( ( ( temp_output_281_0_g4110 - 0.0 ) + temp_output_284_0_g4110 ) / 2 ) + 0.0 );
				float temp_output_7_0_g4165 = temp_output_286_0_g4110;
				float temp_output_337_10_g4110 = temp_output_7_0_g4165;
				float3 normalizeResult8_g4215 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4214 = ( ( temp_output_337_10_g4110 * normalizeResult8_g4215 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4214 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4217 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4214 - temp_output_10_0_g4110 ) - temp_output_10_0_g4214 ), float3(0,1,0), break61_g4217.y );
				float3 rotatedValue33_g4217 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4217, float3(1,0,0), break61_g4217.x );
				float3 rotatedValue28_g4217 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4217, float3(0,0,1), break61_g4217.z );
				float3 break36_g4217 = rotatedValue28_g4217;
				float2 appendResult27_g4217 = (float2(break36_g4217.x , break36_g4217.y));
				float4 tex2DNode7_g4217 = tex2D( _D_1, ( ( ( appendResult27_g4217 / _CameraF ) / break36_g4217.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4165 = ( ( temp_output_7_0_g4165 - ( temp_output_284_0_g4110 + 0.0 ) ) / 2 );
				float temp_output_8_0_g4165 = ( temp_output_7_0_g4165 + temp_output_2_0_g4165 );
				float temp_output_9_0_g4165 = ( temp_output_7_0_g4165 - temp_output_2_0_g4165 );
				float temp_output_266_0_g4110 = ( ( ( _DepthK / tex2DNode7_g4217.r ) + _DepthB ) >= distance( temp_output_10_0_g4214 , temp_output_24_0_g4214 ) ? ( temp_output_8_0_g4165 > temp_output_9_0_g4165 ? temp_output_8_0_g4165 : temp_output_9_0_g4165 ) : ( temp_output_8_0_g4165 > temp_output_9_0_g4165 ? temp_output_9_0_g4165 : temp_output_8_0_g4165 ) );
				float temp_output_7_0_g4191 = temp_output_266_0_g4110;
				float temp_output_341_10_g4110 = temp_output_7_0_g4191;
				float3 normalizeResult8_g4194 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4193 = ( ( temp_output_341_10_g4110 * normalizeResult8_g4194 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4193 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4196 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4193 - temp_output_10_0_g4110 ) - temp_output_10_0_g4193 ), float3(0,1,0), break61_g4196.y );
				float3 rotatedValue33_g4196 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4196, float3(1,0,0), break61_g4196.x );
				float3 rotatedValue28_g4196 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4196, float3(0,0,1), break61_g4196.z );
				float3 break36_g4196 = rotatedValue28_g4196;
				float2 appendResult27_g4196 = (float2(break36_g4196.x , break36_g4196.y));
				float4 tex2DNode7_g4196 = tex2D( _D_1, ( ( ( appendResult27_g4196 / _CameraF ) / break36_g4196.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4191 = ( ( temp_output_7_0_g4191 - temp_output_337_10_g4110 ) / 2 );
				float temp_output_8_0_g4191 = ( temp_output_7_0_g4191 + temp_output_2_0_g4191 );
				float temp_output_9_0_g4191 = ( temp_output_7_0_g4191 - temp_output_2_0_g4191 );
				float temp_output_276_0_g4110 = ( ( ( _DepthK / tex2DNode7_g4196.r ) + _DepthB ) >= distance( temp_output_10_0_g4193 , temp_output_24_0_g4193 ) ? ( temp_output_8_0_g4191 > temp_output_9_0_g4191 ? temp_output_8_0_g4191 : temp_output_9_0_g4191 ) : ( temp_output_8_0_g4191 > temp_output_9_0_g4191 ? temp_output_9_0_g4191 : temp_output_8_0_g4191 ) );
				float temp_output_7_0_g4163 = temp_output_276_0_g4110;
				float temp_output_335_10_g4110 = temp_output_7_0_g4163;
				float3 normalizeResult8_g4147 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4146 = ( ( temp_output_335_10_g4110 * normalizeResult8_g4147 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4146 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4149 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4146 - temp_output_10_0_g4110 ) - temp_output_10_0_g4146 ), float3(0,1,0), break61_g4149.y );
				float3 rotatedValue33_g4149 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4149, float3(1,0,0), break61_g4149.x );
				float3 rotatedValue28_g4149 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4149, float3(0,0,1), break61_g4149.z );
				float3 break36_g4149 = rotatedValue28_g4149;
				float2 appendResult27_g4149 = (float2(break36_g4149.x , break36_g4149.y));
				float4 tex2DNode7_g4149 = tex2D( _D_1, ( ( ( appendResult27_g4149 / _CameraF ) / break36_g4149.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4163 = ( ( temp_output_7_0_g4163 - temp_output_341_10_g4110 ) / 2 );
				float temp_output_8_0_g4163 = ( temp_output_7_0_g4163 + temp_output_2_0_g4163 );
				float temp_output_9_0_g4163 = ( temp_output_7_0_g4163 - temp_output_2_0_g4163 );
				float temp_output_282_0_g4110 = ( ( ( _DepthK / tex2DNode7_g4149.r ) + _DepthB ) >= distance( temp_output_10_0_g4146 , temp_output_24_0_g4146 ) ? ( temp_output_8_0_g4163 > temp_output_9_0_g4163 ? temp_output_8_0_g4163 : temp_output_9_0_g4163 ) : ( temp_output_8_0_g4163 > temp_output_9_0_g4163 ? temp_output_9_0_g4163 : temp_output_8_0_g4163 ) );
				float temp_output_7_0_g4167 = temp_output_282_0_g4110;
				float temp_output_339_10_g4110 = temp_output_7_0_g4167;
				float3 normalizeResult8_g4130 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4129 = ( ( temp_output_339_10_g4110 * normalizeResult8_g4130 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4129 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4132 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4129 - temp_output_10_0_g4110 ) - temp_output_10_0_g4129 ), float3(0,1,0), break61_g4132.y );
				float3 rotatedValue33_g4132 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4132, float3(1,0,0), break61_g4132.x );
				float3 rotatedValue28_g4132 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4132, float3(0,0,1), break61_g4132.z );
				float3 break36_g4132 = rotatedValue28_g4132;
				float2 appendResult27_g4132 = (float2(break36_g4132.x , break36_g4132.y));
				float4 tex2DNode7_g4132 = tex2D( _D_1, ( ( ( appendResult27_g4132 / _CameraF ) / break36_g4132.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4167 = ( ( temp_output_7_0_g4167 - temp_output_335_10_g4110 ) / 2 );
				float temp_output_8_0_g4167 = ( temp_output_7_0_g4167 + temp_output_2_0_g4167 );
				float temp_output_9_0_g4167 = ( temp_output_7_0_g4167 - temp_output_2_0_g4167 );
				float temp_output_7_0_g4162 = ( ( ( _DepthK / tex2DNode7_g4132.r ) + _DepthB ) >= distance( temp_output_10_0_g4129 , temp_output_24_0_g4129 ) ? ( temp_output_8_0_g4167 > temp_output_9_0_g4167 ? temp_output_8_0_g4167 : temp_output_9_0_g4167 ) : ( temp_output_8_0_g4167 > temp_output_9_0_g4167 ? temp_output_9_0_g4167 : temp_output_8_0_g4167 ) );
				float temp_output_334_10_g4110 = temp_output_7_0_g4162;
				float3 normalizeResult8_g4210 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4209 = ( ( temp_output_334_10_g4110 * normalizeResult8_g4210 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4209 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4212 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4209 - temp_output_10_0_g4110 ) - temp_output_10_0_g4209 ), float3(0,1,0), break61_g4212.y );
				float3 rotatedValue33_g4212 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4212, float3(1,0,0), break61_g4212.x );
				float3 rotatedValue28_g4212 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4212, float3(0,0,1), break61_g4212.z );
				float3 break36_g4212 = rotatedValue28_g4212;
				float2 appendResult27_g4212 = (float2(break36_g4212.x , break36_g4212.y));
				float4 tex2DNode7_g4212 = tex2D( _D_1, ( ( ( appendResult27_g4212 / _CameraF ) / break36_g4212.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4162 = ( ( temp_output_7_0_g4162 - temp_output_339_10_g4110 ) / 2 );
				float temp_output_8_0_g4162 = ( temp_output_7_0_g4162 + temp_output_2_0_g4162 );
				float temp_output_9_0_g4162 = ( temp_output_7_0_g4162 - temp_output_2_0_g4162 );
				float temp_output_7_0_g4166 = ( ( ( _DepthK / tex2DNode7_g4212.r ) + _DepthB ) >= distance( temp_output_10_0_g4209 , temp_output_24_0_g4209 ) ? ( temp_output_8_0_g4162 > temp_output_9_0_g4162 ? temp_output_8_0_g4162 : temp_output_9_0_g4162 ) : ( temp_output_8_0_g4162 > temp_output_9_0_g4162 ? temp_output_9_0_g4162 : temp_output_8_0_g4162 ) );
				float temp_output_338_10_g4110 = temp_output_7_0_g4166;
				float3 normalizeResult8_g4200 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4199 = ( ( temp_output_338_10_g4110 * normalizeResult8_g4200 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4199 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4202 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4199 - temp_output_10_0_g4110 ) - temp_output_10_0_g4199 ), float3(0,1,0), break61_g4202.y );
				float3 rotatedValue33_g4202 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4202, float3(1,0,0), break61_g4202.x );
				float3 rotatedValue28_g4202 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4202, float3(0,0,1), break61_g4202.z );
				float3 break36_g4202 = rotatedValue28_g4202;
				float2 appendResult27_g4202 = (float2(break36_g4202.x , break36_g4202.y));
				float4 tex2DNode7_g4202 = tex2D( _D_1, ( ( ( appendResult27_g4202 / _CameraF ) / break36_g4202.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4166 = ( ( temp_output_7_0_g4166 - temp_output_334_10_g4110 ) / 2 );
				float temp_output_8_0_g4166 = ( temp_output_7_0_g4166 + temp_output_2_0_g4166 );
				float temp_output_9_0_g4166 = ( temp_output_7_0_g4166 - temp_output_2_0_g4166 );
				float temp_output_7_0_g4164 = ( ( ( _DepthK / tex2DNode7_g4202.r ) + _DepthB ) >= distance( temp_output_10_0_g4199 , temp_output_24_0_g4199 ) ? ( temp_output_8_0_g4166 > temp_output_9_0_g4166 ? temp_output_8_0_g4166 : temp_output_9_0_g4166 ) : ( temp_output_8_0_g4166 > temp_output_9_0_g4166 ? temp_output_9_0_g4166 : temp_output_8_0_g4166 ) );
				float temp_output_336_10_g4110 = temp_output_7_0_g4164;
				float3 normalizeResult8_g4118 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4117 = ( ( temp_output_336_10_g4110 * normalizeResult8_g4118 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4117 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4120 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4117 - temp_output_10_0_g4110 ) - temp_output_10_0_g4117 ), float3(0,1,0), break61_g4120.y );
				float3 rotatedValue33_g4120 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4120, float3(1,0,0), break61_g4120.x );
				float3 rotatedValue28_g4120 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4120, float3(0,0,1), break61_g4120.z );
				float3 break36_g4120 = rotatedValue28_g4120;
				float2 appendResult27_g4120 = (float2(break36_g4120.x , break36_g4120.y));
				float4 tex2DNode7_g4120 = tex2D( _D_1, ( ( ( appendResult27_g4120 / _CameraF ) / break36_g4120.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4164 = ( ( temp_output_7_0_g4164 - temp_output_338_10_g4110 ) / 2 );
				float temp_output_8_0_g4164 = ( temp_output_7_0_g4164 + temp_output_2_0_g4164 );
				float temp_output_9_0_g4164 = ( temp_output_7_0_g4164 - temp_output_2_0_g4164 );
				float temp_output_7_0_g4140 = ( ( ( _DepthK / tex2DNode7_g4120.r ) + _DepthB ) >= distance( temp_output_10_0_g4117 , temp_output_24_0_g4117 ) ? ( temp_output_8_0_g4164 > temp_output_9_0_g4164 ? temp_output_8_0_g4164 : temp_output_9_0_g4164 ) : ( temp_output_8_0_g4164 > temp_output_9_0_g4164 ? temp_output_9_0_g4164 : temp_output_8_0_g4164 ) );
				float3 normalizeResult8_g4135 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4134 = ( ( temp_output_7_0_g4140 * normalizeResult8_g4135 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4134 = temp_output_9_0_g4110;
				float3 rotatedValue31_g4137 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4134 - temp_output_10_0_g4110 ) - temp_output_10_0_g4134 ), float3(0,1,0), break61_g4137.y );
				float3 rotatedValue33_g4137 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4137, float3(1,0,0), break61_g4137.x );
				float3 rotatedValue28_g4137 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4137, float3(0,0,1), break61_g4137.z );
				float3 break36_g4137 = rotatedValue28_g4137;
				float2 appendResult27_g4137 = (float2(break36_g4137.x , break36_g4137.y));
				float4 tex2DNode7_g4137 = tex2D( _D_1, ( ( ( appendResult27_g4137 / _CameraF ) / break36_g4137.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4140 = ( ( temp_output_7_0_g4140 - temp_output_336_10_g4110 ) / 2 );
				float temp_output_8_0_g4140 = ( temp_output_7_0_g4140 + temp_output_2_0_g4140 );
				float temp_output_9_0_g4140 = ( temp_output_7_0_g4140 - temp_output_2_0_g4140 );
				float temp_output_275_0_g4110 = ( ( ( _DepthK / tex2DNode7_g4137.r ) + _DepthB ) >= distance( temp_output_10_0_g4134 , temp_output_24_0_g4134 ) ? ( temp_output_8_0_g4140 > temp_output_9_0_g4140 ? temp_output_8_0_g4140 : temp_output_9_0_g4140 ) : ( temp_output_8_0_g4140 > temp_output_9_0_g4140 ? temp_output_9_0_g4140 : temp_output_8_0_g4140 ) );
				float temp_output_150_0 = temp_output_275_0_g4110;
				float3 temp_output_12_0_g4224 = _Camera2Rotation;
				float3 break61_g4251 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4234 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4316 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4326 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4246 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4263 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4310 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4331 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float3 break61_g4269 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_13_0_g4224 = temp_output_112_0;
				float temp_output_118_0_g4224 = ( 0.1 * temp_output_13_0_g4224 );
				float temp_output_12_0_g4282 = temp_output_118_0_g4224;
				float temp_output_138_10_g4224 = temp_output_12_0_g4282;
				float3 normalizeResult8_g4267 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4266 = ( ( temp_output_138_10_g4224 * normalizeResult8_g4267 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4224 = _PositionOffset;
				float3 temp_output_9_0_g4224 = _Camera2Position;
				float3 temp_output_10_0_g4266 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4269 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4266 - temp_output_10_0_g4224 ) - temp_output_10_0_g4266 ), float3(0,1,0), break61_g4269.y );
				float3 rotatedValue33_g4269 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4269, float3(1,0,0), break61_g4269.x );
				float3 rotatedValue28_g4269 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4269, float3(0,0,1), break61_g4269.z );
				float3 break36_g4269 = rotatedValue28_g4269;
				float2 appendResult27_g4269 = (float2(break36_g4269.x , break36_g4269.y));
				float4 tex2DNode7_g4269 = tex2D( _D_2, ( ( ( appendResult27_g4269 / _CameraF ) / break36_g4269.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4274 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4253 = ( temp_output_12_0_g4282 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_136_10_g4224 = temp_output_12_0_g4253;
				float3 normalizeResult8_g4272 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4271 = ( ( temp_output_136_10_g4224 * normalizeResult8_g4272 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4271 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4274 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4271 - temp_output_10_0_g4224 ) - temp_output_10_0_g4271 ), float3(0,1,0), break61_g4274.y );
				float3 rotatedValue33_g4274 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4274, float3(1,0,0), break61_g4274.x );
				float3 rotatedValue28_g4274 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4274, float3(0,0,1), break61_g4274.z );
				float3 break36_g4274 = rotatedValue28_g4274;
				float2 appendResult27_g4274 = (float2(break36_g4274.x , break36_g4274.y));
				float4 tex2DNode7_g4274 = tex2D( _D_2, ( ( ( appendResult27_g4274 / _CameraF ) / break36_g4274.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4298 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4265 = ( temp_output_12_0_g4253 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_137_10_g4224 = temp_output_12_0_g4265;
				float3 normalizeResult8_g4296 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4295 = ( ( temp_output_137_10_g4224 * normalizeResult8_g4296 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4295 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4298 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4295 - temp_output_10_0_g4224 ) - temp_output_10_0_g4295 ), float3(0,1,0), break61_g4298.y );
				float3 rotatedValue33_g4298 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4298, float3(1,0,0), break61_g4298.x );
				float3 rotatedValue28_g4298 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4298, float3(0,0,1), break61_g4298.z );
				float3 break36_g4298 = rotatedValue28_g4298;
				float2 appendResult27_g4298 = (float2(break36_g4298.x , break36_g4298.y));
				float4 tex2DNode7_g4298 = tex2D( _D_2, ( ( ( appendResult27_g4298 / _CameraF ) / break36_g4298.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4293 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4306 = ( temp_output_12_0_g4265 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_142_10_g4224 = temp_output_12_0_g4306;
				float3 normalizeResult8_g4291 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4290 = ( ( temp_output_142_10_g4224 * normalizeResult8_g4291 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4290 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4293 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4290 - temp_output_10_0_g4224 ) - temp_output_10_0_g4290 ), float3(0,1,0), break61_g4293.y );
				float3 rotatedValue33_g4293 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4293, float3(1,0,0), break61_g4293.x );
				float3 rotatedValue28_g4293 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4293, float3(0,0,1), break61_g4293.z );
				float3 break36_g4293 = rotatedValue28_g4293;
				float2 appendResult27_g4293 = (float2(break36_g4293.x , break36_g4293.y));
				float4 tex2DNode7_g4293 = tex2D( _D_2, ( ( ( appendResult27_g4293 / _CameraF ) / break36_g4293.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4228 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4312 = ( temp_output_12_0_g4306 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_144_10_g4224 = temp_output_12_0_g4312;
				float3 normalizeResult8_g4226 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4225 = ( ( temp_output_144_10_g4224 * normalizeResult8_g4226 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4225 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4228 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4225 - temp_output_10_0_g4224 ) - temp_output_10_0_g4225 ), float3(0,1,0), break61_g4228.y );
				float3 rotatedValue33_g4228 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4228, float3(1,0,0), break61_g4228.x );
				float3 rotatedValue28_g4228 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4228, float3(0,0,1), break61_g4228.z );
				float3 break36_g4228 = rotatedValue28_g4228;
				float2 appendResult27_g4228 = (float2(break36_g4228.x , break36_g4228.y));
				float4 tex2DNode7_g4228 = tex2D( _D_2, ( ( ( appendResult27_g4228 / _CameraF ) / break36_g4228.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4258 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4230 = ( temp_output_12_0_g4312 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_146_10_g4224 = temp_output_12_0_g4230;
				float3 normalizeResult8_g4256 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4255 = ( ( temp_output_146_10_g4224 * normalizeResult8_g4256 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4255 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4258 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4255 - temp_output_10_0_g4224 ) - temp_output_10_0_g4255 ), float3(0,1,0), break61_g4258.y );
				float3 rotatedValue33_g4258 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4258, float3(1,0,0), break61_g4258.x );
				float3 rotatedValue28_g4258 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4258, float3(0,0,1), break61_g4258.z );
				float3 break36_g4258 = rotatedValue28_g4258;
				float2 appendResult27_g4258 = (float2(break36_g4258.x , break36_g4258.y));
				float4 tex2DNode7_g4258 = tex2D( _D_2, ( ( ( appendResult27_g4258 / _CameraF ) / break36_g4258.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4239 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4288 = ( temp_output_12_0_g4230 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_148_10_g4224 = temp_output_12_0_g4288;
				float3 normalizeResult8_g4237 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4236 = ( ( temp_output_148_10_g4224 * normalizeResult8_g4237 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4236 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4239 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4236 - temp_output_10_0_g4224 ) - temp_output_10_0_g4236 ), float3(0,1,0), break61_g4239.y );
				float3 rotatedValue33_g4239 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4239, float3(1,0,0), break61_g4239.x );
				float3 rotatedValue28_g4239 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4239, float3(0,0,1), break61_g4239.z );
				float3 break36_g4239 = rotatedValue28_g4239;
				float2 appendResult27_g4239 = (float2(break36_g4239.x , break36_g4239.y));
				float4 tex2DNode7_g4239 = tex2D( _D_2, ( ( ( appendResult27_g4239 / _CameraF ) / break36_g4239.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4321 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4289 = ( temp_output_12_0_g4288 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_150_10_g4224 = temp_output_12_0_g4289;
				float3 normalizeResult8_g4319 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4318 = ( ( temp_output_150_10_g4224 * normalizeResult8_g4319 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4318 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4321 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4318 - temp_output_10_0_g4224 ) - temp_output_10_0_g4318 ), float3(0,1,0), break61_g4321.y );
				float3 rotatedValue33_g4321 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4321, float3(1,0,0), break61_g4321.x );
				float3 rotatedValue28_g4321 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4321, float3(0,0,1), break61_g4321.z );
				float3 break36_g4321 = rotatedValue28_g4321;
				float2 appendResult27_g4321 = (float2(break36_g4321.x , break36_g4321.y));
				float4 tex2DNode7_g4321 = tex2D( _D_2, ( ( ( appendResult27_g4321 / _CameraF ) / break36_g4321.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4336 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4241 = ( temp_output_12_0_g4289 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_152_10_g4224 = temp_output_12_0_g4241;
				float3 normalizeResult8_g4334 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4333 = ( ( temp_output_152_10_g4224 * normalizeResult8_g4334 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4333 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4336 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4333 - temp_output_10_0_g4224 ) - temp_output_10_0_g4333 ), float3(0,1,0), break61_g4336.y );
				float3 rotatedValue33_g4336 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4336, float3(1,0,0), break61_g4336.x );
				float3 rotatedValue28_g4336 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4336, float3(0,0,1), break61_g4336.z );
				float3 break36_g4336 = rotatedValue28_g4336;
				float2 appendResult27_g4336 = (float2(break36_g4336.x , break36_g4336.y));
				float4 tex2DNode7_g4336 = tex2D( _D_2, ( ( ( appendResult27_g4336 / _CameraF ) / break36_g4336.z ) + float2( 0.5,0.5 ) ) );
				float3 break61_g4303 = ( ( ( temp_output_12_0_g4224 * 3.141593 ) / 180 ) * -1 );
				float temp_output_12_0_g4242 = ( temp_output_12_0_g4241 + ( ( temp_output_13_0_g4224 - 0.0 ) * 0.1 ) );
				float temp_output_154_10_g4224 = temp_output_12_0_g4242;
				float3 normalizeResult8_g4301 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4300 = ( ( temp_output_154_10_g4224 * normalizeResult8_g4301 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4300 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4303 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4300 - temp_output_10_0_g4224 ) - temp_output_10_0_g4300 ), float3(0,1,0), break61_g4303.y );
				float3 rotatedValue33_g4303 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4303, float3(1,0,0), break61_g4303.x );
				float3 rotatedValue28_g4303 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4303, float3(0,0,1), break61_g4303.z );
				float3 break36_g4303 = rotatedValue28_g4303;
				float2 appendResult27_g4303 = (float2(break36_g4303.x , break36_g4303.y));
				float4 tex2DNode7_g4303 = tex2D( _D_2, ( ( ( appendResult27_g4303 / _CameraF ) / break36_g4303.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_281_0_g4224 = ( ( ( _DepthK / tex2DNode7_g4269.r ) + _DepthB ) >= distance( temp_output_10_0_g4266 , temp_output_24_0_g4266 ) ? ( ( ( _DepthK / tex2DNode7_g4274.r ) + _DepthB ) >= distance( temp_output_10_0_g4271 , temp_output_24_0_g4271 ) ? ( ( ( _DepthK / tex2DNode7_g4298.r ) + _DepthB ) >= distance( temp_output_10_0_g4295 , temp_output_24_0_g4295 ) ? ( ( ( _DepthK / tex2DNode7_g4293.r ) + _DepthB ) >= distance( temp_output_10_0_g4290 , temp_output_24_0_g4290 ) ? ( ( ( _DepthK / tex2DNode7_g4228.r ) + _DepthB ) >= distance( temp_output_10_0_g4225 , temp_output_24_0_g4225 ) ? ( ( ( _DepthK / tex2DNode7_g4258.r ) + _DepthB ) >= distance( temp_output_10_0_g4255 , temp_output_24_0_g4255 ) ? ( ( ( _DepthK / tex2DNode7_g4239.r ) + _DepthB ) >= distance( temp_output_10_0_g4236 , temp_output_24_0_g4236 ) ? ( ( ( _DepthK / tex2DNode7_g4321.r ) + _DepthB ) >= distance( temp_output_10_0_g4318 , temp_output_24_0_g4318 ) ? ( ( ( _DepthK / tex2DNode7_g4336.r ) + _DepthB ) >= distance( temp_output_10_0_g4333 , temp_output_24_0_g4333 ) ? ( ( ( _DepthK / tex2DNode7_g4303.r ) + _DepthB ) >= distance( temp_output_10_0_g4300 , temp_output_24_0_g4300 ) ? 100.0 : temp_output_154_10_g4224 ) : temp_output_152_10_g4224 ) : temp_output_150_10_g4224 ) : temp_output_148_10_g4224 ) : temp_output_146_10_g4224 ) : temp_output_144_10_g4224 ) : temp_output_142_10_g4224 ) : temp_output_137_10_g4224 ) : temp_output_136_10_g4224 ) : temp_output_138_10_g4224 );
				float temp_output_284_0_g4224 = ( temp_output_281_0_g4224 - temp_output_118_0_g4224 );
				float temp_output_286_0_g4224 = ( ( ( ( temp_output_281_0_g4224 - 0.0 ) + temp_output_284_0_g4224 ) / 2 ) + 0.0 );
				float temp_output_7_0_g4279 = temp_output_286_0_g4224;
				float temp_output_337_10_g4224 = temp_output_7_0_g4279;
				float3 normalizeResult8_g4329 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4328 = ( ( temp_output_337_10_g4224 * normalizeResult8_g4329 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4328 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4331 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4328 - temp_output_10_0_g4224 ) - temp_output_10_0_g4328 ), float3(0,1,0), break61_g4331.y );
				float3 rotatedValue33_g4331 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4331, float3(1,0,0), break61_g4331.x );
				float3 rotatedValue28_g4331 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4331, float3(0,0,1), break61_g4331.z );
				float3 break36_g4331 = rotatedValue28_g4331;
				float2 appendResult27_g4331 = (float2(break36_g4331.x , break36_g4331.y));
				float4 tex2DNode7_g4331 = tex2D( _D_2, ( ( ( appendResult27_g4331 / _CameraF ) / break36_g4331.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4279 = ( ( temp_output_7_0_g4279 - ( temp_output_284_0_g4224 + 0.0 ) ) / 2 );
				float temp_output_8_0_g4279 = ( temp_output_7_0_g4279 + temp_output_2_0_g4279 );
				float temp_output_9_0_g4279 = ( temp_output_7_0_g4279 - temp_output_2_0_g4279 );
				float temp_output_266_0_g4224 = ( ( ( _DepthK / tex2DNode7_g4331.r ) + _DepthB ) >= distance( temp_output_10_0_g4328 , temp_output_24_0_g4328 ) ? ( temp_output_8_0_g4279 > temp_output_9_0_g4279 ? temp_output_8_0_g4279 : temp_output_9_0_g4279 ) : ( temp_output_8_0_g4279 > temp_output_9_0_g4279 ? temp_output_9_0_g4279 : temp_output_8_0_g4279 ) );
				float temp_output_7_0_g4305 = temp_output_266_0_g4224;
				float temp_output_341_10_g4224 = temp_output_7_0_g4305;
				float3 normalizeResult8_g4308 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4307 = ( ( temp_output_341_10_g4224 * normalizeResult8_g4308 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4307 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4310 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4307 - temp_output_10_0_g4224 ) - temp_output_10_0_g4307 ), float3(0,1,0), break61_g4310.y );
				float3 rotatedValue33_g4310 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4310, float3(1,0,0), break61_g4310.x );
				float3 rotatedValue28_g4310 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4310, float3(0,0,1), break61_g4310.z );
				float3 break36_g4310 = rotatedValue28_g4310;
				float2 appendResult27_g4310 = (float2(break36_g4310.x , break36_g4310.y));
				float4 tex2DNode7_g4310 = tex2D( _D_2, ( ( ( appendResult27_g4310 / _CameraF ) / break36_g4310.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4305 = ( ( temp_output_7_0_g4305 - temp_output_337_10_g4224 ) / 2 );
				float temp_output_8_0_g4305 = ( temp_output_7_0_g4305 + temp_output_2_0_g4305 );
				float temp_output_9_0_g4305 = ( temp_output_7_0_g4305 - temp_output_2_0_g4305 );
				float temp_output_276_0_g4224 = ( ( ( _DepthK / tex2DNode7_g4310.r ) + _DepthB ) >= distance( temp_output_10_0_g4307 , temp_output_24_0_g4307 ) ? ( temp_output_8_0_g4305 > temp_output_9_0_g4305 ? temp_output_8_0_g4305 : temp_output_9_0_g4305 ) : ( temp_output_8_0_g4305 > temp_output_9_0_g4305 ? temp_output_9_0_g4305 : temp_output_8_0_g4305 ) );
				float temp_output_7_0_g4277 = temp_output_276_0_g4224;
				float temp_output_335_10_g4224 = temp_output_7_0_g4277;
				float3 normalizeResult8_g4261 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4260 = ( ( temp_output_335_10_g4224 * normalizeResult8_g4261 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4260 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4263 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4260 - temp_output_10_0_g4224 ) - temp_output_10_0_g4260 ), float3(0,1,0), break61_g4263.y );
				float3 rotatedValue33_g4263 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4263, float3(1,0,0), break61_g4263.x );
				float3 rotatedValue28_g4263 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4263, float3(0,0,1), break61_g4263.z );
				float3 break36_g4263 = rotatedValue28_g4263;
				float2 appendResult27_g4263 = (float2(break36_g4263.x , break36_g4263.y));
				float4 tex2DNode7_g4263 = tex2D( _D_2, ( ( ( appendResult27_g4263 / _CameraF ) / break36_g4263.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4277 = ( ( temp_output_7_0_g4277 - temp_output_341_10_g4224 ) / 2 );
				float temp_output_8_0_g4277 = ( temp_output_7_0_g4277 + temp_output_2_0_g4277 );
				float temp_output_9_0_g4277 = ( temp_output_7_0_g4277 - temp_output_2_0_g4277 );
				float temp_output_282_0_g4224 = ( ( ( _DepthK / tex2DNode7_g4263.r ) + _DepthB ) >= distance( temp_output_10_0_g4260 , temp_output_24_0_g4260 ) ? ( temp_output_8_0_g4277 > temp_output_9_0_g4277 ? temp_output_8_0_g4277 : temp_output_9_0_g4277 ) : ( temp_output_8_0_g4277 > temp_output_9_0_g4277 ? temp_output_9_0_g4277 : temp_output_8_0_g4277 ) );
				float temp_output_7_0_g4281 = temp_output_282_0_g4224;
				float temp_output_339_10_g4224 = temp_output_7_0_g4281;
				float3 normalizeResult8_g4244 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4243 = ( ( temp_output_339_10_g4224 * normalizeResult8_g4244 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4243 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4246 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4243 - temp_output_10_0_g4224 ) - temp_output_10_0_g4243 ), float3(0,1,0), break61_g4246.y );
				float3 rotatedValue33_g4246 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4246, float3(1,0,0), break61_g4246.x );
				float3 rotatedValue28_g4246 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4246, float3(0,0,1), break61_g4246.z );
				float3 break36_g4246 = rotatedValue28_g4246;
				float2 appendResult27_g4246 = (float2(break36_g4246.x , break36_g4246.y));
				float4 tex2DNode7_g4246 = tex2D( _D_2, ( ( ( appendResult27_g4246 / _CameraF ) / break36_g4246.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4281 = ( ( temp_output_7_0_g4281 - temp_output_335_10_g4224 ) / 2 );
				float temp_output_8_0_g4281 = ( temp_output_7_0_g4281 + temp_output_2_0_g4281 );
				float temp_output_9_0_g4281 = ( temp_output_7_0_g4281 - temp_output_2_0_g4281 );
				float temp_output_7_0_g4276 = ( ( ( _DepthK / tex2DNode7_g4246.r ) + _DepthB ) >= distance( temp_output_10_0_g4243 , temp_output_24_0_g4243 ) ? ( temp_output_8_0_g4281 > temp_output_9_0_g4281 ? temp_output_8_0_g4281 : temp_output_9_0_g4281 ) : ( temp_output_8_0_g4281 > temp_output_9_0_g4281 ? temp_output_9_0_g4281 : temp_output_8_0_g4281 ) );
				float temp_output_334_10_g4224 = temp_output_7_0_g4276;
				float3 normalizeResult8_g4324 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4323 = ( ( temp_output_334_10_g4224 * normalizeResult8_g4324 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4323 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4326 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4323 - temp_output_10_0_g4224 ) - temp_output_10_0_g4323 ), float3(0,1,0), break61_g4326.y );
				float3 rotatedValue33_g4326 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4326, float3(1,0,0), break61_g4326.x );
				float3 rotatedValue28_g4326 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4326, float3(0,0,1), break61_g4326.z );
				float3 break36_g4326 = rotatedValue28_g4326;
				float2 appendResult27_g4326 = (float2(break36_g4326.x , break36_g4326.y));
				float4 tex2DNode7_g4326 = tex2D( _D_2, ( ( ( appendResult27_g4326 / _CameraF ) / break36_g4326.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4276 = ( ( temp_output_7_0_g4276 - temp_output_339_10_g4224 ) / 2 );
				float temp_output_8_0_g4276 = ( temp_output_7_0_g4276 + temp_output_2_0_g4276 );
				float temp_output_9_0_g4276 = ( temp_output_7_0_g4276 - temp_output_2_0_g4276 );
				float temp_output_7_0_g4280 = ( ( ( _DepthK / tex2DNode7_g4326.r ) + _DepthB ) >= distance( temp_output_10_0_g4323 , temp_output_24_0_g4323 ) ? ( temp_output_8_0_g4276 > temp_output_9_0_g4276 ? temp_output_8_0_g4276 : temp_output_9_0_g4276 ) : ( temp_output_8_0_g4276 > temp_output_9_0_g4276 ? temp_output_9_0_g4276 : temp_output_8_0_g4276 ) );
				float temp_output_338_10_g4224 = temp_output_7_0_g4280;
				float3 normalizeResult8_g4314 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4313 = ( ( temp_output_338_10_g4224 * normalizeResult8_g4314 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4313 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4316 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4313 - temp_output_10_0_g4224 ) - temp_output_10_0_g4313 ), float3(0,1,0), break61_g4316.y );
				float3 rotatedValue33_g4316 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4316, float3(1,0,0), break61_g4316.x );
				float3 rotatedValue28_g4316 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4316, float3(0,0,1), break61_g4316.z );
				float3 break36_g4316 = rotatedValue28_g4316;
				float2 appendResult27_g4316 = (float2(break36_g4316.x , break36_g4316.y));
				float4 tex2DNode7_g4316 = tex2D( _D_2, ( ( ( appendResult27_g4316 / _CameraF ) / break36_g4316.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4280 = ( ( temp_output_7_0_g4280 - temp_output_334_10_g4224 ) / 2 );
				float temp_output_8_0_g4280 = ( temp_output_7_0_g4280 + temp_output_2_0_g4280 );
				float temp_output_9_0_g4280 = ( temp_output_7_0_g4280 - temp_output_2_0_g4280 );
				float temp_output_7_0_g4278 = ( ( ( _DepthK / tex2DNode7_g4316.r ) + _DepthB ) >= distance( temp_output_10_0_g4313 , temp_output_24_0_g4313 ) ? ( temp_output_8_0_g4280 > temp_output_9_0_g4280 ? temp_output_8_0_g4280 : temp_output_9_0_g4280 ) : ( temp_output_8_0_g4280 > temp_output_9_0_g4280 ? temp_output_9_0_g4280 : temp_output_8_0_g4280 ) );
				float temp_output_336_10_g4224 = temp_output_7_0_g4278;
				float3 normalizeResult8_g4232 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4231 = ( ( temp_output_336_10_g4224 * normalizeResult8_g4232 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4231 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4234 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4231 - temp_output_10_0_g4224 ) - temp_output_10_0_g4231 ), float3(0,1,0), break61_g4234.y );
				float3 rotatedValue33_g4234 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4234, float3(1,0,0), break61_g4234.x );
				float3 rotatedValue28_g4234 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4234, float3(0,0,1), break61_g4234.z );
				float3 break36_g4234 = rotatedValue28_g4234;
				float2 appendResult27_g4234 = (float2(break36_g4234.x , break36_g4234.y));
				float4 tex2DNode7_g4234 = tex2D( _D_2, ( ( ( appendResult27_g4234 / _CameraF ) / break36_g4234.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4278 = ( ( temp_output_7_0_g4278 - temp_output_338_10_g4224 ) / 2 );
				float temp_output_8_0_g4278 = ( temp_output_7_0_g4278 + temp_output_2_0_g4278 );
				float temp_output_9_0_g4278 = ( temp_output_7_0_g4278 - temp_output_2_0_g4278 );
				float temp_output_7_0_g4254 = ( ( ( _DepthK / tex2DNode7_g4234.r ) + _DepthB ) >= distance( temp_output_10_0_g4231 , temp_output_24_0_g4231 ) ? ( temp_output_8_0_g4278 > temp_output_9_0_g4278 ? temp_output_8_0_g4278 : temp_output_9_0_g4278 ) : ( temp_output_8_0_g4278 > temp_output_9_0_g4278 ? temp_output_9_0_g4278 : temp_output_8_0_g4278 ) );
				float3 normalizeResult8_g4249 = normalize( ( WorldPosition - _WorldSpaceCameraPos ) );
				float3 temp_output_24_0_g4248 = ( ( temp_output_7_0_g4254 * normalizeResult8_g4249 ) + _WorldSpaceCameraPos );
				float3 temp_output_10_0_g4248 = temp_output_9_0_g4224;
				float3 rotatedValue31_g4251 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_24_0_g4248 - temp_output_10_0_g4224 ) - temp_output_10_0_g4248 ), float3(0,1,0), break61_g4251.y );
				float3 rotatedValue33_g4251 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue31_g4251, float3(1,0,0), break61_g4251.x );
				float3 rotatedValue28_g4251 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue33_g4251, float3(0,0,1), break61_g4251.z );
				float3 break36_g4251 = rotatedValue28_g4251;
				float2 appendResult27_g4251 = (float2(break36_g4251.x , break36_g4251.y));
				float4 tex2DNode7_g4251 = tex2D( _D_2, ( ( ( appendResult27_g4251 / _CameraF ) / break36_g4251.z ) + float2( 0.5,0.5 ) ) );
				float temp_output_2_0_g4254 = ( ( temp_output_7_0_g4254 - temp_output_336_10_g4224 ) / 2 );
				float temp_output_8_0_g4254 = ( temp_output_7_0_g4254 + temp_output_2_0_g4254 );
				float temp_output_9_0_g4254 = ( temp_output_7_0_g4254 - temp_output_2_0_g4254 );
				float temp_output_275_0_g4224 = ( ( ( _DepthK / tex2DNode7_g4251.r ) + _DepthB ) >= distance( temp_output_10_0_g4248 , temp_output_24_0_g4248 ) ? ( temp_output_8_0_g4254 > temp_output_9_0_g4254 ? temp_output_8_0_g4254 : temp_output_9_0_g4254 ) : ( temp_output_8_0_g4254 > temp_output_9_0_g4254 ? temp_output_9_0_g4254 : temp_output_8_0_g4254 ) );
				float temp_output_151_0 = temp_output_275_0_g4224;
				float3 temp_cast_0 = (( ( max( temp_output_150_0 , temp_output_151_0 ) - 0.7 ) / ( temp_output_112_0 - 0.7 ) )).xxx;
				
				float2 uv_RGB_2 = IN.ase_texcoord3.xy * _RGB_2_ST.xy + _RGB_2_ST.zw;
				float2 uv_RGB_1 = IN.ase_texcoord3.xy * _RGB_1_ST.xy + _RGB_1_ST.zw;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = temp_cast_0;
				float Alpha = ( float4( 0,0,0,0 ) * tex2D( _RGB_2, uv_RGB_2 ) * tex2D( _RGB_1, uv_RGB_1 ) ).r;
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
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _RGB_2_ST;
			float4 _RGB_1_ST;
			float3 _Camera1Rotation;
			float3 _PositionOffset;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _DepthK;
			float _MaxDepthDelta;
			float _CameraF;
			float _DepthB;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _RGB_2;
			sampler2D _RGB_1;


			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
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
				float4 ase_texcoord : TEXCOORD0;

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
				o.ase_texcoord = v.ase_texcoord;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
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

				float2 uv_RGB_2 = IN.ase_texcoord2.xy * _RGB_2_ST.xy + _RGB_2_ST.zw;
				float2 uv_RGB_1 = IN.ase_texcoord2.xy * _RGB_1_ST.xy + _RGB_1_ST.zw;
				
				float Alpha = ( float4( 0,0,0,0 ) * tex2D( _RGB_2, uv_RGB_2 ) * tex2D( _RGB_1, uv_RGB_1 ) ).r;
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
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _RGB_2_ST;
			float4 _RGB_1_ST;
			float3 _Camera1Rotation;
			float3 _PositionOffset;
			float3 _Camera1Position;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float _DepthK;
			float _MaxDepthDelta;
			float _CameraF;
			float _DepthB;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _RGB_2;
			sampler2D _RGB_1;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
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
				float4 ase_texcoord : TEXCOORD0;

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
				o.ase_texcoord = v.ase_texcoord;
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
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
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

				float2 uv_RGB_2 = IN.ase_texcoord2.xy * _RGB_2_ST.xy + _RGB_2_ST.zw;
				float2 uv_RGB_1 = IN.ase_texcoord2.xy * _RGB_1_ST.xy + _RGB_1_ST.zw;
				
				float Alpha = ( float4( 0,0,0,0 ) * tex2D( _RGB_2, uv_RGB_2 ) * tex2D( _RGB_1, uv_RGB_1 ) ).r;
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
-196;-1027;1920;1006;2084.478;1883.885;2.516668;False;False
Node;AmplifyShaderEditor.TexturePropertyNode;8;-1171.978,156.1476;Inherit;True;Property;_RGB_2;RGB_2;190;0;Create;True;0;0;0;False;0;False;3d7039e2d91fd44f68f4f05c291fb0a7;3d7039e2d91fd44f68f4f05c291fb0a7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;5;-1216.744,-956.5697;Inherit;True;Property;_RGB_1;RGB_1;0;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;6e525e0933ba04ebe9d0f3860234333d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;7;-905.4182,156.1476;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-950.1835,-956.5697;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;11;-896.2289,372.7456;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;27;-2199.773,-433.9232;Inherit;False;Property;_PositionOffset;PositionOffset;197;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;150;-617.7129,-1675.456;Inherit;False;IterativelyGetDepth;1;;4110;737fc4a0ba92542e0a72347a837a8648;0;5;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;93;1540.479,-392.8936;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;117;1333.026,-329.5901;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;116;1120.203,-367.8223;Inherit;False;Constant;_Float0;Float 0;50;0;Create;True;0;0;0;False;0;False;0.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;9;-953.6662,-748.0662;Inherit;True;Property;_TextureSample2;Texture Sample 2;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;30;-1178.169,-1538.857;Inherit;False;Property;_Camera1Rotation;Camera 1 Rotation;195;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;26;-507.2855,-659.1292;Inherit;False;F256ToDepth;-1;;2;4f92d4ca3c22c4e8f94594a5c13266ba;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;115;1314.811,-462.7235;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;153;272.2153,-496.4482;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;31;-1175.32,-1381.268;Inherit;False;Property;_Camera1Position;Camera 1 Position;194;0;Create;True;0;0;0;False;0;False;0,0,0;-0.057,1.63,-0.829;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;10;-1220.226,-748.0662;Inherit;True;Property;_D_1;D_1;191;0;Create;True;0;0;0;False;0;False;0146383e3995643be92047c1c3fd405d;0146383e3995643be92047c1c3fd405d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleSubtractOpNode;107;-1395.135,-154.0809;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;29;-1203.041,860.6336;Inherit;False;Property;_Camera2Position;Camera 2 Position;193;0;Create;True;0;0;0;False;0;False;0,0,0;0.949,1.884,-0.689;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-478.0756,-439.5494;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-1052.89,-297.0006;Inherit;False;Property;_MaxDepthDelta;MaxDepthDelta;176;0;Create;True;0;0;0;False;0;False;4;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;104;-1741.135,-280.0809;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;110;-1128.907,-165.4125;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;112;-852.9073,-235.4125;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;111;-1006.907,-169.4125;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;74;-367.9774,-1775.448;Inherit;False;CamDepthToWorldPosition;-1;;333;a9d725c4349ce4106bfa1039b7647c13;0;1;9;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;28;-1213.134,653.7977;Inherit;False;Property;_Camera2Rotation;Camera 2 Rotation;196;0;Create;True;0;0;0;False;0;False;0,0,0;11.33,312.3629,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;151;-657.749,779.4965;Inherit;False;IterativelyGetDepth;1;;4224;737fc4a0ba92542e0a72347a837a8648;0;5;13;FLOAT;4;False;10;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;9;FLOAT3;0,0,0;False;11;SAMPLER2D;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;155;-375.416,780.5508;Inherit;False;CamDepthToWorldPosition;-1;;4339;a9d725c4349ce4106bfa1039b7647c13;0;1;9;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;154;-4.263719,209.838;Inherit;False;SingleCameraMapping;177;;4338;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;108;-1251.907,-162.4125;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.FunctionNode;63;-84.55149,-1454.441;Inherit;False;SingleCameraMapping;177;;94;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1162.789,372.7456;Inherit;True;Property;_D_2;D_2;192;0;Create;True;0;0;0;False;0;False;008ecc74e3a374dc7b0378989802d355;008ecc74e3a374dc7b0378989802d355;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1616.546,38.01801;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;NovelView;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
WireConnection;7;0;8;0
WireConnection;6;0;5;0
WireConnection;11;0;12;0
WireConnection;150;13;112;0
WireConnection;150;10;27;0
WireConnection;150;12;30;0
WireConnection;150;9;31;0
WireConnection;150;11;10;0
WireConnection;93;0;115;0
WireConnection;93;1;117;0
WireConnection;117;0;112;0
WireConnection;117;1;116;0
WireConnection;9;0;10;0
WireConnection;26;1;9;1
WireConnection;115;0;153;0
WireConnection;115;1;116;0
WireConnection;153;0;150;0
WireConnection;153;1;151;0
WireConnection;107;0;104;0
WireConnection;107;1;27;0
WireConnection;157;1;7;0
WireConnection;157;2;6;0
WireConnection;110;0;108;0
WireConnection;110;1;108;2
WireConnection;112;0;44;0
WireConnection;112;1;111;0
WireConnection;111;0;110;0
WireConnection;74;9;150;0
WireConnection;151;13;112;0
WireConnection;151;10;27;0
WireConnection;151;12;28;0
WireConnection;151;9;29;0
WireConnection;151;11;12;0
WireConnection;155;9;151;0
WireConnection;154;55;8;0
WireConnection;154;79;12;0
WireConnection;154;56;155;0
WireConnection;154;57;27;0
WireConnection;154;60;28;0
WireConnection;154;61;29;0
WireConnection;108;0;107;0
WireConnection;63;55;5;0
WireConnection;63;79;10;0
WireConnection;63;56;74;0
WireConnection;63;57;27;0
WireConnection;63;60;30;0
WireConnection;63;61;31;0
WireConnection;1;2;93;0
WireConnection;1;3;157;0
ASEEND*/
//CHKSM=AADF5B499286C6920D457DB8E9E01E7F0DDFE6D8