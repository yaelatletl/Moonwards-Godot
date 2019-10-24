shader_type spatial;
//render_mode unshaded, cull_disabled;

uniform sampler2D splatmap;
uniform sampler2D texture0;
uniform sampler2D normal_tex0;
uniform sampler2D texture1;
uniform sampler2D normal_tex1;
uniform sampler2D texture2;
uniform sampler2D normal_tex2;

uniform sampler2D albedo_tex;
uniform sampler2D normal_tex;

uniform float tex0_scale = 1;
uniform float tex1_scale = 1;
uniform float tex2_scale = 1;

uniform float blend : hint_range(0, 1);
// Compute local triangle barycentric coordinates and vertex IDs
void TriangleGrid ( vec2 uv ,
out float w1 , out float w2 , out float w3 ,
out vec2 vertex1 , out vec2 vertex2 , out vec2 vertex3 )
{
// Scaling of the input
uv *= 3.464; // 2 * sqrt (3)
// Skew input space into simplex triangle grid
mat2 gridToSkewedGrid = mat2 (vec2(1.0 , 0.0) , vec2(-0.57735027 , 1.15470054)) ;
vec2 skewedCoord = gridToSkewedGrid * uv ;
// Compute local triangle vertex IDs and local barycentric coordinates
ivec2 baseId = ivec2 ( floor ( skewedCoord ));
vec3 temp = vec3 ( fract ( skewedCoord ) , 0) ;
temp .z = 1.0 - temp . x - temp .y;
if ( temp . z > 0.0)
{
w1 = temp .z;
w2 = temp .y;
w3 = temp .x;
vertex1 = vec2(float(baseId.x), float(baseId.y)) ;
vertex2 = vertex1 + vec2 (0 , 1) ;
vertex3 = vertex1 + vec2 (1 , 0) ;
}
else
{
w1 = - temp .z ;
w2 = 1.0 - temp .y;
w3 = 1.0 - temp .x;
vertex1 = vec2(float(baseId.x), float(baseId.y)) + vec2 (1 , 1) ;
vertex2 = vec2(float(baseId.x), float(baseId.y)) + vec2 (1 , 0) ;
vertex3 = vec2(float(baseId.x), float(baseId.y)) + vec2 (0 , 1) ;
}
}

vec2 hash2D2D (vec2 s)
{
    //magic numbers
    return fract(sin(mod(vec2(dot(s, vec2(127.1,311.7)), dot(s, vec2(269.5,183.3))), 3.14159))*43758.5453);
}

vec3 ProceduralTilingAndBlending (sampler2D input,   vec2 uv )
{
// Get triangle info
float w1 , w2 , w3 ;
vec2 vertex1 , vertex2 , vertex3 ;
TriangleGrid (uv , w1 , w2 , w3 , vertex1 , vertex2 , vertex3 );
// Assign random offset to each triangle vertex
vec2 uv1 = uv + hash2D2D ( vertex1 );
vec2 uv2 = uv + hash2D2D ( vertex2 );
vec2 uv3 = uv + hash2D2D ( vertex3 );
// Precompute UV derivatives
vec2 duvdx = dFdx ( uv ) ;
vec2 duvdy = dFdy ( uv ) ;
// Fetch input
vec3 I1 = textureGrad ( input , uv1 , duvdx , duvdy ). rgb ;
vec3 I2 = textureGrad ( input , uv2 , duvdx , duvdy ). rgb ;
vec3 I3 = textureGrad ( input , uv3 , duvdx , duvdy ). rgb ;
// Variance - preserving blending
vec3 G;
vec3 I = w1 * I1 + w2 * I2 + w3 * I3 ;
G = I - vec3 (0.5) ;
G = G * inversesqrt ( w1 * w1 + w2 * w2 + w3 * w3 ) ;
G = G + vec3 (0.5) ;
vec3 grayXfer = vec3(0.3, 0.59, 0.11);
vec3 gray = vec3(dot(grayXfer, G));
G = mix(G, gray, 0.5);

return mix(I,G,0.4);
}
 
