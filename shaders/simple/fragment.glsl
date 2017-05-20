#version 450 core

#define MinWeight 0.5
#define MaxWeight 1.0

in VS_DATA {
    vec4 model_coord;
    vec4 view_coord;
    float weight;
} fsin;

layout(location = 0) out vec4 fColor;

vec3 rainbowMap(in float val) {
    float dx = 0.8;
    float v = (6 - 2 * dx) * clamp(val, 0.0, 1.0) + dx;
    vec3 color;
    color.r = max(0.0, (3-abs(v-4)-abs(v-5)) / 2.0);
    color.g = max(0.0, (4-abs(v-2)-abs(v-4)) / 2.0);
    color.b = max(0.0, (3-abs(v-1)-abs(v-2)) / 2.0);
    return color;
}

void main() {
    float val = (fsin.weight - MinWeight) / (MaxWeight - MinWeight);
    fColor = vec4(rainbowMap(val), 1.0);
}
