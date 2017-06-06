#version 410 core

// =============================================================================
// -- Defines ------------------------------------------------------------------
// =============================================================================

// Defines for offsets in gl_TessLevelOuter
#define U0 0
#define V0 1
#define W0 2

// Defines for level array offsets
#define MinLevel 0
#define MaxLevel 1
#define NUM_LEVELS 2

// Defines for vertex coord array offsets
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

// Defines for heuristics array offsets
// Should be the same in TessellationHeurstic.h!
#define FixedLevels 0
#define ScreenSpaceNormal 1
#define ScreenProjection 2
#define Curvature 3
#define MaxDeviation 4
// CombinedMethods
#define MinProjectionCurvature 5
#define NUM_HEURISTICS 6

// =============================================================================
// -- In and outputs -----------------------------------------------------------
// =============================================================================

layout(vertices = NUM_CONTROL_POINTS) out;

in vec4 vert_coord_CS_in[];
in vec4 model_coord_CS_in[];

out vec4 vert_coord_ES_in[];
patch out vec3 patch_color_ES_in;
patch out float patch_curvature_ES_in;

// =============================================================================
// -- Uniforms -----------------------------------------------------------------
// =============================================================================

/// Contains the minimum and maximum tessellation levels
uniform int TessLevels[NUM_LEVELS];

uniform int EdgeHeuristic;

uniform int FaceHeuristic;

// --- Tolerances --------------------------------------------------------------
uniform float ProjectionTolerance;

uniform float DeviationTolerance;

// --- Common OpenGL uniforms --------------------------------------------------

uniform mat4 ProjectionMatrix;
uniform int Width;
uniform int Height;

// =============================================================================
// -- Functions ----------------------------------------------------------------
// =============================================================================

// --- Utility functions -------------------------------------------------------

/// Projects Weighted coordiantes to 3D coordinates
vec3 stripWeight(in vec4 homogeneous) {
  return homogeneous.xyz / homogeneous.w;
}

/// Generates a random number from a vec2
float rand(in vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

/// Sums the square of each component
float sumSqr3(in vec3 v) {
  return v.x * v.x + v.y * v.y + v.z * v.z;
}

/// Returns a random color based on the PrimitiveID
vec3 randomColor() {
  vec3 c = vec3(0);
  c.r = rand(vec2(gl_PrimitiveID, gl_PrimitiveID + 1));
  c.g = rand(vec2(gl_PrimitiveID + 2, gl_PrimitiveID + 3));
  c.b = rand(vec2(gl_PrimitiveID + 4, gl_PrimitiveID + 5));
  return c;
}

/// Interpolate three vec4 with Barycentric coordinates uvw
vec4 interpolate4DUVW(
    in vec3 uvw,
    in vec4 v0,
    in vec4 v1,
    in vec4 v2) {
  return uvw.z * v0 + uvw.x * v1 + uvw.y * v2;
}

// --- Tessellation heuristic helper functions ---------------------------------

/// Determines maximum deviation from the edge
/// Ported from C++ code (TODO: add class and function name)
float maxEdgeDeviation(
    in vec3 v0,
    in vec3 v1,
    in vec3 v2,
    in vec3 v3) {
  vec3 dxyz = v3 - v0;
  float U0NormSqr = 1.0 / sumSqr3(dxyz);
  vec3 p1 = v1 - v0;
  vec3 d1 = cross(dxyz, p1);
  float d1Sqr = sumSqr3(d1);
  vec3 p2 = v2 - v0;
  vec3 d2 = cross(dxyz, p2);
  float d2Sqr = sumSqr3(d2);
  return sqrt(max(d1Sqr, d2Sqr) * U0NormSqr);
}

/// Interpolate tangent at the given t
vec3 interpolateTangent(
    in float t,
    in vec4 v0,
    in vec4 e0,
    in vec4 e1,
    in vec4 v1) {
  vec4 A = mix(v0, e0, t);
  vec4 B = mix(e0, e1, t);
  vec4 C = mix(e1, v1, t);

  vec4 a = mix(A, B, t);
  vec4 b = mix(B, C, t);

  vec3 aw = stripWeight(a);
  vec3 bw = stripWeight(b);

  return normalize(bw - aw);
}

/// Interpolate normal at the given barycentric coordinate
vec3 interpolateNormal(in vec3 uvw) {
  // Cubic to quadratic triangle
  vec4 A = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV003],
        vert_coord_CS_in[UV102],
        vert_coord_CS_in[UV012]);
  vec4 B = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV102],
        vert_coord_CS_in[UV201],
        vert_coord_CS_in[UV111]);
  vec4 C = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV201],
        vert_coord_CS_in[UV300],
        vert_coord_CS_in[UV210]);
  vec4 D = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV012],
        vert_coord_CS_in[UV111],
        vert_coord_CS_in[UV021]);
  vec4 E = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV111],
        vert_coord_CS_in[UV210],
        vert_coord_CS_in[UV120]);
  vec4 F = interpolate4DUVW(uvw,
        vert_coord_CS_in[UV021],
        vert_coord_CS_in[UV120],
        vert_coord_CS_in[UV030]);

  // Quadratic to linear triangle
  vec4 a = interpolate4DUVW(uvw, A, B, D);
  vec4 b = interpolate4DUVW(uvw, B, C, E);
  vec4 c = interpolate4DUVW(uvw, D, E, F);

  // Linear triangle
  vec3 aw = a.xyz / a.w;
  vec3 bw = b.xyz / b.w;
  vec3 cw = c.xyz / c.w;
  vec3 ab = normalize(bw - aw);
  vec3 ac = normalize(cw - aw);
  return normalize(cross(ab, ac));
}

