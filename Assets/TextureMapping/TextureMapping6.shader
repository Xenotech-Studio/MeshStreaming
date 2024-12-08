// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TextureMapping6"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_Viewport1("Viewport 1", 2D) = "white" {}
		_CameraF("Camera F", Range( 1 , 2)) = 1.1543
		_NormalCoeff("Normal Coeff", Range( 0 , 5)) = 1.5
		_DepthK("Depth K", Float) = 0.2966
		_DepthB("Depth B", Float) = 0.022267
		_OcculusionTolerance("Occulusion Tolerance", Range( 0.05 , 0.3)) = 0.05
		[Toggle]_DropOcculusion("Drop Occulusion", Float) = 1
		_Viewport2("Viewport 2", 2D) = "white" {}
		_Viewport3("Viewport 3", 2D) = "white" {}
		_Viewport4("Viewport 4", 2D) = "white" {}
		_Viewport5("Viewport 5", 2D) = "white" {}
		_Viewport6("Viewport 6", 2D) = "white" {}
		_Camera5Position("Camera 5 Position", Vector) = (0,0,0,0)
		_Camera4Position("Camera 4 Position", Vector) = (0,0,0,0)
		_Camera3Position("Camera 3 Position", Vector) = (0,0,0,0)
		_Camera2Position("Camera 2 Position", Vector) = (0,0,0,0)
		_Camera6Position("Camera 6 Position", Vector) = (0,0,0,0)
		_Camera1Position("Camera 1 Position", Vector) = (0,0,0,0)
		_Camera3Rotation("Camera 3 Rotation", Vector) = (0,0,0,0)
		_Camera1Rotation("Camera 1 Rotation", Vector) = (0,0,0,0)
		_Camera4Rotation("Camera 4 Rotation", Vector) = (0,0,0,0)
		_Camera5Rotation("Camera 5 Rotation", Vector) = (0,0,0,0)
		_Camera6Rotation("Camera 6 Rotation", Vector) = (0,0,0,0)
		_Camera2Rotation("Camera 2 Rotation", Vector) = (0,0,0,0)
		_PositionOffset("PositionOffset", Vector) = (0,0,0,0)
		[Toggle]_EnableCam5("Enable Cam 5", Float) = 1
		[Toggle]_EnableCam1("Enable Cam 1", Float) = 1
		[Toggle]_EnableCam2("Enable Cam 2", Float) = 1
		[Toggle]_EnableCam3("Enable Cam 3", Float) = 1
		[Toggle]_EnableCam4("Enable Cam 4", Float) = 1
		[Toggle]_EnableCam6("Enable Cam 6", Float) = 1
		_EmptyWeight("EmptyWeight", Range( 0 , 1)) = 0.01
		_EmptyColor("EmptyColor", Color) = (0.6226415,0.6226415,0.6226415,0)
		_Depth1("Depth 1", 2D) = "white" {}
		_Depth2("Depth 2", 2D) = "white" {}
		_Depth3("Depth 3", 2D) = "white" {}
		_Depth4("Depth 4", 2D) = "white" {}
		_Depth5("Depth 5", 2D) = "white" {}
		[ASEEnd]_Depth6("Depth 6", 2D) = "white" {}

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
			#define ASE_NEEDS_VERT_NORMAL


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
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _EmptyColor;
			float3 _Camera6Rotation;
			float3 _Camera6Position;
			float3 _Camera5Rotation;
			float3 _Camera5Position;
			float3 _Camera4Rotation;
			float3 _Camera4Position;
			float3 _Camera3Rotation;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float3 _Camera3Position;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _PositionOffset;
			float _NormalCoeff;
			float _EnableCam2;
			float _EmptyWeight;
			float _OcculusionTolerance;
			float _EnableCam3;
			float _DropOcculusion;
			float _DepthB;
			float _EnableCam4;
			float _CameraF;
			float _EnableCam5;
			float _DepthK;
			float _EnableCam6;
			float _EnableCam1;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _Depth1;
			sampler2D _Viewport1;
			sampler2D _Depth2;
			sampler2D _Viewport2;
			sampler2D _Depth3;
			sampler2D _Viewport3;
			sampler2D _Depth4;
			sampler2D _Viewport4;
			sampler2D _Depth5;
			sampler2D _Viewport5;
			sampler2D _Depth6;
			sampler2D _Viewport6;


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

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
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
				float3 temp_output_56_0_g60 = WorldPosition;
				float3 temp_output_57_0_g60 = _PositionOffset;
				float3 temp_output_61_0_g60 = _Camera1Position;
				float3 temp_output_53_0_g60 = ( ( temp_output_56_0_g60 - temp_output_57_0_g60 ) - temp_output_61_0_g60 );
				float3 break35_g61 = ( ( ( _Camera1Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g61 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g60 - temp_output_57_0_g60 ) - temp_output_61_0_g60 ), float3(0,1,0), break35_g61.y );
				float3 rotatedValue39_g61 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g61, float3(1,0,0), break35_g61.x );
				float3 rotatedValue33_g61 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g61, float3(0,0,1), break35_g61.z );
				float3 break44_g61 = rotatedValue33_g61;
				float2 appendResult31_g61 = (float2(break44_g61.x , break44_g61.y));
				float2 temp_output_160_0_g60 = ( ( ( appendResult31_g61 / _CameraF ) / break44_g61.z ) + float2( 0.5,0.5 ) );
				float3 ase_worldNormal = IN.ase_texcoord3.xyz;
				float3 normalizeResult20_g60 = normalize( temp_output_53_0_g60 );
				float dotResult71_g60 = dot( ase_worldNormal , ( -1 * normalizeResult20_g60 ) );
				float clampResult99_g60 = clamp( dotResult71_g60 , 0.0 , 1.0 );
				float clampResult111_g60 = clamp( pow( clampResult99_g60 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_722_62 = ( abs( ( length( temp_output_53_0_g60 ) - ( ( _DepthK / tex2D( _Depth1, temp_output_160_0_g60 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g60 : 0.0 );
				float4 temp_output_722_0 = tex2D( _Viewport1, temp_output_160_0_g60 );
				float3 temp_output_56_0_g54 = WorldPosition;
				float3 temp_output_57_0_g54 = _PositionOffset;
				float3 temp_output_61_0_g54 = _Camera2Position;
				float3 temp_output_53_0_g54 = ( ( temp_output_56_0_g54 - temp_output_57_0_g54 ) - temp_output_61_0_g54 );
				float3 break35_g55 = ( ( ( _Camera2Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g55 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g54 - temp_output_57_0_g54 ) - temp_output_61_0_g54 ), float3(0,1,0), break35_g55.y );
				float3 rotatedValue39_g55 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g55, float3(1,0,0), break35_g55.x );
				float3 rotatedValue33_g55 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g55, float3(0,0,1), break35_g55.z );
				float3 break44_g55 = rotatedValue33_g55;
				float2 appendResult31_g55 = (float2(break44_g55.x , break44_g55.y));
				float2 temp_output_160_0_g54 = ( ( ( appendResult31_g55 / _CameraF ) / break44_g55.z ) + float2( 0.5,0.5 ) );
				float3 normalizeResult20_g54 = normalize( temp_output_53_0_g54 );
				float dotResult71_g54 = dot( ase_worldNormal , ( -1 * normalizeResult20_g54 ) );
				float clampResult99_g54 = clamp( dotResult71_g54 , 0.0 , 1.0 );
				float clampResult111_g54 = clamp( pow( clampResult99_g54 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_719_62 = ( abs( ( length( temp_output_53_0_g54 ) - ( ( _DepthK / tex2D( _Depth2, temp_output_160_0_g54 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g54 : 0.0 );
				float3 temp_output_56_0_g58 = WorldPosition;
				float3 temp_output_57_0_g58 = _PositionOffset;
				float3 temp_output_61_0_g58 = _Camera3Position;
				float3 temp_output_53_0_g58 = ( ( temp_output_56_0_g58 - temp_output_57_0_g58 ) - temp_output_61_0_g58 );
				float3 break35_g59 = ( ( ( _Camera3Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g59 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g58 - temp_output_57_0_g58 ) - temp_output_61_0_g58 ), float3(0,1,0), break35_g59.y );
				float3 rotatedValue39_g59 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g59, float3(1,0,0), break35_g59.x );
				float3 rotatedValue33_g59 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g59, float3(0,0,1), break35_g59.z );
				float3 break44_g59 = rotatedValue33_g59;
				float2 appendResult31_g59 = (float2(break44_g59.x , break44_g59.y));
				float2 temp_output_160_0_g58 = ( ( ( appendResult31_g59 / _CameraF ) / break44_g59.z ) + float2( 0.5,0.5 ) );
				float3 normalizeResult20_g58 = normalize( temp_output_53_0_g58 );
				float dotResult71_g58 = dot( ase_worldNormal , ( -1 * normalizeResult20_g58 ) );
				float clampResult99_g58 = clamp( dotResult71_g58 , 0.0 , 1.0 );
				float clampResult111_g58 = clamp( pow( clampResult99_g58 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_721_62 = ( abs( ( length( temp_output_53_0_g58 ) - ( ( _DepthK / tex2D( _Depth3, temp_output_160_0_g58 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g58 : 0.0 );
				float3 temp_output_56_0_g56 = WorldPosition;
				float3 temp_output_57_0_g56 = _PositionOffset;
				float3 temp_output_61_0_g56 = _Camera4Position;
				float3 temp_output_53_0_g56 = ( ( temp_output_56_0_g56 - temp_output_57_0_g56 ) - temp_output_61_0_g56 );
				float3 break35_g57 = ( ( ( _Camera4Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g57 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g56 - temp_output_57_0_g56 ) - temp_output_61_0_g56 ), float3(0,1,0), break35_g57.y );
				float3 rotatedValue39_g57 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g57, float3(1,0,0), break35_g57.x );
				float3 rotatedValue33_g57 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g57, float3(0,0,1), break35_g57.z );
				float3 break44_g57 = rotatedValue33_g57;
				float2 appendResult31_g57 = (float2(break44_g57.x , break44_g57.y));
				float2 temp_output_160_0_g56 = ( ( ( appendResult31_g57 / _CameraF ) / break44_g57.z ) + float2( 0.5,0.5 ) );
				float3 normalizeResult20_g56 = normalize( temp_output_53_0_g56 );
				float dotResult71_g56 = dot( ase_worldNormal , ( -1 * normalizeResult20_g56 ) );
				float clampResult99_g56 = clamp( dotResult71_g56 , 0.0 , 1.0 );
				float clampResult111_g56 = clamp( pow( clampResult99_g56 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_720_62 = ( abs( ( length( temp_output_53_0_g56 ) - ( ( _DepthK / tex2D( _Depth4, temp_output_160_0_g56 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g56 : 0.0 );
				float3 temp_output_56_0_g50 = WorldPosition;
				float3 temp_output_57_0_g50 = _PositionOffset;
				float3 temp_output_61_0_g50 = _Camera5Position;
				float3 temp_output_53_0_g50 = ( ( temp_output_56_0_g50 - temp_output_57_0_g50 ) - temp_output_61_0_g50 );
				float3 break35_g51 = ( ( ( _Camera5Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g51 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g50 - temp_output_57_0_g50 ) - temp_output_61_0_g50 ), float3(0,1,0), break35_g51.y );
				float3 rotatedValue39_g51 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g51, float3(1,0,0), break35_g51.x );
				float3 rotatedValue33_g51 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g51, float3(0,0,1), break35_g51.z );
				float3 break44_g51 = rotatedValue33_g51;
				float2 appendResult31_g51 = (float2(break44_g51.x , break44_g51.y));
				float2 temp_output_160_0_g50 = ( ( ( appendResult31_g51 / _CameraF ) / break44_g51.z ) + float2( 0.5,0.5 ) );
				float3 normalizeResult20_g50 = normalize( temp_output_53_0_g50 );
				float dotResult71_g50 = dot( ase_worldNormal , ( -1 * normalizeResult20_g50 ) );
				float clampResult99_g50 = clamp( dotResult71_g50 , 0.0 , 1.0 );
				float clampResult111_g50 = clamp( pow( clampResult99_g50 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_717_62 = ( abs( ( length( temp_output_53_0_g50 ) - ( ( _DepthK / tex2D( _Depth5, temp_output_160_0_g50 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g50 : 0.0 );
				float3 temp_output_56_0_g52 = WorldPosition;
				float3 temp_output_57_0_g52 = _PositionOffset;
				float3 temp_output_61_0_g52 = _Camera6Position;
				float3 temp_output_53_0_g52 = ( ( temp_output_56_0_g52 - temp_output_57_0_g52 ) - temp_output_61_0_g52 );
				float3 break35_g53 = ( ( ( _Camera6Rotation * 3.141593 ) / 180 ) * -1 );
				float3 rotatedValue37_g53 = RotateAroundAxis( float3( 0,0,0 ), ( ( temp_output_56_0_g52 - temp_output_57_0_g52 ) - temp_output_61_0_g52 ), float3(0,1,0), break35_g53.y );
				float3 rotatedValue39_g53 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue37_g53, float3(1,0,0), break35_g53.x );
				float3 rotatedValue33_g53 = RotateAroundAxis( float3( 0,0,0 ), rotatedValue39_g53, float3(0,0,1), break35_g53.z );
				float3 break44_g53 = rotatedValue33_g53;
				float2 appendResult31_g53 = (float2(break44_g53.x , break44_g53.y));
				float2 temp_output_160_0_g52 = ( ( ( appendResult31_g53 / _CameraF ) / break44_g53.z ) + float2( 0.5,0.5 ) );
				float3 normalizeResult20_g52 = normalize( temp_output_53_0_g52 );
				float dotResult71_g52 = dot( ase_worldNormal , ( -1 * normalizeResult20_g52 ) );
				float clampResult99_g52 = clamp( dotResult71_g52 , 0.0 , 1.0 );
				float clampResult111_g52 = clamp( pow( clampResult99_g52 , _NormalCoeff ) , 0.0 , 1.0 );
				float temp_output_718_62 = ( abs( ( length( temp_output_53_0_g52 ) - ( ( _DepthK / tex2D( _Depth6, temp_output_160_0_g52 ).r ) + _DepthB ) ) ) <= ( _DropOcculusion == 0.0 ? 100.0 : _OcculusionTolerance ) ? clampResult111_g52 : 0.0 );
				float4 temp_output_84_0 = ( ( ( temp_output_722_62 * temp_output_722_0 * _EnableCam1 ) + ( temp_output_719_62 * tex2D( _Viewport2, temp_output_160_0_g54 ) * _EnableCam2 ) + ( temp_output_721_62 * tex2D( _Viewport3, temp_output_160_0_g58 ) * _EnableCam3 ) + ( temp_output_720_62 * tex2D( _Viewport4, temp_output_160_0_g56 ) * _EnableCam4 ) + ( temp_output_717_62 * tex2D( _Viewport5, temp_output_160_0_g50 ) * _EnableCam5 ) + ( temp_output_718_62 * tex2D( _Viewport6, temp_output_160_0_g52 ) * _EnableCam6 ) + ( _EmptyWeight * _EmptyColor ) ) / ( ( _EnableCam1 * temp_output_722_62 ) + ( _EnableCam2 * temp_output_719_62 ) + ( _EnableCam3 * temp_output_721_62 ) + ( _EnableCam4 * temp_output_720_62 ) + ( _EnableCam5 * temp_output_717_62 ) + ( _EnableCam6 * temp_output_718_62 ) + _EmptyWeight ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = temp_output_84_0.rgb;
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
			float4 _EmptyColor;
			float3 _Camera6Rotation;
			float3 _Camera6Position;
			float3 _Camera5Rotation;
			float3 _Camera5Position;
			float3 _Camera4Rotation;
			float3 _Camera4Position;
			float3 _Camera3Rotation;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float3 _Camera3Position;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _PositionOffset;
			float _NormalCoeff;
			float _EnableCam2;
			float _EmptyWeight;
			float _OcculusionTolerance;
			float _EnableCam3;
			float _DropOcculusion;
			float _DepthB;
			float _EnableCam4;
			float _CameraF;
			float _EnableCam5;
			float _DepthK;
			float _EnableCam6;
			float _EnableCam1;
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
			float4 _EmptyColor;
			float3 _Camera6Rotation;
			float3 _Camera6Position;
			float3 _Camera5Rotation;
			float3 _Camera5Position;
			float3 _Camera4Rotation;
			float3 _Camera4Position;
			float3 _Camera3Rotation;
			float3 _Camera2Rotation;
			float3 _Camera2Position;
			float3 _Camera3Position;
			float3 _Camera1Rotation;
			float3 _Camera1Position;
			float3 _PositionOffset;
			float _NormalCoeff;
			float _EnableCam2;
			float _EmptyWeight;
			float _OcculusionTolerance;
			float _EnableCam3;
			float _DropOcculusion;
			float _DepthB;
			float _EnableCam4;
			float _CameraF;
			float _EnableCam5;
			float _DepthK;
			float _EnableCam6;
			float _EnableCam1;
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
-196;-1027;1920;927;5214.909;1690.147;3.340743;True;False
Node;AmplifyShaderEditor.SimpleAddOpNode;6;-681.1222,-3.923917;Inherit;False;7;7;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;721;-1688.627,-306.8883;Inherit;False;SingleCameraMapping;1;;58;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;253;-1363.943,-683.3734;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-1949.079,256.759;Inherit;True;Property;_Viewport5;Viewport 5;20;0;Create;True;0;0;0;False;0;False;92a22c3073f174e259ea57f2a8403d5e;92a22c3073f174e259ea57f2a8403d5e;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;697;-2594.955,261.482;Inherit;True;Property;_Depth5;Depth 5;47;0;Create;True;0;0;0;False;0;False;None;81f1138ec6a204921a755f59d5b8be70;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-1356.951,607.5546;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;272;-977.0403,-1286.88;Inherit;True;Constant;_Float2;Float 2;34;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;37;-2966.03,-216.9255;Inherit;False;Property;_PositionOffset;PositionOffset;34;0;Create;True;0;0;0;False;0;False;0,0,0;3.5,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;250;-1366.198,164.43;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;67;-2150.972,-602.8923;Inherit;False;Property;_Camera2Rotation;Camera 2 Rotation;33;0;Create;True;0;0;0;False;0;False;0,0,0;11.33,60,-4.353713E-07;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;695;-2592.232,-313.2934;Inherit;True;Property;_Depth3;Depth 3;45;0;Create;True;0;0;0;False;0;False;None;8a69cc9b134364ad8871657d283a82da;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleDivideOpNode;84;-417.6054,-110.4605;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;246;-1597.488,-118.5289;Inherit;False;Property;_EnableCam4;Enable Cam 4;39;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;247;-1597.488,174.7489;Inherit;False;Property;_EnableCam5;Enable Cam 5;35;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-1365.2,-589.9842;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;258;-1207.081,872.4131;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;82;-2355.087,592.1214;Inherit;False;Property;_Camera6Position;Camera 6 Position;26;0;Create;True;0;0;0;False;0;False;0,0,0;2,1.5,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-1357.599,512.979;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;244;-1600.9,-682.9179;Inherit;False;Property;_EnableCam2;Enable Cam 2;37;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1947.834,-50.92311;Inherit;True;Property;_Viewport4;Viewport 4;19;0;Create;True;0;0;0;False;0;False;05734752a4255405aa18e1191e950651;05734752a4255405aa18e1191e950651;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;696;-2586.783,-24.54364;Inherit;True;Property;_Depth4;Depth 4;46;0;Create;True;0;0;0;False;0;False;None;211adf7b876d24960ad28072971e12f9;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;694;-2574.762,-600.5599;Inherit;True;Property;_Depth2;Depth 2;44;0;Create;True;0;0;0;False;0;False;None;ba859147f617041a6a4f2a0904ac9d5a;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;265;-2582.994,-892.0739;Inherit;True;Property;_Depth1;Depth 1;43;0;Create;True;0;0;0;False;0;False;None;0146383e3995643be92047c1c3fd405d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleAddOpNode;36;-217.1789,-438.396;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;717;-1706.439,256.9467;Inherit;False;SingleCameraMapping;1;;50;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;718;-1702.044,604.3686;Inherit;False;SingleCameraMapping;1;;52;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;719;-1702.781,-599.5066;Inherit;False;SingleCameraMapping;1;;54;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;720;-1703.988,-34.63258;Inherit;False;SingleCameraMapping;1;;56;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-1937.6,579.0958;Inherit;True;Property;_Viewport6;Viewport 6;21;0;Create;True;0;0;0;False;0;False;3d7039e2d91fd44f68f4f05c291fb0a7;3d7039e2d91fd44f68f4f05c291fb0a7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector3Node;73;-2362.968,-312.9946;Inherit;False;Property;_Camera3Position;Camera 3 Position;24;0;Create;True;0;0;0;False;0;False;0,0,0;-2,1.5,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;245;-1577.029,-387.9352;Inherit;False;Property;_EnableCam3;Enable Cam 3;38;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;83;-678.2205,-347.7461;Inherit;False;7;7;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-268.5599,-239.8742;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;21;-2149.21,-899.2417;Inherit;False;Property;_Camera1Rotation;Camera 1 Rotation;29;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;-1363.246,-885.668;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;255;-1484.693,846.8955;Inherit;False;Property;_EmptyWeight;EmptyWeight;41;0;Create;True;0;0;0;False;0;False;0.01;0.01;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;254;-1360.872,-977.3534;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;252;-1360.8,-394.2994;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-1363.588,-301.5157;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;80;-2365.407,264.4083;Inherit;False;Property;_Camera5Position;Camera 5 Position;22;0;Create;True;0;0;0;False;0;False;0,0,0;2,1.5,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;243;-1597.489,-988.1314;Inherit;False;Property;_EnableCam1;Enable Cam 1;36;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;369;-2993.659,89.48102;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-1368.823,256.7666;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;-1366.138,-33.59846;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;20;-2341.182,-898.6359;Inherit;False;Property;_Camera1Position;Camera 1 Position;27;0;Create;True;0;0;0;False;0;False;0,0,0;0,1,-2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;18;-2963.493,-361.9537;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;68;-2342.944,-602.2865;Inherit;False;Property;_Camera2Position;Camera 2 Position;25;0;Create;True;0;0;0;False;0;False;0,0,0;-2,1.5,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;81;-2157.047,590.3024;Inherit;False;Property;_Camera6Rotation;Camera 6 Rotation;32;0;Create;True;0;0;0;False;0;False;0,0,0;11.33,300,4.353713E-07;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;5;-1941.323,-901.144;Inherit;True;Property;_Viewport1;Viewport 1;0;0;Create;True;0;0;0;False;0;False;6e525e0933ba04ebe9d0f3860234333d;6e525e0933ba04ebe9d0f3860234333d;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;251;-1362.371,-125.649;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;77;-2353.114,-29.08919;Inherit;False;Property;_Camera4Position;Camera 4 Position;23;0;Create;True;0;0;0;False;0;False;0,0,0;0,1.5,2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;248;-1597.941,519.8408;Inherit;False;Property;_EnableCam6;Enable Cam 6;40;1;[Toggle];Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;79;-2167.367,262.5893;Inherit;False;Property;_Camera5Rotation;Camera 5 Rotation;31;0;Create;True;0;0;0;False;0;False;0,0,0;11.33,240,4.353713E-07;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;722;-1702.503,-891.2581;Inherit;False;SingleCameraMapping;1;;60;c8b5fbd685dd64b198a955213c46363d;0;7;55;SAMPLER2D;;False;79;SAMPLER2D;;False;56;FLOAT3;0,0,0;False;57;FLOAT3;0,0,0;False;59;FLOAT3;0,0,0;False;60;FLOAT3;0,0,0;False;61;FLOAT3;0,0,0;False;2;FLOAT;62;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;58;-2966.685,-58.41299;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;698;-2585.979,593.1341;Inherit;True;Property;_Depth6;Depth 6;48;0;Create;True;0;0;0;False;0;False;None;008ecc74e3a374dc7b0378989802d355;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;10;-1944.042,-322.9174;Inherit;True;Property;_Viewport3;Viewport 3;18;0;Create;True;0;0;0;False;0;False;a2aa7782c388b495d9d19bb8bfec8098;a2aa7782c388b495d9d19bb8bfec8098;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector3Node;78;-2155.074,-30.90819;Inherit;False;Property;_Camera4Rotation;Camera 4 Rotation;30;0;Create;True;0;0;0;False;0;False;0,0,0;11.32999,180,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;8;-1944.627,-599.8073;Inherit;True;Property;_Viewport2;Viewport 2;17;0;Create;True;0;0;0;False;0;False;0650854c277ec45588530cd7c0d9cb47;0650854c277ec45588530cd7c0d9cb47;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.ColorNode;257;-1433.783,930.8633;Inherit;False;Property;_EmptyColor;EmptyColor;42;0;Create;True;0;0;0;False;0;False;0.6226415,0.6226415,0.6226415,0;0.3962252,0.3962252,0.3962252,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;72;-2164.929,-314.8136;Inherit;False;Property;_Camera3Rotation;Camera 3 Rotation;28;0;Create;True;0;0;0;False;0;False;0,0,0;11.33,120,-4.353713E-07;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;TextureMapping6;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;6;0;91;0
WireConnection;6;1;92;0
WireConnection;6;2;93;0
WireConnection;6;3;94;0
WireConnection;6;4;95;0
WireConnection;6;5;96;0
WireConnection;6;6;258;0
WireConnection;721;55;10;0
WireConnection;721;79;695;0
WireConnection;721;56;18;0
WireConnection;721;57;37;0
WireConnection;721;59;369;0
WireConnection;721;60;72;0
WireConnection;721;61;73;0
WireConnection;253;0;244;0
WireConnection;253;1;719;62
WireConnection;96;0;718;62
WireConnection;96;1;718;0
WireConnection;96;2;248;0
WireConnection;250;0;247;0
WireConnection;250;1;717;62
WireConnection;84;0;6;0
WireConnection;84;1;83;0
WireConnection;92;0;719;62
WireConnection;92;1;719;0
WireConnection;92;2;244;0
WireConnection;258;0;255;0
WireConnection;258;1;257;0
WireConnection;249;0;248;0
WireConnection;249;1;718;62
WireConnection;36;0;722;0
WireConnection;36;1;97;0
WireConnection;717;55;14;0
WireConnection;717;79;697;0
WireConnection;717;56;18;0
WireConnection;717;57;37;0
WireConnection;717;59;369;0
WireConnection;717;60;79;0
WireConnection;717;61;80;0
WireConnection;718;55;16;0
WireConnection;718;79;698;0
WireConnection;718;56;18;0
WireConnection;718;57;37;0
WireConnection;718;59;369;0
WireConnection;718;60;81;0
WireConnection;718;61;82;0
WireConnection;719;55;8;0
WireConnection;719;79;694;0
WireConnection;719;56;18;0
WireConnection;719;57;37;0
WireConnection;719;59;369;0
WireConnection;719;60;67;0
WireConnection;719;61;68;0
WireConnection;720;55;12;0
WireConnection;720;79;696;0
WireConnection;720;56;18;0
WireConnection;720;57;37;0
WireConnection;720;59;369;0
WireConnection;720;60;78;0
WireConnection;720;61;77;0
WireConnection;83;0;254;0
WireConnection;83;1;253;0
WireConnection;83;2;252;0
WireConnection;83;3;251;0
WireConnection;83;4;250;0
WireConnection;83;5;249;0
WireConnection;83;6;255;0
WireConnection;97;0;84;0
WireConnection;91;0;722;62
WireConnection;91;1;722;0
WireConnection;91;2;243;0
WireConnection;254;0;243;0
WireConnection;254;1;722;62
WireConnection;252;0;245;0
WireConnection;252;1;721;62
WireConnection;93;0;721;62
WireConnection;93;1;721;0
WireConnection;93;2;245;0
WireConnection;95;0;717;62
WireConnection;95;1;717;0
WireConnection;95;2;247;0
WireConnection;94;0;720;62
WireConnection;94;1;720;0
WireConnection;94;2;246;0
WireConnection;251;0;246;0
WireConnection;251;1;720;62
WireConnection;722;55;5;0
WireConnection;722;79;265;0
WireConnection;722;56;18;0
WireConnection;722;57;37;0
WireConnection;722;59;369;0
WireConnection;722;60;21;0
WireConnection;722;61;20;0
WireConnection;1;2;84;0
ASEEND*/
//CHKSM=D3F83C0C10599B28746EF6F35B65E3DE0419643D