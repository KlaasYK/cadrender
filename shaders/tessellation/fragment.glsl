#version 410 core

// =============================================================================
// -- Defines ------------------------------------------------------------------
// =============================================================================

// Defines for level array offsets
#define MinLevel 0
#define MaxLevel 1
#define NUM_LEVELS 2

/// Defines for Drawing Mode
#define SmoothShaded 0
#define FlatShaded 1
#define Normal 2
#define PatchesShaded 3
#define Barycentric 4
#define Error 5
#define Curvature 6
#define MinTriangleSizeMode 7
#define MaxTriangleSizeMode 8
#define InnerTessLevel 9
#define OuterTessLevel 10
#define LocalCurvature 11

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

#define MinTriangleSize 2.0
#define MaxTriangleSize 50.0

// =============================================================================
// -- In and outputs -----------------------------------------------------------
// =============================================================================

// --- Inputs ------------------------------------------------------------------

in vec3 barycenter_FS_in;
in vec4 vert_coord_FS_in;
in vec3 vert_normal_FS_in;

flat in vec3 patch_color_FS_in;
flat in vec3 flat_normal_FS_in;
flat in vec4 control_coord_FS_in[NUM_CONTROL_POINTS];
flat in float patch_curvature_FS_in;
flat in float max_triangle_size_FS_in;
flat in float min_triangle_size_FS_in;
flat in float inner_tess_level_FS_in;
flat in float outer_tess_level_FS_in;
flat in float local_curvature_FS_in;

// --- Outputs -----------------------------------------------------------------

layout(location = 0) out vec4 fColor;

// =============================================================================
// -- Uniforms -----------------------------------------------------------------
// =============================================================================

/// Material properties
/// ambient, diffuse, specular, specular power
uniform vec4 MaterialProps;

/// Front color
uniform vec3 ColorFront;

/// Back color
uniform vec3 ColorBack;

/// Drawing Mode
uniform int DrawingMode;

/// Contains the minimum and maximum tessellation levels
uniform int TessLevels[NUM_LEVELS];

// =============================================================================
// -- Functions ----------------------------------------------------------------
// =============================================================================

// --- Interpolation functions -------------------------------------------------

/// Interpolate three vec4 using barycenter_FS_in
vec4 interpolate4D(in vec4 v0, in vec4 v1, in vec4 v2) {
  return barycenter_FS_in.z * v0 +
         barycenter_FS_in.x * v1 +
         barycenter_FS_in.y * v2;
}

/// Calculate the coordinated if the bezier triangle
/// were to be evaluated at each fragment using barycenter_FS_in
/// Also output the normal at the coordinate
vec4 evaluateCoord(out vec3 interpolatedNormal) {

  // Cubic to quadratic triangle
  vec4 A = interpolate4D(
        control_coord_FS_in[UV003],
        control_coord_FS_in[UV102],
        control_coord_FS_in[UV012]);
  vec4 B = interpolate4D(
        control_coord_FS_in[UV102],
        control_coord_FS_in[UV201],
        control_coord_FS_in[UV111]);
  vec4 C = interpolate4D(
        control_coord_FS_in[UV201],
        control_coord_FS_in[UV300],
        control_coord_FS_in[UV210]);
  vec4 D = interpolate4D(
        control_coord_FS_in[UV012],
        control_coord_FS_in[UV111],
        control_coord_FS_in[UV021]);
  vec4 E = interpolate4D(
        control_coord_FS_in[UV111],
        control_coord_FS_in[UV210],
        control_coord_FS_in[UV120]);
  vec4 F = interpolate4D(
        control_coord_FS_in[UV021],
        control_coord_FS_in[UV120],
        control_coord_FS_in[UV030]);

  // Quadratic to linear
  vec4 a = interpolate4D(A, B, D);
  vec4 b = interpolate4D(B, C, E);
  vec4 c = interpolate4D(D, E, F);

  vec3 aw = a.xyz / a.w;
  vec3 bw = b.xyz / b.w;
  vec3 cw = c.xyz / c.w;
  vec3 ab = normalize(bw - aw);
  vec3 ac = normalize(cw - aw);
  interpolatedNormal = normalize(cross(ab, ac));

  // Final homogeneous coordinates
  vec4 homogeneousCoord = interpolate4D(a, b, c);
  return vec4(homogeneousCoord.xyz / homogeneousCoord.w, homogeneousCoord.w);
}

// --- Drawing Modes -----------------------------------------------------------

