#version 450 core

// =============================================================================
// -- Defines ------------------------------------------------------------------
// =============================================================================

/// Defines for vertex coord array offsets
#define UV003 0
#define UV102 1
#define UV201 2
#define UV300 3
#define UV210 4
#define UV120 5
#define UV030 6
#define UV021 7
#define UV012 8
#define UV111 9
#define NUM_CONTROL_POINTS 10

// =============================================================================
// -- In and outputs -----------------------------------------------------------
// =============================================================================

// --- Inputs ------------------------------------------------------------------

layout(triangles, equal_spacing, ccw) in;

in vec4 vert_coord_ES_in[];
patch in vec3 patch_color_ES_in;
patch in float patch_curvature_ES_in;

// --- Interpolated outputs ----------------------------------------------------

// TODO: create interaface blocks!
// https://www.khronos.org/opengl/wiki/Interface_Block_(GLSL)

out vec3 barycenter_GS_in;
out vec4 vert_coord_GS_in;
out vec3 vert_normal_GS_in;

// --- Flat outputs ------------------------------------------------------------

out vec3 patch_color_GS_in;
out ControlCoords {
  vec4 control_coord_GS_in[NUM_CONTROL_POINTS];
};
out float patch_curvature_GS_in;
out float inner_tess_level_GS_in;
out float outer_tess_level_GS_in;

// =============================================================================
// -- Uniforms -----------------------------------------------------------------
// =============================================================================

// --- Common OpenGL uniforms --------------------------------------------------

uniform mat4 ProjectionMatrix;

uniform mat3 NormalMatrix;

// =============================================================================
// -- Functions ----------------------------------------------------------------
// =============================================================================

/// Interpolate three vec4 using gl_TessCoord
vec4 interpolate4D(in vec4 v0, in vec4 v1, in vec4 v2) {
  return gl_TessCoord.z * v0 + gl_TessCoord.x * v1 + gl_TessCoord.y * v2;
}

// =============================================================================
// -- Implementation -----------------------------------------------------------
// =============================================================================

void main() {
  // Pass control points to the fragment shader
  for (int i = 0; i < NUM_CONTROL_POINTS; i++) {
    control_coord_GS_in[i] = vert_coord_ES_in[i];
  }

  barycenter_GS_in = gl_TessCoord.xyz;
  patch_color_GS_in = patch_color_ES_in;
  patch_curvature_GS_in = patch_curvature_ES_in;

  inner_tess_level_GS_in = gl_TessLevelInner[0];
  outer_tess_level_GS_in = max(
        max(gl_TessLevelOuter[0], gl_TessLevelOuter[1]),
        gl_TessLevelOuter[2]);

  // Cubic to quadratic triangle
  vec4 A = interpolate4D(
        vert_coord_ES_in[UV003],
        vert_coord_ES_in[UV102],
        vert_coord_ES_in[UV012]);
  vec4 B = interpolate4D(
        vert_coord_ES_in[UV102],
        vert_coord_ES_in[UV201],
        vert_coord_ES_in[UV111]);
  vec4 C = interpolate4D(
        vert_coord_ES_in[UV201],
        vert_coord_ES_in[UV300],
        vert_coord_ES_in[UV210]);
  vec4 D = interpolate4D(
        vert_coord_ES_in[UV012],
        vert_coord_ES_in[UV111],
        vert_coord_ES_in[UV021]);
  vec4 E = interpolate4D(
        vert_coord_ES_in[UV111],
        vert_coord_ES_in[UV210],
        vert_coord_ES_in[UV120]);
  vec4 F = interpolate4D(
        vert_coord_ES_in[UV021],
        vert_coord_ES_in[UV120],
        vert_coord_ES_in[UV030]);

  // Quadratic to linear triangle
  vec4 a = interpolate4D(A, B, D);
  vec4 b = interpolate4D(B, C, E);
  vec4 c = interpolate4D(D, E, F);

  // Final homogeneous coordinates
  vec4 homogeneousCoord = interpolate4D(a, b, c);
  vec3 weightedCoord = homogeneousCoord.xyz / homogeneousCoord.w;
  vert_coord_GS_in = vec4(weightedCoord, 1.0);
  gl_Position = ProjectionMatrix * vert_coord_GS_in;

  // Calculate normal
  vec3 aw = a.xyz / a.w;
  vec3 bw = b.xyz / b.w;
  vec3 cw = c.xyz / c.w;
  vec3 ab = normalize(bw - aw);
  vec3 ac = normalize(cw - aw);

  // TODO: remove singularities in C++ code!
  vert_normal_GS_in = normalize(cross(ab, ac));
  // Normal for flat triangle will be calculated in the Geometry shader

}
