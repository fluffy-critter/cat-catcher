uniform Image fur;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    return color*Texel(texture, tc)*Texel(fur, tc);
}
