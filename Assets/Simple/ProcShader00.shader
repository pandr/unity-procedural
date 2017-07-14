Shader "Instanced/ProcShader00" {
	Properties{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader{

		Pass{

			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }

			ZWrite off
			ZTest Always
			Cull off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma target 4.5

			#include "UnityCG.cginc"

			sampler2D _MainTex;

			struct instanceData
			{
				float4 position;
				float4 size;
				float4 color;
			};

			StructuredBuffer<instanceData> positionBuffer;
			uniform float4x4 worldMat;
			float4 peelRange;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv_MainTex : TEXCOORD0;
				float4 color : TEXCOORD3;
			};

			v2f vert(uint vid : SV_VertexID, uint instanceID : SV_InstanceID)
			{

				// We just draw a bunch of vertices but want to pretend to
				// be drawing two-triangle quads. Build inst/vert id for this:
				int instID = vid / 120.0;
				int segID = vid / 6.0;
				int vertID = vid - segID * 6;
				segID -= instID * 20;

				// Generates (0,0) (1,0) (1,1) (1,1) (1,0) (0,0) from vertID
				float3 v_pos = saturate(float3(2 - abs(vertID - 2), 2 - abs(vertID - 3), 0));

				v_pos.y = segID * 0.05 + v_pos.y * 0.05;

				// Generate uv
				float2 uv = float2(v_pos.x, v_pos.y);

				v_pos.x = -1.0 + 2.0*v_pos.x;

				float ra = sin(1137.5*instID);
				v_pos.x *= 0.08 + sin(v_pos.y*10.0 + _Time.w*.2 + ra)*0.005 - pow(v_pos.y, 2.0)*0.05;
				v_pos.x += 0.3*sin(_Time.w*0.1 + v_pos.y*ra*6.0 + ra*100.0 + cos(ra*123.4 + _Time.w*0.17))*(v_pos.y);
				v_pos.y *= 2.2 + 0.5*ra;


				// Read instance data
				float4 pos = positionBuffer[instID].position;
				float4 scale = positionBuffer[instID].size;
				float4 color = positionBuffer[instID].color;

				pos = mul(worldMat, float4(pos.xyz, 1));
				float3 dir = mul(worldMat, float4(scale.xyz, 0)).xyz;

				float3 viewDir = UnityWorldSpaceViewDir(pos);
				float3 viewRight = normalize(cross(viewDir, dir));
				float3 viewUp = dir;

				// Generate position
				v_pos *= scale.w;
				v_pos = viewRight*v_pos.x + viewUp*v_pos.y;
				float3 p = v_pos + pos.xyz;

				v2f o;
				o.pos = float4(p, 1);
				o.pos = UnityWorldToClipPos(o.pos);
				o.uv_MainTex = uv;
				float r = dot(normalize(viewDir), normalize(dir));
				float b = saturate(min((peelRange.y - r) * 10, 1 + (r - peelRange.x) * 10));
				o.color = float4(1, 1, 1, b);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				float vcolb = i.color.a;
				float2 uv = i.uv_MainTex;
				float c = 1.0 - abs(0.5 - uv.x)*2.0;
				float x = pow((abs(uv.x - 0.5)), 1.4) + pow((abs(uv.y - 0.2)), 0.8)*(uv.y*1.1);
				float mask = clamp((6.0 - uv.y*6.0) - (uv.x*0.5 - 0.25)*(uv.x*0.5 - 0.25), 0.0, 1.0);
				float ox = x;
				x *= 1.2;
				//x += 0.2*vcolb - 0.1;
				x = clamp(x, 0.0, 1.0);
				x = x * x;

				float4 col = float4(
					(1.0 - x)*(1.0 - x)*(1.0 - x)*0.8 + pow(x, 3.4),
					x*x*x + (1.0 - x)*(1.0 - x)*0.1,
					smoothstep(0.4, 0.7, x),
					cos((uv.x - 0.5)*3.14)
					);
				col.g += abs(x - 0.02) < 0.01 ? x*10.0 : 0;
				col = col*smoothstep(0.1, 0.4, mask);
				col.w = min(col.w, uv.y*10.0 - 0.1)*vcolb;
				col.xyz *= 0.7 + 0.3*uv.y;
				col.xyz = pow(col.xyz, 2.0);
				return col;
			}

		ENDCG
	}
	}
}
