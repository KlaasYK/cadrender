#version 450 core

layout (location = 0) in vec4 vert_coord_VS_in;

out VS_DATA {
    vec4 model_coord;
    vec4 view_coord;
    float weight;
} fsin;

uniform mat4 ModelViewMatrix;
uniform mat4 ProjectionMatrix;

void main() {
    fsin.model_coord = vert_coord_VS_in;
    fsin.weight = vert_coord_VS_in.w;

    vec3 vert_coord = vert_coord_VS_in.xyz / vert_coord_VS_in.w;
    fsin.view_coord = ModelViewMatrix * vec4(vert_coord, 1.0);
    gl_Position = ProjectionMatrix * fsin.view_coord;
}