float calculateCurvature(in vec3 N) {

  // FIXME: this is not correct

  // Calculate normals at the centers of the subtriangles
  //vec3 n0 = interpolateNormal(vec3(1.0 / 9.0, 1.0 / 9.0, 7.0 / 9.0));
  //vec3 n1 = interpolateNormal(vec3(4.0 / 9.0, 1.0 / 9.0, 5.0 / 9.0));
  //vec3 n2 = interpolateNormal(vec3(7.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0));
  //vec3 n3 = interpolateNormal(vec3(2.0 / 9.0, 2.0 / 9.0, 5.0 / 9.0));
  //vec3 n4 = interpolateNormal(vec3(5.0 / 9.0, 2.0 / 9.0, 2.0 / 9.0));
  //vec3 n5 = interpolateNormal(vec3(1.0 / 9.0, 4.0 / 9.0, 4.0 / 9.0));
  //vec3 n6 = interpolateNormal(vec3(4.0 / 9.0, 4.0 / 9.0, 1.0 / 9.0));
  //vec3 n7 = interpolateNormal(vec3(2.0 / 9.0, 5.0 / 9.0, 2.0 / 9.0));
  //vec3 n8 = interpolateNormal(vec3(1.0 / 9.0, 7.0 / 9.0, 1.0 / 9.0));

  // Calculate normals at the corners, the center and center of edges
  vec3 n0 = interpolateNormal(vec3(0, 0, 1)); // B003
  vec3 n1 = interpolateNormal(vec3(1, 0, 0)); // B300
  vec3 n2 = interpolateNormal(vec3(0, 1, 0)); // B030

  vec3 n3 = interpolateNormal(vec3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)); // B111

  vec3 n4 = interpolateNormal(vec3(0.5, 0, 0.5)); // V0
  vec3 n5 = interpolateNormal(vec3(0.5, 0.5, 0.0)); // W0
  vec3 n6 = interpolateNormal(vec3(0.0, 0.5, 0.5)); // U0

  // Determine maximum deviation of the normal
  float f0 = dot(n0, N);
  float f1 = min(dot(n1, N), f0);
  float f2 = min(dot(n2, N), f1);
  float f3 = min(dot(n3, N), f2);
  float f4 = min(dot(n4, N), f3);
  float f5 = min(dot(n5, N), f4);
  float f6 = min(dot(n6, N), f5);
  //float f7 = min(dot(n7, N), f6);
  //float f8 = min(dot(n8, N), f7);

  return f6;
}

