shader_type canvas_item;

uniform float strength = 0.0;
uniform float a = 1.0;
uniform vec4 tint : source_color = vec4(1, 1, 1, 1);

void fragment() {
	COLOR += vec4(strength, strength, strength, 0);
	COLOR.a *= a;
	COLOR *= tint;
}
