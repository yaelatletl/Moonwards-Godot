shader_type particles;

uniform float rows = 4;
uniform float spacing= 1.0;
uniform sampler2D noise;
uniform sampler2D rotation_noise_r;
uniform sampler2D rotation_noise_g;
uniform sampler2D rotation_noise_b;
uniform sampler2D heightmap;
uniform float terrain_height = 3060;
uniform float amplitude = 15.0;
uniform float y_offset = 15.0;
uniform float scale = 0.5;
uniform vec2 heightmap_size = vec2(300.0, 300.0);

float get_height(vec2 pos){
	pos += 0.5 * heightmap_size;
	pos /= heightmap_size;
	float vectorade = amplitude * (texture(heightmap, pos).r );
	return vectorade - 0.1*texture(noise,pos).r;
	//return vectorade;
}

void vertex(){
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;
	
	pos *= spacing;
	
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);
	
	vec3 noise_space = 10.0*texture(rotation_noise_g, 0.001*pos.xz).rgb;
	pos.x += noise_space.x * spacing;
	pos.z += noise_space.z * spacing;
	
	TRANSFORM[0][0] = EMISSION_TRANSFORM[0][0] - mod(EMISSION_TRANSFORM[0][0], texture(rotation_noise_r, pos.xz).r);
	TRANSFORM[1][1] = EMISSION_TRANSFORM[1][1] - mod(EMISSION_TRANSFORM[1][1], texture(rotation_noise_r, pos.xy).r);
	TRANSFORM[2][2] = EMISSION_TRANSFORM[2][2] - mod(EMISSION_TRANSFORM[2][2], texture(rotation_noise_r, pos.xy).r);
	TRANSFORM[2][3] = EMISSION_TRANSFORM[2][3] - mod(EMISSION_TRANSFORM[2][3], texture(rotation_noise_r, pos.xy).r);
	
	TRANSFORM[0][0] *= scale;
	TRANSFORM[1][1] *= scale;
	TRANSFORM[2][2] *= scale;
	
	pos.y = get_height(pos.xz);
	
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y + y_offset;
	TRANSFORM[3][2] = pos.z;
}