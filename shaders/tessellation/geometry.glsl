#version 410 core

// =============================================================================
// -- Defines ------------------------------------------------------------------
// =============================================================================

#define NUM_CONTROL_POINTS 10

// =============================================================================
// -- In and outputs -----------------------------------------------------------
// =============================================================================

// --- Inputs ------------------------------------------------------------------

layout(triangles) in;

in vec3 barycenter_GS_in[];
in vec4 vert_coord_GS_in[];
in vec3 vert_normal_GS_in[];

// --- Flat inputs -------------------------------------------------------------

in vec3 patch_color_GS_in[];

// Needs Interface Block to pass the array of control points
in ControlCoords {
  vec4 control_coord_GS_in[NUM_CONTROL_POINTS];
} controls[];

in float patch_curvature_GS_in[];
in float inner_tess_level_GS_in[];
in float outer_tess_level_GS_in[];
in vec3 patch_normal_GS_in[];

// --- Outputs -----------------------------------------------------------------

// We do not change any vertices, just calculate flat normals and triangle size
layout(triangle_strip, max_vertices = 3) out;

out vec3 barycenter_FS_in;
out vec4 vert_coord_FS_in;
out vec3 vert_normal_FS_in;

// --- Flat outputs ------------------------------------------------------------

flat out vec3 patch_color_FS_in;
flat out vec4 control_coord_FS_in[NUM_CONTROL_POINTS];
flat out float patch_curvature_FS_in;
flat out vec3 flat_normal_FS_in;
flat out float max_triangle_size_FS_in;
flat out float min_triangle_size_FS_in;
flat out float inner_tess_level_FS_in;
flat out float outer_tess_level_FS_in;
flat out float local_curvature_FS_in;

// =============================================================================
// -- Uniforms -----------------------------------------------------------------
// =============================================================================

uniform int Width;
uniform int Height;

// =============================================================================
// -- Functions ----------------------------------------------------------------
// =============================================================================

void emitPerVertex(in int index) {
  gl_Position = gl_in[index].gl_Position;
  barycenter_FS_in = barycenter_GS_in[index];
  vert_coord_FS_in = vert_coord_GS_in[index];
  vert_normal_FS_in = vert_normal_GS_in[index];
  EmitVertex();
}

float distanceProjectedPoints(in vec4 v0, in vec4 v1) {
  vec2 WH = vec2(Width, Height);
  vec2 p0 = (v0.xy / v0.w) * WH;
  vec2 p1 = (v1.xy / v1.w) * WH;
  return distance(p0, p1);
}

// =============================================================================
// -- Implementation -----------------------------------------------------------
// =============================================================================

void main() {

  patch_color_FS_in = patch_color_GS_in[0];
  for (int i = 0; i < NUM_CONTROL_POINTS; ++i) {
    control_coord_FS_in[i] = controls[0].control_coord_GS_in[i];
  }
  patch_curvature_FS_in = patch_curvature_GS_in[0];
  inner_tess_level_FS_in = inner_tess_level_GS_in[0];
  outer_tess_level_FS_in = outer_tess_level_GS_in[0];

  // Calculate the normal

  vec3 n0 = normalize(vert_coord_GS_in[1].xyz - vert_coord_GS_in[0].xyz);
  vec3 n1 = normalize(vert_coord_GS_in[2].xyz - vert_coord_GS_in[0].xyz);

  flat_normal_FS_in = normalize(cross(n0, n1));

  local_curvature_FS_in = (1 - dot(patch_normal_GS_in[0], flat_normal_FS_in)) / 2.0;

  float u0 = distanceProjectedPoints(gl_in[2].gl_Position, gl_in[0].gl_Position);
  float v0 = distanceProjectedPoints(gl_in[1].gl_Position, gl_in[0].gl_Position);
  float w0 = distanceProjectedPoints(gl_in[2].gl_Position, gl_in[1].gl_Position);

  max_triangle_size_FS_in = max(max(u0, v0), w0);
  min_triangle_size_FS_in = min(min(u0, v0), w0);

  emitPerVertex(0);
  emitPerVertex(1);
  emitPerVertex(2);

  EndPrimitive();
}
