shader_type canvas_item;

uniform float time;
uniform float scanline_strength = 0.1;
uniform float noise_strength = 0.02;
uniform float barrel_distortion = 0.15; // increase for stronger effect

void fragment() {
	vec2 uv = UV;

	// Barrel distortion
	vec2 centered_uv = uv * 2.0 - 1.0; // Move UV from [0,1] to [-1,1]
	float r = length(centered_uv);
	centered_uv *= mix(1.0, 1.0 - barrel_distortion, r * r); // distortion based on radius
	uv = centered_uv * 0.5 + 0.5; // Convert back to [0,1]

	// Check if UVs are out of bounds due to distortion
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0); // black edges
		return;
	}

	// Scanlines
	float scanline = sin(uv.y * 800.0) * scanline_strength;

	// Noise
	float noise = fract(sin(dot(uv * time, vec2(12.9898, 78.233))) * 43758.5453) * noise_strength;

	vec4 color = texture(TEXTURE, uv);
	color.rgb += scanline + noise;

	COLOR = color;
}
