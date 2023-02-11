#pragma once

#include <neutron/elemental.h>
#include <neutron/graphics/shader.h>

/**
 * SECTION: shader-program
 * @title: Shader Program
 * @short_description: Shader program API
 */

/**
 * NtShaderProgram:
 * @instance: The %NtTypeInstance associated with this
 * @attach: Method for attaching a shader to the program
 * @detach: Method for detaching a shader from the program
 * @link: Method for linking the shaders
 * @get_binary: Method for getting the binary data of the shader
 *
 * A shader program
 */
typedef struct _NtShaderProgram {
  NtTypeInstance instance;

  bool (*attach)(struct _NtShaderProgram* self, NtShader* shader);
  bool (*detach)(struct _NtShaderProgram* self, NtShader* shader);
  bool (*link)(struct _NtShaderProgram* self);
  void* (*get_binary)(struct _NtShaderProgram* self, size_t* len);
} NtShaderProgram;

NT_BEGIN_DECLS

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#elif defined(__clang__)
#pragma clang visibility push(default)
#endif

/**
 * NT_TYPE_SHADER_PROGRAM:
 *
 * The %NtType for %NtShaderProgram
 */
#define NT_TYPE_SHADER_PROGRAM nt_shader_program_get_type()
NT_DECLARE_TYPE(NT, SHADER_PROGRAM, NtShaderProgram, nt_shader_program);

/**
 * nt_shader_program_attach:
 * @self: Instance of a shader program
 * @shader: The shader to attach
 *
 * Attaches the shader to the program.
 * 
 * Returns: %TRUE if the shader was added, %FALSE if it failed.
 */
bool nt_shader_program_attach(NtShaderProgram* self, NtShader* shader);

/**
 * nt_shader_program_detach:
 * @self: Instance of a shader program
 * @shader: The shader to detach
 *
 * Detaches the shader to the program.
 * 
 * Returns: %TRUE if the shader was removed, %FALSE if it failed.
 */
bool nt_shader_program_detach(NtShaderProgram* self, NtShader* shader);

/**
 * nt_shader_program_link:
 * @self: Instance of a shader program
 *
 * Links all the shaders together which makes the program usable.
 *
 * Returns: %TRUE if the shader program was linked, %FALSE if it failed.
 */
bool nt_shader_program_link(NtShaderProgram* self);

/**
 * nt_shader_program_get_binary:
 * @self: Instance of a shader program
 * @len: Pointer for storing the length
 *
 * Used for getting the binary code of the shader program.
 *
 * Returns: An pointer of the binary
 */
void* nt_shader_program_get_binary(NtShaderProgram* self, size_t* len);

#if defined(__GNUC__)
#pragma GCC visibility pop
#elif defined(__clang__)
#pragma clang visibility pop
#endif

NT_END_DECLS
