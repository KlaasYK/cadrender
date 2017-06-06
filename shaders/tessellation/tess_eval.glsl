#version 410 core

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
out vec3 patch_normal_GS_in;

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

/// Interpolate three vec4 with Barycentric coordinates uvw
vec4 interpolate4DUVW(
    in vec3 uvw,
    in vec4 v0,
    in vec4 v1,
    in vec4 v2) {
  return uvw.z * v0 + uvw.x * v1 + uvw.y * v2;
}

/// Determine barycentric coordinates for  with a, b, c
/// Uses Cramers Rule for solving linear systems
//    b                   c
//   / \                 / \
//  /   \               /   \
// a --- c while I use a --- b
vec3 calculateBarycenter(in vec4 p, in vec4 a, in vec4 c, in vec4 b) {
  vec4 v0 = b - a;
  vec4 v1 = c - a;
  vec4 v2 = p - a;
  float d00 = dot(v0, v0);
  float d01 = dot(v0, v1);
  float d11 = dot(v1, v1);
  float d20 = dot(v2, v0);
  float d21 = dot(v2, v1);
  float denom = d00 * d11 - d01 * d01;
  float v = (d11 * d20 - d01 * d21) / denom;
  float w = (d00 * d21 - d01 * d20) / denom;
  float u = 1.0f - v - w;
  return vec3(u, v, w);
}

vec3 projectTo3D(in vec4 v0) {
  return v0.xyz / v0.w;
}

// =============================================================================
// -- main ---------------------------------------------------------------------
// =============================================================================

void main() {
  // Pass control points to the fragment shader
  for (int i = 0; i < NUM_CONTROL_POINTS; i++) {
    control_coord_GS_in[i] = vert_coord_ES_in[i];
  }

  patch_color_GS_in = patch_color_ES_in;
  patch_curvature_GS_in = patch_curvature_ES_in;

  inner_tess_level_GS_in = gl_TessLevelInner[0];
  outer_tess_level_GS_in = max(
        max(gl_TessLevelOuter[0], gl_TessLevelOuter[1]),
        gl_TessLevelOuter[2]);

  vec3 uvw = gl_TessCoord.xyz;
  barycenter_GS_in = uvw;

  vec3 tangent = normalize(
        projectTo3D(vert_coord_ES_in[UV030]) - projectTo3D(vert_coord_ES_in[UV003])
        );
  vec3 bitangent = normalize(
        projectTo3D(vert_coord_ES_in[UV300]) - projectTo3D(vert_coord_ES_in[UV003])
        );

  patch_normal_GS_in = normalize(cross(bitangent, tangent));

  if (distance(vert_coord_ES_in[UV030], vert_coord_ES_in[UV111]) < 0.00001) {
    // Triangle contains singularity (cones)

    float u = clamp(uvw.x / (1 - uvw.y), 0.0, 1.0);

    vec3 top = projectTo3D(vert_coord_ES_in[UV030]);
    vec3 left = projectTo3D(vert_coord_ES_in[UV003]);
    vec3 leftTangent = projectTo3D(vert_coord_ES_in[UV102]);
    vec3 right = projectTo3D(vert_coord_ES_in[UV300]);
    vec3 rightTangent = projectTo3D(vert_coord_ES_in[UV201]);

    vec3 lto = normalize(top - left);
    vec3 lta = normalize(leftTangent - left);
    vec3 leftNormal = normalize(cross(lta, lto));
    vec3 rto = normalize(top - right);
    vec3 rta = normalize(rightTangent - right);
    vec3 rightNormal = normalize(cross(rto, rta));

    // Determine point on the bottom of the cone
    vec4 A = mix(vert_coord_ES_in[UV003], vert_coord_ES_in[UV102], u);
    vec4 B = mix(vert_coord_ES_in[UV102], vert_coord_ES_in[UV201], u);
    vec4 C = mix(vert_coord_ES_in[UV201], vert_coord_ES_in[UV300], u);

    vec4 a = mix(A, B, u);
    vec4 b = mix(B, C, u);

    vec4 bottomPoint = mix(a, b, u);
    vec4 resultPoint = mix(bottomPoint, vert_coord_ES_in[UV030], uvw.y);

    vec3 weightedCoord = resultPoint.xyz / resultPoint.w;

    vert_coord_GS_in = vec4(weightedCoord, 1.0);
    gl_Position = ProjectionMatrix * vert_coord_GS_in;

    if (uvw.y > 0.999) {
      vert_normal_GS_in = normalize(cross(
                normalize( right - left),
                normalize(top - left)
                ));
    } else {
      vert_normal_GS_in = normalize(mix(leftNormal, rightNormal, u));
    }
    vert_normal_GS_in = normalize(mix(leftNormal, rightNormal, u));

  } else {
    // Regular tripatch

    // Cubic to quadratic triangle
    vec4 A = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV003],
          vert_coord_ES_in[UV102],
          vert_coord_ES_in[UV012]);
    vec4 B = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV102],
          vert_coord_ES_in[UV201],
          vert_coord_ES_in[UV111]);
    vec4 C = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV201],
          vert_coord_ES_in[UV300],
          vert_coord_ES_in[UV210]);
    vec4 D = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV012],
          vert_coord_ES_in[UV111],
          vert_coord_ES_in[UV021]);
    vec4 E = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV111],
          vert_coord_ES_in[UV210],
          vert_coord_ES_in[UV120]);
    vec4 F = interpolate4DUVW(
          uvw,
          vert_coord_ES_in[UV021],
          vert_coord_ES_in[UV120],
          vert_coord_ES_in[UV030]);

    // Quadratic to linear triangle
    vec4 a = interpolate4DUVW(uvw, A, B, D);
    vec4 b = interpolate4DUVW(uvw, B, C, E);
    vec4 c = interpolate4DUVW(uvw, D, E, F);

    // Final homogeneous coordinates
    vec4 homogeneousCoord = interpolate4DUVW(uvw, a, b, c);
    vec3 weightedCoord = homogeneousCoord.xyz / homogeneousCoord.w;
    vert_coord_GS_in = vec4(weightedCoord, 1.0);
    gl_Position = ProjectionMatrix * vert_coord_GS_in;

    // Calculate normal

    vec3 aw = a.xyz / a.w;
    vec3 bw = b.xyz / b.w;
    vec3 cw = c.xyz / c.w;
    vec3 ab = normalize(bw - aw);
    vec3 ac = normalize(cw - aw);

    vert_normal_GS_in = normalize(cross(ab, ac));
    // Normal for flat triangle will be calculated in the Geometry shader
  }
}
