#version 450 core

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
#define TriangleSize 7
#define InnerTessLevel 8
#define OuterTessLevel 9

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

#define MinTriangleSize 3.0
#define MaxTriangleSize 100.0

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
flat in float triangle_size_FS_in;
flat in float inner_tess_level_FS_in;
flat in float outer_tess_level_FS_in;

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
/// Also can output the normal at the coordinate
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

// =============================================================================
// -- Implementation -----------------------------------------------------------
// =============================================================================

void main() {

  vec3 N;
  // TODO: either select interpolated normal,
  // or evaluate normal
  vec4 temp = evaluateCoord(N);
  vec3 interCoord = temp.xyz;
  float weight = temp.w;

  N = normalize(vert_normal_FS_in);

  // Take pink when functions does not work!
  fColor = vec4(1.0, 0.75, 0.8, 1.0);

  // If statements are allowed for Uniforms
  if (DrawingMode == SmoothShaded) {
    fColor = smoothShaded(ColorFront, ColorBack, N);
  }

  if (DrawingMode == FlatShaded) {
    fColor = smoothShaded(ColorFront, ColorBack, flat_normal_FS_in);
  }

  if (DrawingMode == Normal) {
    fColor = normalColorMap(N);
  }

  if (DrawingMode == PatchesShaded) {
    fColor = smoothShaded(
          patch_color_FS_in,
          0.8 * ColorBack + 0.2 * patch_color_FS_in,
          N);
  }

  if (DrawingMode == Barycentric) {
    fColor = vec4(barycenter_FS_in, 1.0);
  }

  if (DrawingMode == Error) {
    vec3 interpolated = interCoord;
    vec3 dir = normalize(interpolated - vert_coord_FS_in.xyz);
    vec3 N = normalize(N);
    // Only error along the normal should be considered?
    float d = abs(dot(dir, N)) *
      clamp(distance(vert_coord_FS_in.xyz, interpolated) / 0.01, 0.0, 1.0);
    // TODO: determine limit (now 0.1)
    fColor = vec4(rainbowMap(d), 1.0);
  }

  if (DrawingMode == Curvature) {
    // Curvature
    fColor = vec4(rainbowMap(patch_curvature_FS_in), 1.0);
  }

  if (DrawingMode == TriangleSize) {
    float RANGE = (MaxTriangleSize - MinTriangleSize);
    float offset = (triangle_size_FS_in - MinTriangleSize);
    // Invert the clamp (blue is large, red is small)
    float val = 1 - clamp( offset / RANGE, 0.0, 1.0);
    fColor = vec4(rainbowMap(val), 1.0);
  }

  if (DrawingMode == InnerTessLevel) {
    float RANGE = (TessLevels[MaxLevel] - TessLevels[MinLevel]);
    float offset = (inner_tess_level_FS_in - TessLevels[MinLevel]);
    float val = clamp( offset / RANGE, 0.0, 1.0);
    fColor = vec4(rainbowMap(val), 1.0);
  }

  if (DrawingMode == OuterTessLevel) {
    float RANGE = (TessLevels[MaxLevel] - TessLevels[MinLevel]);
    float offset = (outer_tess_level_FS_in - TessLevels[MinLevel]);
    float val = clamp( offset / RANGE, 0.0, 1.0);
    fColor = vec4(rainbowMap(val), 1.0);
  }

}
