shader_type particles;

uniform float rows = 4;
uniform float spacing= 1.0;
uniform sampler2D noise;
uniform sampler2D rotation_noise_r;
uniform sampler2D rotation_noise_g;
uniform sampler2D rotation_noise_b;
uniform sampler2D heightmap;
uniform float amplitude = 15.0;
uniform vec2 heightmap_size = vec2(300.0, 300.0);

float get_height(vec2 pos){
	pos -= 0.5 * heightmap_size;
	pos /= heightmap_size;
	
	return amplitude * (texture(heightmap, pos).r  - texture(noise,pos).r);
}

void vertex(){
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, rows);
	pos.z = (pos.z - pos.x) / rows;
	
	pos.x -= rows * 0.5;
	pos.z -= rows * 0.5;
	
	pos *= texture(rotation_noise_g, pos.xz).b+spacing;
	
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], spacing);
	TRANSFORM[0][0] = EMISSION_TRANSFORM[0][0] - mod(EMISSION_TRANSFORM[0][0], texture(rotation_noise_r, pos.xz).r);
	TRANSFORM[1][1] = EMISSION_TRANSFORM[1][1] - mod(EMISSION_TRANSFORM[1][1], texture(rotation_noise_r, pos.xy).r);
	TRANSFORM[2][2] = EMISSION_TRANSFORM[2][2] - mod(EMISSION_TRANSFORM[2][2], texture(rotation_noise_r, pos.xy).r);
	TRANSFORM[2][3] = EMISSION_TRANSFORM[2][3] - mod(EMISSION_TRANSFORM[2][3], texture(rotation_noise_r, pos.xy).r);
	
	pos.y = get_height(pos.xz);
	
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y;
	TRANSFORM[3][2] = pos.z;
}