// --- Tessellation heuristic functions ----------------------------------------

/// Calculate edge tessellation level using the max deviation heuristic
float maxDeviationEdge(
    in vec4 v0,
    in vec4 v1,
    in vec4 v2,
    in vec4 v3) {
  float deviation = maxEdgeDeviation(
        stripWeight(v0),
        stripWeight(v1),
        stripWeight(v2),
        stripWeight(v3));
  return clamp(
      deviation / DeviationTolerance,
      TessLevels[MinLevel],
      TessLevels[MaxLevel]);
}

// TODO: find something for faces and deviation...

/// Calculate edge tessellation level using the Curvature heuristic
///
/// Determines maximum deviation of tangent compared to the
/// tangent of the edge endpoints
float curvatureEdge(
    in vec4 v0,
    in vec4 e0,
    in vec4 e1,
    in vec4 v1) {

  // Calculate tangent of the whole edge
  vec3 T = normalize(stripWeight(v1) - stripWeight(v0));

  // Calculate tangents in between
  vec3 t0 = interpolateTangent(0.0 / 6.0, v0, e0, e1, v1);
  vec3 t1 = interpolateTangent(2.0 / 6.0, v0, e0, e1, v1);
  vec3 t2 = interpolateTangent(3.0 / 6.0, v0, e0, e1, v1);
  vec3 t3 = interpolateTangent(4.0 / 6.0, v0, e0, e1, v1);
  vec3 t4 = interpolateTangent(6.0 / 6.0, v0, e0, e1, v1);

  // Find the most divergent tangent
  float f0 = dot(t0, T);
  float f1 = min(dot(t1, T), f0);
  float f2 = min(dot(t2, T), f1);
  float f3 = min(dot(t3, T), f2);
  float f4 = min(dot(t4, T), f3);

  // Cubic root is used for faster curve
  float factor = pow(1 - clamp(f4, 0.0, 1.0), 1.0 / 3.0);
  return mix(
      TessLevels[MinLevel],
      TessLevels[MaxLevel],
      factor);
}

/// Calculate face tessellation level, using curvature heuristic
///
/// Curvature is determines by comparing the interpolated normal
/// at using barycentric coordaintes from the centers of the nine
/// subtriangles that make up the control net for rational bezier
/// triangles
float curvatureFace(in vec3 N, in float curvature) {
  // Use a cubic root for a faster curve
  float factor = pow(1 - clamp(curvature, 0.0, 1.0), 1.0 / 3.0);
  return mix(
      TessLevels[MinLevel],
      TessLevels[MaxLevel],
      factor);
}

/// Calculate the face tessellation level using the
/// screen space normal heuristic
float screenSpaceNormalFace(in vec3 N) {

  vec3 v0 = stripWeight(vert_coord_CS_in[UV003]);
  vec3 v1 = stripWeight(vert_coord_CS_in[UV300]);
  vec3 v2 = stripWeight(vert_coord_CS_in[UV030]);

  vec3 vc = (v0+v1+v2)/3.0;
  vec3 vn = normalize(-vc);

  float normalDeviation = calculateCurvature(vn);
  float factor = pow(1 - clamp(normalDeviation, 0.0, 1.0), 1.0 / 3.0);
  return mix(
      TessLevels[MinLevel],
      TessLevels[MaxLevel],
      factor);
}

/// Calculate the edge tessellation level using the screen
/// projection heuristic
float screenProjectionEdge(in vec4 v0, in vec4 e0, in vec4 e1, in vec4 v1) {
  // Project to screen
  vec2 WH = vec2(Width, Height);

  vec4 vp0 = ProjectionMatrix * vec4(stripWeight(v0), 1.0);
  vec2 vn0 = (vp0.xy / vp0.w) * WH;

  vec4 ep0 = ProjectionMatrix * vec4(stripWeight(e0), 1.0);
  vec2 en0 = (ep0.xy / ep0.w) * WH;

  vec4 ep1 = ProjectionMatrix * vec4(stripWeight(e1), 1.0);
  vec2 en1 = (ep1.xy / ep1.w) * WH;

  vec4 vp1 = ProjectionMatrix * vec4(stripWeight(v1), 1.0);
  vec2 vn1 = (vp1.xy / vp1.w) * WH;

  // Sum the distance
  float d = distance(vn0, en0);
  d += distance(en0, en1);
  d += distance(en1, vn1);

  // Divide by 2 since the distance is doubled
  return clamp(
      d / (2 * ProjectionTolerance),
      TessLevels[MinLevel],
      TessLevels[MaxLevel]);
}

