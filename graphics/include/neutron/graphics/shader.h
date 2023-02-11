#pragma once

#include <neutron/elemental.h>

/**
 * SECTION: shader
 * @title: Shader
 * @short_description: Shader API
 */

/**
 * NtShaderKind:
 * @NT_SHADER_VERT: Vertex shader
 * @NT_SHADER_TESS: Tessellation shader
 * @NT_SHADER_GEOM: Geometry shader
 * @NT_SHADER_FRAG: Fragment shader
 * @NT_SHADER_COMP: Compute shader
 *
 * The different kinds of shader
 */
typedef enum _NtShaderKind {
  NT_SHADER_VERT = 0,
  NT_SHADER_TESS,
  NT_SHADER_GEOM,
  NT_SHADER_FRAG,
  NT_SHADER_COMP
} NtShaderKind;

/**
 * NtShader:
 * @instance: The %NtTypeInstance associated with this
 * @get_kind: Method for getting the kind of shader
 * @get_source: Method for getting the shader code
 * @get_binary: Method for getting the binary code
 *
 * A shader
 */
typedef struct _NtShader {
  NtTypeInstance instance;

  NtShaderKind (*get_kind)(struct _NtShader* self);
  char* (*get_source)(struct _NtShader* self, size_t* len);
  void* (*get_binary)(struct _NtShader* self, size_t* len);
} NtShader;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SHADER:
 *
 * The %NtType for %NtShader
 */
#define NT_TYPE_SHADER nt_shader_get_type()
NT_DECLARE_TYPE(NT, SHADER, NtShader, nt_shader);

/**
 * nt_shader_get_kind:
 * @self: The instance of the shader
 *
 * Used for getting the kind of shader this is.
 *
 * Returns: The kind of shader
 */
NtShaderKind nt_shader_get_kind(NtShader* self);

/**
 * nt_shader_get_source:
 * @self: The instance of the shader
 * @len: Pointer for storing the length
 *
 * Used for getting the source code of the shader.
 *
 * Returns: An allocated string of the shader source code.
 */
char* nt_shader_get_source(NtShader* self, size_t* len);

/**
 * nt_shader_get_binary:
 * @self: The instance of the shader
 * @len: Pointer for storing the length
 *
 * Used for getting the binary code of the shader.
 *
 * Returns: An pointer of the binary
 */
void* nt_shader_get_binary(NtShader* self, size_t* len);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
