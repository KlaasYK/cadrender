#version 410 core

// =============================================================================
// -- In and outputs -----------------------------------------------------------
// =============================================================================

layout(location = 0) in vec4 vert_coord_VS_in;

out vec4 model_coord_CS_in;
out vec4 vert_coord_CS_in;

// =============================================================================
// -- Uniforms -----------------------------------------------------------------
// =============================================================================

uniform mat4 ModelViewMatrix;

// =============================================================================
// -- Implementation -----------------------------------------------------------
// =============================================================================

void main() {
  // Transform weighted coordinates to homogeneous coordinates
  float weight = vert_coord_VS_in.w;
  vec3 weightedCoord = vert_coord_VS_in.xyz / vert_coord_VS_in.w;

  vec4 transformedCoord = ModelViewMatrix * vec4(weightedCoord, 1.0);
  vec3 divided = (transformedCoord.xyz / transformedCoord.w);

  // ... and back
  vec4 homogeneousCoord = vec4(divided * weight, weight);

  // Passthrough model coord
  model_coord_CS_in = vert_coord_VS_in;

  vert_coord_CS_in = homogeneousCoord;
}
