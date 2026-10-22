shader_type canvas_item;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	// Chroma-key only pure black pixels so the dark lantern outline remains.
	if (sampled.r < 0.005 && sampled.g < 0.005 && sampled.b < 0.005) {
		discard;
	}
}
