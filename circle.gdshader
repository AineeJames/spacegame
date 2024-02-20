shader_type canvas_item;

void fragment() {
	float radius = distance(UV, vec2(0.5));
	
	if (radius < 0.5 && radius > 0.4) {
		COLOR;
	} else {
		discard;
	}
}