/// Blinn-Phong Shading with given colors and normals
/// Material properties are read from the uniform
vec4 smoothShaded(in vec3 Front, in vec3 Back, vec3 n) {
  // TODO: these should be set by Uniforms
  vec3 LightPosition = vec3(100.0, 250.0, 1000.0);
  vec3 LightColor = vec3(1.0, 1.0, 1.0);

  vec3 MaterialColor = Front;

  // Retrieve the right normal
  vec3 N = normalize(n);
  if (!gl_FrontFacing) {
    N = -N; // Flip normals on backface
    MaterialColor = Back;
  }

  // Determine lighting vectors
  vec3 L = normalize(LightPosition - vert_coord_FS_in.xyz);
  vec3 E = normalize(-vert_coord_FS_in.xyz);
  vec3 H = normalize(L + E);

  // Calculate Ambient, Diffuse and Specular terms
  vec3 ambient = MaterialColor * MaterialProps.x;
  vec3 diffuse = MaterialColor * MaterialProps.y * clamp(dot(N, L), 0.0, 1.0);
  vec3 specular = LightColor * MaterialProps.z * pow(max(dot(N, H), 0.0), MaterialProps.w);
  return vec4(ambient + diffuse + specular, 1.0);
}

/// Convert the normal to a color value
vec4 normalColorMap(vec3 N) {
  if (!gl_FrontFacing) {
    N = -N; // Flip normals on backface
  }
  return vec4((N + 1.0) / 2.0, 1.0);
}

/// The (in)famous rainbow colormap
vec3 rainbowMap(float val) {
  float dx = 0.8;
  float v = (6 - 2 * dx) * clamp(val, 0.0, 1.0) + dx;
  vec3 color;
  color.r = max(0.0, (3 - abs(v - 4) - abs(v - 5)) / 2.0);
  color.g = max(0.0, (4 - abs(v - 2) - abs(v - 4)) / 2.0);
  color.b = max(0.0, (3 - abs(v - 1) - abs(v - 2)) / 2.0);
  return color;
}

vec3 heatMap(float val) {
  float r = clamp(8.0 / 3.0 * val, 0.0, 1.0);
  float g = clamp(8.0 / 3.0 * val - 1.0, 0.0, 1.0);
  float b = clamp(4.0 * val - 3.0, 0.0, 1.0);
  return vec3(r, g, b);
}

// =============================================================================
// -- Main ---------------------------------------------------------------------
// =============================================================================

void main() {

  vec3 N;
  vec4 temp = evaluateCoord(N);
  vec3 interCoord = temp.xyz;
  vec3 errorDir = normalize(interCoord - vert_coord_FS_in.xyz);
  float weight = temp.w;
  // Use normal passed from the Tess Eval shader
  // TODO: maybe look into a uniform/setting for this
  //N = normalize(vert_normal_FS_in);
  //N = normalize(N);

  float SIZE_RANGE = (MaxTriangleSize - MinTriangleSize);
  float TESS_RANGE = (TessLevels[MaxLevel] - TessLevels[MinLevel]);

  float error;
  float offset;
  float val;

  // Switch based on selected drawingmode;
  switch (DrawingMode) {
    case SmoothShaded:
      fColor = smoothShaded(ColorFront, ColorBack, N);
      break;

    case FlatShaded:
      fColor = smoothShaded(ColorFront, ColorBack, flat_normal_FS_in);
      break;

    case Normal:
      fColor = normalColorMap(N);
      break;

    case PatchesShaded:
      fColor = smoothShaded(
            patch_color_FS_in,
            0.8 * ColorBack + 0.2 * patch_color_FS_in,
            N);
      break;

    case Barycentric:
      fColor = vec4(barycenter_FS_in, 1.0);
      break;

    case Error:
      // Only error along the normal should be considered?
      error = abs(dot(errorDir, N)) *
        clamp(distance(vert_coord_FS_in.xyz, interCoord) / 0.01, 0.0, 1.0);
      // TODO: determine limit (now 0.1)
      fColor = vec4(rainbowMap(error), 1.0);
      break;

    case Curvature:
      fColor = vec4(rainbowMap(patch_curvature_FS_in), 1.0);
      break;

    case MinTriangleSizeMode:
      offset = (min_triangle_size_FS_in - MinTriangleSize);
      // Invert the clamp (blue is large, red is small)
      val = 1 - clamp( offset / SIZE_RANGE, 0.0, 1.0);
      fColor = vec4(rainbowMap(val), 1.0);
      break;

    case MaxTriangleSizeMode:
      offset = (max_triangle_size_FS_in - MinTriangleSize);
      // Invert the clamp (blue is large, red is small)
      val = 1 - clamp( offset / SIZE_RANGE, 0.0, 1.0);
      fColor = vec4(rainbowMap(val), 1.0);
      break;

    case InnerTessLevel:
      offset = (inner_tess_level_FS_in - TessLevels[MinLevel]);
      val = clamp( offset / TESS_RANGE, 0.0, 1.0);
      fColor = vec4(rainbowMap(val), 1.0);
      break;

    case OuterTessLevel:
      offset = (outer_tess_level_FS_in - TessLevels[MinLevel]);
      val = clamp( offset / TESS_RANGE, 0.0, 1.0);
      fColor = vec4(rainbowMap(val), 1.0);
      break;

    case LocalCurvature:
      fColor = vec4(rainbowMap(local_curvature_FS_in), 1.0);
      break;

    default:
      // Default color is pink, in case of uknown drawingmode.
      fColor = vec4(1.0, 0.75, 0.8, 1.0);
      break;

  }

}
