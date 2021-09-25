Shader "Unlit/MulLight"
{
 Properties
 {
  _MainTex ("Texture", 2D) = "white" {}
 }
 SubShader
 {
  //一盏主灯
  Pass
  {
   //Always: 总是渲染；没有光照模式。
   //ForwardBase: 适用于前渲染、环境、主要方向灯、光/sh光和烘焙图。
   //ForwardAdd: 适用于前渲染， 叠加每一盏灯，每一盏灯就多一个pass。
   //Deferred: 延迟渲染，渲染g缓冲区 。
   //ShadowCaster:将物体深度渲染到阴影贴图或者深度纹理上 。
   //PrepassBase: 用于传统的延迟光照，渲染法线和高光效果。
   //PrepassFinal:用于传统的延迟光照，通过结合文理、灯光、和法线来渲染最终的结果。
   //Vertex:当对象不是光映射时，用于遗留顶点的渲染，所有顶点灯都被利用。 
   //VertexLMRGBM: 当对象被光映射时，在遗留的顶点上使用渲染，在LightMap是RGBM编码的平台上（pc和控制台）。
   //VertexLM: 当对象被光映射时，在遗留的顶点上使用渲染，在LightMap是双idr编码的（移动平台）平台上。
   Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}//////
   CGPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "UnityCG.cginc"
    #pragma target 3.0 
 
   //衰减与阴影的实现
   #include "AutoLight.cginc"//////
    //fwdadd：ForwardBase的阴影显示，在下面的ForwardAdd里得用fwdadd； 必须结合fallback，两者缺一不可 
   #pragma multi_compile_fwdadd_fullshadows//////
   sampler2D _MainTex;
   float4 _MainTex_ST;
   //定义一个灯光,名字为固定格式，会自动取场景中灯光
   float4 _LightColor0;//////
 
   struct appdata
   {
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float4 normal:NORMAL;//////
   };
 
   struct v2f
   {
    float2 uv : TEXCOORD0;
    float4 pos: SV_POSITION;
    float3 normal :TEXCOORD1;//////
     //点光源需要的衰减 
    LIGHTING_COORDS(3,4)//////#include "AutoLight.cginc"
   };
   v2f vert (appdata v)
   {
    v2f o;
    //这里一般用 o.pos，用o.vertex有时候会报错 
    o.pos= UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = v.normal;//////
    //点光源需要的衰减 
    TRANSFER_VERTEX_TO_FRAGMENT(o)//////#include "AutoLight.cginc"
    return o;
   }
   fixed4 frag (v2f i) : SV_Target
   {
    //物体法向量转化为世界法向量
    float3 N = normalize(UnityObjectToWorldNormal(i.normal));//////
    //世界光向量：unity封装好的光向量，会自动调用场景里面的存在的灯光
    float3 L =normalize( _WorldSpaceLightPos0.xyz);//////
             //点光源需要的衰减系数
    float atten = LIGHT_ATTENUATION(i);//////#include "AutoLight.cginc"
 
    fixed4 col = tex2D(_MainTex, i.uv);
    //最终颜色 = 主颜色 x（ 灯光颜色 x 漫反射系数 x衰减系数 + 环境光）
    col.rgb = col.rgb * (_LightColor0.rgb* saturate(dot(N,L)) *atten + UNITY_LIGHTMODEL_AMBIENT);//////
 
    return col;
   }
   ENDCG
   }
 
   //多盏灯叠加
  Pass//////
  {
   Tags { "RenderType"="Opaque" "LightMode" = "ForwardAdd"} //ForwardAdd ：多灯混合//////
   Blend One One//////
   CGPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "UnityCG.cginc"
   #pragma target 3.0
 
   //衰减与阴影的实现
   #include "AutoLight.cginc"//////
    //fwdadd：ForwardAdd的阴影显示，在上面的ForwardBase里得用fwdbase； 必须结合fallback，两者缺一不可 
   #pragma multi_compile_fwdadd_fullshadows//////
 
   sampler2D _MainTex;
   float4 _MainTex_ST;
   //定义一个灯光,名字为固定格式，会自动取场景中灯光
   float4 _LightColor0;//////
 
   struct appdata
   {
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float4 normal:NORMAL;//////
   };
 
   struct v2f
   {
    float2 uv : TEXCOORD0;
    float4 pos: SV_POSITION;
    float3 normal :TEXCOORD1;//////
    float4 wPos :TEXCOORD2;//////
    //点光源需要的衰减 
    LIGHTING_COORDS(3,4)//////#include "AutoLight.cginc"
   };
   v2f vert (appdata v)
   {
    v2f o;
     //这里一般用 o.pos，用o.vertex有时候会报错
    o.pos= UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.wPos= mul(unity_ObjectToWorld, v.vertex);//////
    o.normal = v.normal;//////
    //点光源需要的衰减
    TRANSFER_VERTEX_TO_FRAGMENT(o)//////#include "AutoLight.cginc"
    return o;
   }
   fixed4 frag (v2f i) : SV_Target
   {
    //物体法向量转化为世界法向量
    float3 N = normalize(UnityObjectToWorldNormal(i.normal));//////
 
    //世界光向量：这里计算的是点光源，按照灯光的距离来算衰减，第一个pass不需要
    float3 L = normalize (lerp(_WorldSpaceLightPos0.xyz , _WorldSpaceLightPos0.xyz - i.wPos.xyz , _WorldSpaceLightPos0.w));//////
 
    //点光源需要的衰减
    float atten = LIGHT_ATTENUATION(i);//////#include "AutoLight.cginc"
 
    fixed4 col = tex2D(_MainTex, i.uv);
 
    //最终颜色 = 主颜色 x 灯光颜色 x 漫反射系数 x 衰减系数 第一个pass已经有了环境色 这里就不能加了
    col.rgb = col.rgb * _LightColor0.rgb * saturate(dot(N,L))*atten;//////
 
    return col;
   }
  ENDCG
  }
 }
   //需要产生阴影 
   FallBack "Diffuse" 
}