//stochastic sampling
vec4 textureStochastic(sampler2D tex, vec2 uv)
{
    //triangle vertices and blend weights
    //BW_vx[0...2].xyz = triangle verts
    //BW_vx[3].xy = blend weights (z is unused)
    mat4 BW_vx;
 
    //uv transformed into triangular grid space with UV scaled by approximation of 2*sqrt(3)
    vec2 newUV = (mat2(vec2(1.0 , 0.0) , vec2(-0.57735027 , 1.15470054))* uv * 3.464);
 
    //vertex IDs and barycentric coords
    vec2 vxID = vec2 (floor(newUV));
    vec3 fracted = vec3 (fract(newUV), 0);
    fracted.z = 1.0-fracted.x-fracted.y;
 
    BW_vx = ((fracted.z>0.0) ?
        mat4(vec4(vxID, 0,0), vec4(vxID + vec2(0, 1), 0,0), vec4(vxID + vec2(1, 0), 0,0), vec4(fracted,0)) :
        mat4(vec4(vxID + vec2 (1, 1), 0,0), vec4(vxID + vec2 (1, 0), 0,0), vec4(vxID + vec2 (0, 1), 0,0), vec4(-fracted.z, 1.0-fracted.y, 1.0-fracted.x,0)));
 
    //calculate derivatives to avoid triangular grid artifacts
    vec2 dx = dFdx(uv);
    vec2 dy = dFdy(uv);

    //blend samples with calculated weights
    return (textureGrad(tex, uv + hash2D2D(BW_vx[0].xy), dx, dy) * BW_vx[3].x +
	       textureGrad(tex, uv + hash2D2D(BW_vx[1].xy), dx, dy) * BW_vx[3].y +
           textureGrad(tex, uv + hash2D2D(BW_vx[2].xy), dx, dy) * BW_vx[3].z);
	
}
vec4 STexComplexB(sampler2D input, vec2 uv){
	vec4 tex = vec4(ProceduralTilingAndBlending(input, uv),1);
	tex = mix(tex, textureStochastic(input, uv), 0.4);
	return tex;
}
void fragment() { 
	vec3 color0;
	vec3 normal0;
	vec3 color1;
	vec3 normal1;
	vec3 color2;
	vec3 normal2;
	vec3 normal;
	vec3 albedo;
	vec4 splatmapcolor;
	
	splatmapcolor = texture(splatmap, UV);
	color0 = STexComplexB(texture0, UV * tex0_scale).rgb * splatmapcolor.r;
	normal0 = (STexComplexB(normal_tex0, UV * tex0_scale).rgb * splatmapcolor.r);
	color1 = STexComplexB(texture1, UV * tex1_scale).rgb * splatmapcolor.g;
	normal1 = (STexComplexB(normal_tex1, UV * tex1_scale).rgb * splatmapcolor.g);
	color2 = STexComplexB(texture2, UV * tex2_scale).rgb * splatmapcolor.b;
	normal2 = (STexComplexB(normal_tex2, UV * tex2_scale).rgb * splatmapcolor.b);
	
//	albedo = texture(albedo_tex, UV).rgb * (vec3(1.0) - (splatmapcolor.r));
//	albedo = albedo * (vec3(1.0) - (splatmapcolor.g));
//	albedo = albedo * (vec3(1.0) - (splatmapcolor.b));

//	albedo = texture(albedo_tex, UV).rgb * (1.0 - splatmapcolor.a);
	
//	normal = texture(normal_tex, UV).rgb * (vec3(1.0) - (splatmapcolor.r));
//	normal = normal * (vec3(1.0) - (splatmapcolor.g));
//	normal = normal * (vec3(1.0) - (splatmapcolor.b));
	normal = (texture(normal_tex, UV).rgb * max(0.0, (1.0 - splatmapcolor.r - splatmapcolor.g - splatmapcolor.b)));
	normal = normal + (blend * (normal0 + normal1 + normal2))/length(normal + normal0 + normal1 + normal2);
	NORMALMAP = normal;

//	normal = texture(normal_tex, UV).rgb * (1.0 - splatmapcolor.a);
	
	albedo = (texture(albedo_tex, UV).rgb * max(0.0, (1.0 - splatmapcolor.r - splatmapcolor.g - splatmapcolor.b)));
	albedo = albedo + (blend * (color0 + color1 + color2));
	ALBEDO = albedo;
}