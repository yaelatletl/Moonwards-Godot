shader_type spatial;
render_mode blend_mix,depth_draw_opaque,world_vertex_coords;
uniform sampler2D splatmap;
uniform sampler2D splatmap_2;
uniform sampler2D global_normal;
uniform sampler2D global_albedo;
uniform bool show_splatmap;
uniform bool detail_enabled;

uniform sampler2D texture0;
uniform sampler2D normal_tex0;
uniform float normal_depth0 : hint_range(-16,16);

uniform sampler2D texture1;
uniform sampler2D normal_tex1;
uniform float normal_depth1 : hint_range(-16,16);

uniform sampler2D texture2;
uniform sampler2D normal_tex2;
uniform float normal_depth2 : hint_range(-16,16);

uniform sampler2D texture3;
uniform sampler2D normal_tex3;
uniform float normal_depth3 : hint_range(-16,16);

uniform sampler2D texture4;
uniform sampler2D normal_tex4;
uniform float normal_depth4 : hint_range(-16,16);

uniform sampler2D texture5;
uniform sampler2D normal_tex5;
uniform float normal_depth5 : hint_range(-16,16);


uniform sampler2D detail_normal;
uniform float detail_normal_depht : hint_range(-1,1);
uniform float normal_depth : hint_range(-16,16);

uniform float specular;
uniform float metallic;
uniform float subsurface_scattering_strength : hint_range(0,1);

varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;
varying vec3 uv3_triplanar_pos;
varying vec3 uv4_triplanar_pos;
varying vec3 uv5_triplanar_pos;
varying vec3 uv6_triplanar_pos;
uniform float uv1_blend_sharpness = 1;
varying vec3 uv1_power_normal;
uniform float uv2_blend_sharpness = 1;
varying vec3 uv2_power_normal;
uniform float uv3_blend_sharpness = 1;
varying vec3 uv3_power_normal;
uniform float uv4_blend_sharpness = 1;
varying vec3 uv4_power_normal;
uniform float uv5_blend_sharpness = 1;
varying vec3 uv5_power_normal;
uniform float uv6_blend_sharpness = 1;
varying vec3 uv6_power_normal;
uniform float uv1_scale = 0.1;
uniform vec3 uv1_offset;
uniform float uv2_scale = 0.1;
uniform vec3 uv2_offset;
uniform float uv3_scale = 0.1;
uniform vec3 uv3_offset;
uniform float uv4_scale = 0.1;
uniform vec3 uv4_offset;
uniform float uv5_scale = 0.1;
uniform vec3 uv5_offset;
uniform float uv6_scale = 0.1;
uniform vec3 uv6_offset;