/// Takes the maximum of all projected edges
float screenProjectionFace() {
  // TODO check for edge heuristic == ScreenProjection
  // Can take the max from the outer levels instead
  float d0 = screenProjectionEdge(
        vert_coord_CS_in[UV003],
        vert_coord_CS_in[UV012],
        vert_coord_CS_in[UV021],
        vert_coord_CS_in[UV030]);
  float d1 = screenProjectionEdge(
        vert_coord_CS_in[UV003],
        vert_coord_CS_in[UV102],
        vert_coord_CS_in[UV201],
        vert_coord_CS_in[UV300]);
  float d2 = screenProjectionEdge(
        vert_coord_CS_in[UV300],
        vert_coord_CS_in[UV210],
        vert_coord_CS_in[UV120],
        vert_coord_CS_in[UV030]);
  return floor(max(max(d0, d1), d2));
}

// =============================================================================
// -- main ---------------------------------------------------------------------
// =============================================================================

void main() {

  // Pass vertex coordinates to the evaluation shader
  vert_coord_ES_in[gl_InvocationID] = vert_coord_CS_in[gl_InvocationID];

  // Allow only proving vertex to set the tessellation levels and color
  if (gl_InvocationID == 0) {
    patch_color_ES_in = randomColor();

    // Calculate the vertex and center points in view coordinates
    vec3 v0 = stripWeight(vert_coord_CS_in[UV003]);
    vec3 v1 = stripWeight(vert_coord_CS_in[UV300]);
    vec3 v2 = stripWeight(vert_coord_CS_in[UV030]);
    vec3 vc = stripWeight(vert_coord_CS_in[UV111]);

    // Calculate the normal of the flat triangle
    vec3 N  = normalize(cross(normalize(v1 - v0), normalize(v2 - v0)));
    float curvature = calculateCurvature(N);
    // transform [1, -1] to [0, 1] (0 no curvature, 1 max, can be > 1)
    patch_curvature_ES_in = pow(clamp((1 - curvature), 0.0, 1.0), 1.0 / 3.0);

    // =========================================================================
    // -- Implementation -------------------------------------------------------
    // =========================================================================

    // --- Fixed Levels --------------------------------------------------------

    if (EdgeHeuristic == FixedLevels) {
      gl_TessLevelOuter[U0] = TessLevels[MaxLevel];
      gl_TessLevelOuter[V0] = TessLevels[MaxLevel];
      gl_TessLevelOuter[W0] = TessLevels[MaxLevel];
    }
    if (FaceHeuristic == FixedLevels) {
      gl_TessLevelInner[0] = TessLevels[MaxLevel];
    }

    // -- ScreenSpaceNormal ----------------------------------------------------

    if (EdgeHeuristic == ScreenSpaceNormal) {
      // TODO: write Edge normal heuristic
      gl_TessLevelOuter[U0] = 1;
      gl_TessLevelOuter[V0] = 1;
      gl_TessLevelOuter[W0] = 1;
    }
    if (FaceHeuristic == ScreenSpaceNormal) {
      gl_TessLevelInner[0] = floor(screenSpaceNormalFace(N));
    }

    // --- ScreenProjection ----------------------------------------------------

    if (EdgeHeuristic == ScreenProjection) {
      gl_TessLevelOuter[U0] = floor(screenProjectionEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV012],
                vert_coord_CS_in[UV021],
                vert_coord_CS_in[UV030]));
      gl_TessLevelOuter[V0] = floor(screenProjectionEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV102],
                vert_coord_CS_in[UV201],
                vert_coord_CS_in[UV300]));
      gl_TessLevelOuter[W0] = floor(screenProjectionEdge(
                vert_coord_CS_in[UV300],
                vert_coord_CS_in[UV210],
                vert_coord_CS_in[UV120],
                vert_coord_CS_in[UV030]));
    }
    if (FaceHeuristic == ScreenProjection) {
      gl_TessLevelInner[0] = floor(screenProjectionFace());
    }

    // --- Curvature -----------------------------------------------------------

    if (EdgeHeuristic == Curvature) {
      gl_TessLevelOuter[U0] = floor(curvatureEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV012],
                vert_coord_CS_in[UV021],
                vert_coord_CS_in[UV030]));
      gl_TessLevelOuter[V0] = floor(curvatureEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV102],
                vert_coord_CS_in[UV201],
                vert_coord_CS_in[UV300]));
      gl_TessLevelOuter[W0] = floor(curvatureEdge(
                vert_coord_CS_in[UV300],
                vert_coord_CS_in[UV210],
                vert_coord_CS_in[UV120],
                vert_coord_CS_in[UV030]));
    }
    if (FaceHeuristic == Curvature) {
      gl_TessLevelInner[0] = floor(curvatureFace(N, curvature));
    }

    // --- MaxDeviation --------------------------------------------------------

    if (EdgeHeuristic == MaxDeviation) {
      gl_TessLevelOuter[U0] =  floor(maxDeviationEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV012],
                vert_coord_CS_in[UV021],
                vert_coord_CS_in[UV030]));
      gl_TessLevelOuter[V0] = floor(maxDeviationEdge(
                vert_coord_CS_in[UV003],
                vert_coord_CS_in[UV102],
                vert_coord_CS_in[UV201],
                vert_coord_CS_in[UV300]));
      gl_TessLevelOuter[W0] = floor(maxDeviationEdge(
                vert_coord_CS_in[UV300],
                vert_coord_CS_in[UV210],
                vert_coord_CS_in[UV120],
                vert_coord_CS_in[UV030]));
    }
    if (FaceHeuristic == MaxDeviation) {
      // TODO: find face MaxDev
      gl_TessLevelInner[0] = 1;
    }

    // =========================================================================
    // -- Combined heuristics --------------------------------------------------
    // =========================================================================

    // --- min(ScreenProjection,Curvature) -------------------------------------

    if (EdgeHeuristic == MinProjectionCurvature) {
      gl_TessLevelOuter[U0] = min(
            floor(curvatureEdge(
                    vert_coord_CS_in[UV003],
                    vert_coord_CS_in[UV012],
                    vert_coord_CS_in[UV021],
                    vert_coord_CS_in[UV030])),
            floor(screenProjectionEdge(
                    vert_coord_CS_in[UV003],
                    vert_coord_CS_in[UV012],
                    vert_coord_CS_in[UV021],
                    vert_coord_CS_in[UV030])));
      gl_TessLevelOuter[V0] = min(
            floor(curvatureEdge(
                    vert_coord_CS_in[UV003],
                    vert_coord_CS_in[UV102],
                    vert_coord_CS_in[UV201],
                    vert_coord_CS_in[UV300])),
            floor(screenProjectionEdge(
                    vert_coord_CS_in[UV003],
                    vert_coord_CS_in[UV102],
                    vert_coord_CS_in[UV201],
                    vert_coord_CS_in[UV300])));
      gl_TessLevelOuter[W0] = min(
            floor(curvatureEdge(
                    vert_coord_CS_in[UV300],
                    vert_coord_CS_in[UV210],
                    vert_coord_CS_in[UV120],
                    vert_coord_CS_in[UV030])),
            floor(screenProjectionEdge(
                    vert_coord_CS_in[UV300],
                    vert_coord_CS_in[UV210],
                    vert_coord_CS_in[UV120],
                    vert_coord_CS_in[UV030])));
    }
    if (FaceHeuristic == MinProjectionCurvature) {
      gl_TessLevelInner[0] = min(
            floor(screenProjectionFace()),
            floor(curvatureFace(N, curvature))
            );
    }

  }
}
