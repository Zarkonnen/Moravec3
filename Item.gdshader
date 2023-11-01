shader_type canvas_item;

uniform float strength = 0.0;

void fragment() {
	COLOR += vec4(strength, strength, strength, 0);
}
