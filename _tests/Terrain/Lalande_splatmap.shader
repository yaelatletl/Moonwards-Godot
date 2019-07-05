shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,world_vertex_coords;
uniform sampler2D splatmap;
uniform sampler2D global_normal;

uniform sampler2D texture0;
uniform sampler2D normal_tex0;
uniform float normal_depth0 : hint_range(-16,16);

uniform sampler2D texture1;
uniform sampler2D normal_tex1;
uniform float normal_depth1 : hint_range(-16,16);

uniform sampler2D texture2;
uniform sampler2D normal_tex2;
uniform float normal_depth2 : hint_range(-16,16);

uniform sampler2D albedo_tex;
uniform sampler2D normal_tex;
uniform float normal_depth : hint_range(-16,16);

uniform float specular;
uniform float metallic;
uniform float subsurface_scattering_strength : hint_range(0,1);

uniform float tex0_scale = 1;
uniform float tex1_scale = 1;
uniform float tex2_scale = 1;



varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;
varying vec3 uv3_triplanar_pos;
uniform float uv1_blend_sharpness = 1;
varying vec3 uv1_power_normal;
uniform float uv2_blend_sharpness = 1;
varying vec3 uv2_power_normal;
uniform float uv3_blend_sharpness = 1;
varying vec3 uv3_power_normal;
uniform vec3 uv1_scale = vec3(0.1,0.1,0.1);
uniform vec3 uv1_offset;
uniform vec3 uv2_scale = vec3(0.1,0.1,0.1);
uniform vec3 uv2_offset;
uniform vec3 uv3_scale = vec3(0.1,0.1,0.1);
uniform vec3 uv3_offset;

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
	vec3 normal;
	vec3 albedo;
	vec4 splatmapcolor;
	vec4 globalnormal;
	globalnormal = texture(global_normal, UV);
	splatmapcolor = texture(splatmap, UV);

	color0 = triplanar_texture(texture0, uv1_power_normal, uv1_triplanar_pos).rgb * splatmapcolor.r;
	normal0 = triplanar_texture(normal_tex0, uv1_power_normal, uv1_triplanar_pos).rgb * splatmapcolor.r;

	color1 = triplanar_texture(texture1,uv2_power_normal, uv2_triplanar_pos).rgb * splatmapcolor.g;
	normal1 = triplanar_texture(normal_tex2, uv2_power_normal, uv2_triplanar_pos).rgb * splatmapcolor.g;


	color2 = triplanar_texture(texture2, uv3_power_normal, uv3_triplanar_pos).rgb * splatmapcolor.b;
	normal2 = triplanar_texture(normal_tex2, uv3_power_normal, uv3_triplanar_pos).rgb * splatmapcolor.b;

	albedo = triplanar_texture(albedo_tex, uv1_power_normal, uv1_triplanar_pos).rgb * (vec3(1.0) - (splatmapcolor.r));
	albedo = albedo * (vec3(1.0) - (splatmapcolor.g));
	albedo = albedo * (vec3(1.0) - (splatmapcolor.b));
	albedo = (albedo + color0 + color1 + color2);
	ALBEDO = albedo;

	normal = triplanar_texture(normal_tex, uv1_power_normal, uv1_triplanar_pos).rgb * (vec3(1.0) - (splatmapcolor.r));
	normal = normal * (vec3(1.0) - (splatmapcolor.g));
	normal = normal * (vec3(1.0) - (splatmapcolor.b));
	
	//albedo = mix(albedo,color1,splatmapcolor.r);
	//albedo = mix(albedo,color2,splatmapcolor.g);
	//albedo = mix(albedo,color0,splatmapcolor.b);
	SPECULAR = specular;
	METALLIC = metallic;
	ROUGHNESS = 1.0;
	NORMALMAP = (normal_depth*normal + normal_depth0*normal0 + normal_depth1*normal1 + normal_depth2*normal2);
	NORMALMAP = (NORMALMAP + globalnormal.rgb)/dot(NORMALMAP, globalnormal.rgb);
	
	
	SSS_STRENGTH=subsurface_scattering_strength;
	//FLAG!
}
