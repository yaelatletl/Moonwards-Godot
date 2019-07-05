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
	color0 = texture(texture0, UV * tex0_scale).rgb * splatmapcolor.r;
	normal0 = texture(normal_tex0, UV * tex0_scale).rgb * splatmapcolor.r;
	color1 = texture(texture1, UV * tex1_scale).rgb * splatmapcolor.g;
	normal1 = texture(normal_tex1, UV * tex1_scale).rgb * splatmapcolor.g;
	color2 = texture(texture2, UV * tex2_scale).rgb * splatmapcolor.b;
	normal2 = texture(normal_tex2, UV * tex2_scale).rgb * splatmapcolor.b;
	
//	albedo = texture(albedo_tex, UV).rgb * (vec3(1.0) - (splatmapcolor.r));
//	albedo = albedo * (vec3(1.0) - (splatmapcolor.g));
//	albedo = albedo * (vec3(1.0) - (splatmapcolor.b));

//	albedo = texture(albedo_tex, UV).rgb * (1.0 - splatmapcolor.a);
	
//	normal = texture(normal_tex, UV).rgb * (vec3(1.0) - (splatmapcolor.r));
//	normal = normal * (vec3(1.0) - (splatmapcolor.g));
//	normal = normal * (vec3(1.0) - (splatmapcolor.b));
	normal = (texture(normal_tex, UV).rgb * max(0.0, (1.0 - splatmapcolor.r - splatmapcolor.g - splatmapcolor.b)));
	normal = normal + (blend * (normal0 + normal1 + normal2));
	NORMALMAP = normal;

//	normal = texture(normal_tex, UV).rgb * (1.0 - splatmapcolor.a);
	
	albedo = (texture(albedo_tex, UV).rgb * max(0.0, (1.0 - splatmapcolor.r - splatmapcolor.g - splatmapcolor.b)));
	albedo = albedo + (blend * (color0 + color1 + color2));
	ALBEDO = albedo;
}