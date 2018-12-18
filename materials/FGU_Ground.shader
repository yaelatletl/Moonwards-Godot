shader_type spatial;

uniform sampler2D FGU_Ground_Splatmap;
uniform sampler2D moss;
uniform sampler2D fusedrock;
uniform sampler2D plants1;

uniform float mossres = 1;
uniform float fusedrockres =1;
uniform float plants1res =1;

void fragment() {
vec3 mosscolor;
vec3 fusedrockcolor;
vec3 plants1color;
vec3 FGU_Ground_Splatmapcolor;

FGU_Ground_Splatmapcolor = texture(FGU_Ground_Splatmap, UV).rgb;

mosscolor = texture(moss, UV * mossres).rgb * FGU_Ground_Splatmapcolor.r;
fusedrockcolor = texture(fusedrock, UV * fusedrockres).rgb * FGU_Ground_Splatmapcolor.g;
plants1color = texture(plants1, UV * plants1res).rgb * FGU_Ground_Splatmapcolor.b;

ALBEDO = mosscolor + fusedrockcolor + plants1color;
}