uniform float blend = 0;

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv2_power_normal=pow(abs(NORMAL), vec3(uv2_blend_sharpness));
	uv2_power_normal/=dot(uv2_power_normal,vec3(1.0));
	uv2_triplanar_pos = VERTEX * uv2_scale + uv2_offset;
	uv2_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv3_power_normal=pow(abs(NORMAL),vec3(uv3_blend_sharpness));
	uv3_power_normal/=dot(uv3_power_normal,vec3(1.0));
	uv3_triplanar_pos = VERTEX * uv3_scale + uv3_offset;
	uv3_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv4_power_normal=pow(abs(NORMAL),vec3(uv4_blend_sharpness));
	uv4_power_normal/=dot(uv4_power_normal,vec3(1.0));
	uv4_triplanar_pos = VERTEX * uv4_scale + uv4_offset;
	uv4_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv5_power_normal=pow(abs(NORMAL),vec3(uv5_blend_sharpness));
	uv5_power_normal/=dot(uv5_power_normal,vec3(1.0));
	uv5_triplanar_pos = VERTEX * uv5_scale + uv5_offset;
	uv5_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	uv6_power_normal=pow(abs(NORMAL),vec3(uv6_blend_sharpness));
	uv6_power_normal/=dot(uv6_power_normal,vec3(1.0));
	uv6_triplanar_pos = VERTEX * uv6_scale + uv6_offset;
	uv6_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec3 color0;
	vec3 normal0;
	vec3 color1;
	vec3 normal1;
	vec3 color2;
	vec3 normal2;
	vec3 color3;
	vec3 normal3;
	vec3 color4;
	vec3 normal4;
	vec3 color5;
	vec3 normal5;
	vec3 normal;
	vec3 albedo;
	vec3 splatmapcolor;
	vec3 splatmapcolor_2;
	vec4 globalnormal;
	globalnormal = texture(global_normal, UV);
	
	vec3 mixed_splatcolor = mix(texture(splatmap, UV).rgb, texture(splatmap_2, UV).rgb, (greaterThan(texture(splatmap_2, UV).rgb, vec3(0.08))));
	splatmapcolor = max(vec3(0.0), mixed_splatcolor - texture(splatmap_2, UV).rgb);
	splatmapcolor_2 = max(vec3(0.0), mixed_splatcolor - texture(splatmap, UV).rgb);

	color0 = triplanar_texture(texture0, uv1_power_normal, uv1_triplanar_pos).rgb * splatmapcolor.r;
	normal0 = triplanar_texture(normal_tex0, uv1_power_normal, uv1_triplanar_pos).rgb * splatmapcolor.r;

	color1 = triplanar_texture(texture1,uv2_power_normal, uv2_triplanar_pos).rgb * splatmapcolor.g;
	normal1 = triplanar_texture(normal_tex2, uv2_power_normal, uv2_triplanar_pos).rgb * splatmapcolor.g;

	color2 = triplanar_texture(texture2, uv3_power_normal, uv3_triplanar_pos).rgb * splatmapcolor.b;
	normal2 = triplanar_texture(normal_tex2, uv3_power_normal, uv3_triplanar_pos).rgb * splatmapcolor.b;
	
	color3 = triplanar_texture(texture3, uv4_power_normal, uv4_triplanar_pos).rgb * splatmapcolor_2.r;
	normal3 = triplanar_texture(normal_tex3, uv4_power_normal, uv4_triplanar_pos).rgb * splatmapcolor_2.r;
	
	color4 = triplanar_texture(texture4, uv5_power_normal, uv5_triplanar_pos).rgb * splatmapcolor_2.g;
	normal4 = triplanar_texture(normal_tex4, uv5_power_normal, uv5_triplanar_pos).rgb * splatmapcolor_2.g;
	
	color5 = triplanar_texture(texture5, uv6_power_normal, uv6_triplanar_pos).rgb * splatmapcolor_2.b;
	normal5 = triplanar_texture(normal_tex5, uv6_power_normal, uv6_triplanar_pos).rgb * splatmapcolor_2.b;
	
	albedo = texture(global_albedo,UV).rgb  * (vec3(1.0) - (splatmapcolor.r));
	albedo = albedo * (vec3(1.0) - (splatmapcolor.g));
	albedo = albedo * (vec3(1.0) - (splatmapcolor.b));
	
	albedo = albedo * (vec3(1.0) - (splatmapcolor_2.r));
	albedo = albedo * (vec3(1.0) - (splatmapcolor_2.g));
	albedo = albedo * (vec3(1.0) - (splatmapcolor_2.b));
	
	albedo = (albedo + color0 + color1 + color2 + color3 + color4 + color5);
	ALBEDO = albedo;

	normal = texture(global_normal, UV).rgb * (vec3(1.0) - (splatmapcolor.r));
	if (detail_enabled) {
	normal = (texture(global_normal,UV).rgb+detail_normal_depht*(triplanar_texture(detail_normal, uv3_power_normal, uv3_triplanar_pos*10.0).rgb * (vec3(1.0) - (splatmapcolor.r))));
	}
	normal = normal * (vec3(1.0) - (splatmapcolor.g));
	normal = normal * (vec3(1.0) - (splatmapcolor.b));
	
	normal = normal * (vec3(1.0) - (splatmapcolor_2.r));
	normal = normal * (vec3(1.0) - (splatmapcolor_2.g));
	normal = normal * (vec3(1.0) - (splatmapcolor_2.b));
	
	SPECULAR = specular;
	METALLIC = metallic;
	ROUGHNESS = 1.0;
	
	NORMALMAP = normalize(normal_depth*normal + normal_depth0*normal0 + normal_depth1*normal1 + normal_depth2*normal2 + normal_depth3*normal3 + normal_depth4*normal4 + normal_depth5*normal5);
	NORMALMAP = (NORMALMAP + globalnormal.rgb)/length(NORMALMAP+globalnormal.rgb);
	
	if(show_splatmap){
		ALBEDO = (splatmapcolor + splatmapcolor_2).rgb;
	}
	
	
	SSS_STRENGTH=subsurface_scattering_strength;
	//FLAG!
}
