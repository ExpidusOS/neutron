// ingore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_name

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;
import 'package:neutron_elemental/bindings.dart' as _imp1;

/// Bindings for Neutron's Graphics API
///
class NeutronGraphics {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NeutronGraphics(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NeutronGraphics.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  late final ffi.Pointer<ffi.Size> _NT_SCENE_SIZE =
      _lookup<ffi.Size>('NT_SCENE_SIZE');

  int get NT_SCENE_SIZE => _NT_SCENE_SIZE.value;

  set NT_SCENE_SIZE(int value) => _NT_SCENE_SIZE.value = value;

  ffi.Pointer<NtScene> NT_SCENE(
    ffi.Pointer<_imp1.NtTypeInstance> instance,
  ) {
    return _NT_SCENE(
      instance,
    );
  }

  late final _NT_SCENEPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<NtScene> Function(
              ffi.Pointer<_imp1.NtTypeInstance>)>>('NT_SCENE');
  late final _NT_SCENE = _NT_SCENEPtr.asFunction<
      ffi.Pointer<NtScene> Function(ffi.Pointer<_imp1.NtTypeInstance>)>();

  bool NT_IS_SCENE(
    ffi.Pointer<NtScene> self,
  ) {
    return _NT_IS_SCENE(
      self,
    );
  }

  late final _NT_IS_SCENEPtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function(ffi.Pointer<NtScene>)>>(
          'NT_IS_SCENE');
  late final _NT_IS_SCENE =
      _NT_IS_SCENEPtr.asFunction<bool Function(ffi.Pointer<NtScene>)>();

  _imp1.NtType nt_scene_get_type() {
    return _nt_scene_get_type();
  }

  late final _nt_scene_get_typePtr =
      _lookup<ffi.NativeFunction<_imp1.NtType Function()>>('nt_scene_get_type');
  late final _nt_scene_get_type =
      _nt_scene_get_typePtr.asFunction<_imp1.NtType Function()>();

  /// nt_scene_new:
  ///
  /// Creates a new scene.
  /// Returns: A new scene.
  ffi.Pointer<NtScene> nt_scene_new() {
    return _nt_scene_new();
  }

  late final _nt_scene_newPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<NtScene> Function()>>(
          'nt_scene_new');
  late final _nt_scene_new =
      _nt_scene_newPtr.asFunction<ffi.Pointer<NtScene> Function()>();

  /// nt_scene_add_layer:
  /// @self: The scene
  /// @renderer: The layer
  ///
  /// Adds the layer into the scene. This does not reference the layer.
  void nt_scene_add_layer(
    ffi.Pointer<NtScene> self,
    ffi.Pointer<_NtSceneLayer> layer,
  ) {
    return _nt_scene_add_layer(
      self,
      layer,
    );
  }

  late final _nt_scene_add_layerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<NtScene>,
              ffi.Pointer<_NtSceneLayer>)>>('nt_scene_add_layer');
  late final _nt_scene_add_layer = _nt_scene_add_layerPtr.asFunction<
      void Function(ffi.Pointer<NtScene>, ffi.Pointer<_NtSceneLayer>)>();

  /// nt_scene_render:
  /// @self: The scene
  /// @renderer: The renderer
  ///
  /// Renders the scene (@self) onto the renderer (@renderer).
  void nt_scene_render(
    ffi.Pointer<NtScene> self,
    ffi.Pointer<_NtRenderer> renderer,
  ) {
    return _nt_scene_render(
      self,
      renderer,
    );
  }

  late final _nt_scene_renderPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<NtScene>,
              ffi.Pointer<_NtRenderer>)>>('nt_scene_render');
  late final _nt_scene_render = _nt_scene_renderPtr.asFunction<
      void Function(ffi.Pointer<NtScene>, ffi.Pointer<_NtRenderer>)>();

  /// nt_scene_clean:
  /// @self: The scene
  ///
  /// Cleans the scene's layers
  void nt_scene_clean(
    ffi.Pointer<NtScene> self,
  ) {
    return _nt_scene_clean(
      self,
    );
  }

  late final _nt_scene_cleanPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NtScene>)>>(
          'nt_scene_clean');
  late final _nt_scene_clean =
      _nt_scene_cleanPtr.asFunction<void Function(ffi.Pointer<NtScene>)>();

  late final ffi.Pointer<ffi.Size> _NT_SCENE_LAYER_SIZE =
      _lookup<ffi.Size>('NT_SCENE_LAYER_SIZE');

  int get NT_SCENE_LAYER_SIZE => _NT_SCENE_LAYER_SIZE.value;

  set NT_SCENE_LAYER_SIZE(int value) => _NT_SCENE_LAYER_SIZE.value = value;

  ffi.Pointer<NtSceneLayer> NT_SCENE_LAYER(
    ffi.Pointer<_imp1.NtTypeInstance> instance,
  ) {
    return _NT_SCENE_LAYER(
      instance,
    );
  }

  late final _NT_SCENE_LAYERPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<NtSceneLayer> Function(
              ffi.Pointer<_imp1.NtTypeInstance>)>>('NT_SCENE_LAYER');
  late final _NT_SCENE_LAYER = _NT_SCENE_LAYERPtr.asFunction<
      ffi.Pointer<NtSceneLayer> Function(ffi.Pointer<_imp1.NtTypeInstance>)>();

  bool NT_IS_SCENE_LAYER(
    ffi.Pointer<NtSceneLayer> self,
  ) {
    return _NT_IS_SCENE_LAYER(
      self,
    );
  }

  late final _NT_IS_SCENE_LAYERPtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function(ffi.Pointer<NtSceneLayer>)>>(
          'NT_IS_SCENE_LAYER');
  late final _NT_IS_SCENE_LAYER = _NT_IS_SCENE_LAYERPtr.asFunction<
      bool Function(ffi.Pointer<NtSceneLayer>)>();

  _imp1.NtType nt_scene_layer_get_type() {
    return _nt_scene_layer_get_type();
  }

  late final _nt_scene_layer_get_typePtr =
      _lookup<ffi.NativeFunction<_imp1.NtType Function()>>(
          'nt_scene_layer_get_type');
  late final _nt_scene_layer_get_type =
      _nt_scene_layer_get_typePtr.asFunction<_imp1.NtType Function()>();

  /// nt_scene_layer_render:
  /// @self: The scene layer
  /// @renderer: The renderer
  ///
  /// Renders the scene layer (@self) onto the renderer (@renderer)
  void nt_scene_layer_render(
    ffi.Pointer<NtSceneLayer> self,
    ffi.Pointer<_NtRenderer> renderer,
  ) {
    return _nt_scene_layer_render(
      self,
      renderer,
    );
  }

  late final _nt_scene_layer_renderPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<NtSceneLayer>,
              ffi.Pointer<_NtRenderer>)>>('nt_scene_layer_render');
  late final _nt_scene_layer_render = _nt_scene_layer_renderPtr.asFunction<
      void Function(ffi.Pointer<NtSceneLayer>, ffi.Pointer<_NtRenderer>)>();

  /// nt_scene_layer_clean:
  /// @self: The scene layer
  ///
  /// Cleans the scene layers
  void nt_scene_layer_clean(
    ffi.Pointer<NtSceneLayer> self,
  ) {
    return _nt_scene_layer_clean(
      self,
    );
  }

  late final _nt_scene_layer_cleanPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NtSceneLayer>)>>(
          'nt_scene_layer_clean');
  late final _nt_scene_layer_clean = _nt_scene_layer_cleanPtr
      .asFunction<void Function(ffi.Pointer<NtSceneLayer>)>();

  late final ffi.Pointer<ffi.Size> _NT_RENDERER_SIZE =
      _lookup<ffi.Size>('NT_RENDERER_SIZE');

  int get NT_RENDERER_SIZE => _NT_RENDERER_SIZE.value;

  set NT_RENDERER_SIZE(int value) => _NT_RENDERER_SIZE.value = value;

  ffi.Pointer<NtRenderer> NT_RENDERER(
    ffi.Pointer<_imp1.NtTypeInstance> instance,
  ) {
    return _NT_RENDERER(
      instance,
    );
  }

  late final _NT_RENDERERPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<NtRenderer> Function(
              ffi.Pointer<_imp1.NtTypeInstance>)>>('NT_RENDERER');
  late final _NT_RENDERER = _NT_RENDERERPtr.asFunction<
      ffi.Pointer<NtRenderer> Function(ffi.Pointer<_imp1.NtTypeInstance>)>();

  bool NT_IS_RENDERER(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _NT_IS_RENDERER(
      self,
    );
  }

  late final _NT_IS_RENDERERPtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function(ffi.Pointer<NtRenderer>)>>(
          'NT_IS_RENDERER');
  late final _NT_IS_RENDERER =
      _NT_IS_RENDERERPtr.asFunction<bool Function(ffi.Pointer<NtRenderer>)>();

  _imp1.NtType nt_renderer_get_type() {
    return _nt_renderer_get_type();
  }

  late final _nt_renderer_get_typePtr =
      _lookup<ffi.NativeFunction<_imp1.NtType Function()>>(
          'nt_renderer_get_type');
  late final _nt_renderer_get_type =
      _nt_renderer_get_typePtr.asFunction<_imp1.NtType Function()>();

  /// nt_renderer_is_software:
  /// @self: The %NtRenderer instance
  ///
  /// Gets whether or not the renderer is using software or hardware rendering.
  /// Returns: %true if the renderer is software rendering, %false if the renderer is hardware rendering
  bool nt_renderer_is_software(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _nt_renderer_is_software(
      self,
    );
  }

  late final _nt_renderer_is_softwarePtr =
      _lookup<ffi.NativeFunction<ffi.Bool Function(ffi.Pointer<NtRenderer>)>>(
          'nt_renderer_is_software');
  late final _nt_renderer_is_software = _nt_renderer_is_softwarePtr
      .asFunction<bool Function(ffi.Pointer<NtRenderer>)>();

  /// nt_renderer_get_config:
  /// @self: The %NtRenderer instance
  ///
  /// Gets the renderer configuration for Flutter
  /// Returns: A pointer to the renderer configuration
  ffi.Pointer<FlutterRendererConfig> nt_renderer_get_config(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _nt_renderer_get_config(
      self,
    );
  }

  late final _nt_renderer_get_configPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<FlutterRendererConfig> Function(
              ffi.Pointer<NtRenderer>)>>('nt_renderer_get_config');
  late final _nt_renderer_get_config = _nt_renderer_get_configPtr.asFunction<
      ffi.Pointer<FlutterRendererConfig> Function(ffi.Pointer<NtRenderer>)>();

  /// nt_renderer_get_compositor:
  /// @self: The %NtRenderer instance
  ///
  /// Gets the compositor for Flutter
  /// Returns: A pointer to the compositor
  ffi.Pointer<FlutterCompositor> nt_renderer_get_compositor(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _nt_renderer_get_compositor(
      self,
    );
  }

  late final _nt_renderer_get_compositorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<FlutterCompositor> Function(
              ffi.Pointer<NtRenderer>)>>('nt_renderer_get_compositor');
  late final _nt_renderer_get_compositor =
      _nt_renderer_get_compositorPtr.asFunction<
          ffi.Pointer<FlutterCompositor> Function(ffi.Pointer<NtRenderer>)>();

  /// nt_renderer_wait_sync:
  /// @self: The %NtRenderer instance
  ///
  /// Causes the renderer to wait for any synchronization action.
  /// Use this before calling %nt_renderer_render.
  void nt_renderer_wait_sync(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _nt_renderer_wait_sync(
      self,
    );
  }

  late final _nt_renderer_wait_syncPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NtRenderer>)>>(
          'nt_renderer_wait_sync');
  late final _nt_renderer_wait_sync = _nt_renderer_wait_syncPtr
      .asFunction<void Function(ffi.Pointer<NtRenderer>)>();

  /// nt_renderer_render:
  /// @self: The %NtRenderer instance
  ///
  /// Causes the renderer to actually render.
  /// This does not use %nt_renderer_wait_sync so be sure to call it first.
  void nt_renderer_render(
    ffi.Pointer<NtRenderer> self,
  ) {
    return _nt_renderer_render(
      self,
    );
  }

  late final _nt_renderer_renderPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NtRenderer>)>>(
          'nt_renderer_render');
  late final _nt_renderer_render = _nt_renderer_renderPtr
      .asFunction<void Function(ffi.Pointer<NtRenderer>)>();
}

/// NtRenderer:
/// @instance: The %NtTypeInstance associated with this
/// @is_software: Method for getting whether or not the renderer is doing software rendering
/// @get_config: Method for getting the renderer configuration for Flutter
/// @get_compositor: Method for getting the compositor for Flutter
/// @wait_sync: Method for causing the renderer to wait for synchronization
/// @render: Method for causing the renderer to perform the rendering action
/// @pre_render: Signal triggered before rendering begins
/// @post_render: Signal triggered once rendering is done
///
/// Base type for a renderer
class _NtRenderer extends ffi.Struct {
  external _imp1.NtTypeInstance instance;

  external ffi.Pointer<
          ffi.NativeFunction<ffi.Bool Function(ffi.Pointer<_NtRenderer>)>>
      is_software;

  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Pointer<FlutterRendererConfig> Function(
              ffi.Pointer<_NtRenderer>)>> get_config;

  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Pointer<FlutterCompositor> Function(
              ffi.Pointer<_NtRenderer>)>> get_compositor;

  external ffi.Pointer<
          ffi.NativeFunction<ffi.Void Function(ffi.Pointer<_NtRenderer>)>>
      wait_sync;

  external ffi.Pointer<
      ffi.NativeFunction<ffi.Void Function(ffi.Pointer<_NtRenderer>)>> render;

  external ffi.Pointer<_imp1.NtSignal> pre_render;

  external ffi.Pointer<_imp1.NtSignal> post_render;

  /// < private >
  external ffi.Pointer<_NtRendererPrivate> priv;
}

class FlutterRendererConfig extends ffi.Struct {
  @ffi.Int32()
  external int type;
}

abstract class FlutterRendererType {
  static const int kOpenGL = 0;
  static const int kSoftware = 1;

  /// Metal is only supported on Darwin platforms (macOS / iOS).
  /// iOS version >= 10.0 (device), 13.0 (simulator)
  /// macOS version >= 10.14
  static const int kMetal = 2;
  static const int kVulkan = 3;
}

class FlutterCompositor extends ffi.Struct {
  /// This size of this struct. Must be sizeof(FlutterCompositor).
  @ffi.Size()
  external int struct_size;

  /// A baton that in not interpreted by the engine in any way. If it passed
  /// back to the embedder in `FlutterCompositor.create_backing_store_callback`,
  /// `FlutterCompositor.collect_backing_store_callback` and
  /// `FlutterCompositor.present_layers_callback`
  external ffi.Pointer<ffi.Void> user_data;

  /// A callback invoked by the engine to obtain a backing store for a specific
  /// `FlutterLayer`.
  ///
  /// On ABI stability: Callers must take care to restrict access within
  /// `FlutterBackingStore::struct_size` when specifying a new backing store to
  /// the engine. This only matters if the embedder expects to be used with
  /// engines older than the version whose headers it used during compilation.
  external FlutterBackingStoreCreateCallback create_backing_store_callback;

  /// A callback invoked by the engine to release the backing store. The
  /// embedder may collect any resources associated with the backing store.
  external FlutterBackingStoreCollectCallback collect_backing_store_callback;

  /// Callback invoked by the engine to composite the contents of each layer
  /// onto the screen.
  external FlutterLayersPresentCallback present_layers_callback;

  /// Avoid caching backing stores provided by this compositor.
  @ffi.Bool()
  external bool avoid_backing_store_cache;
}

typedef FlutterBackingStoreCreateCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Bool Function(ffi.Pointer<FlutterBackingStoreConfig>,
            ffi.Pointer<FlutterBackingStore>, ffi.Pointer<ffi.Void>)>>;

class FlutterBackingStoreConfig extends ffi.Struct {
  /// The size of this struct. Must be sizeof(FlutterBackingStoreConfig).
  @ffi.Size()
  external int struct_size;

  /// The size of the render target the engine expects to render into.
  external FlutterSize size;
}

/// A structure to represent the width and height.
class FlutterSize extends ffi.Struct {
  @ffi.Double()
  external double width;

  @ffi.Double()
  external double height;
}

class FlutterBackingStore extends ffi.Struct {
  /// The size of this struct. Must be sizeof(FlutterBackingStore).
  @ffi.Size()
  external int struct_size;

  /// A baton that is not interpreted by the engine in any way. The embedder may
  /// use this to associate resources that are tied to the lifecycle of the
  /// `FlutterBackingStore`.
  external ffi.Pointer<ffi.Void> user_data;

  /// Specifies the type of backing store.
  @ffi.Int32()
  external int type;

  /// Indicates if this backing store was updated since the last time it was
  /// associated with a presented layer.
  @ffi.Bool()
  external bool did_update;
}

abstract class FlutterBackingStoreType {
  /// Specifies an OpenGL backing store. Can either be an OpenGL texture or
  /// framebuffer.
  static const int kFlutterBackingStoreTypeOpenGL = 0;

  /// Specified an software allocation for Flutter to render into using the CPU.
  static const int kFlutterBackingStoreTypeSoftware = 1;

  /// Specifies a Metal backing store. This is backed by a Metal texture.
  static const int kFlutterBackingStoreTypeMetal = 2;

  /// Specifies a Vulkan backing store. This is backed by a Vulkan VkImage.
  static const int kFlutterBackingStoreTypeVulkan = 3;
}

typedef FlutterBackingStoreCollectCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Bool Function(
            ffi.Pointer<FlutterBackingStore>, ffi.Pointer<ffi.Void>)>>;
typedef FlutterLayersPresentCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Bool Function(ffi.Pointer<ffi.Pointer<FlutterLayer>>, ffi.Size,
            ffi.Pointer<ffi.Void>)>>;

class FlutterLayer extends ffi.Struct {
  /// This size of this struct. Must be sizeof(FlutterLayer).
  @ffi.Size()
  external int struct_size;

  /// Each layer displays contents in one way or another. The type indicates
  /// whether those contents are specified by Flutter or the embedder.
  @ffi.Int32()
  external int type;

  /// The offset of this layer (in physical pixels) relative to the top left of
  /// the root surface used by the engine.
  external FlutterPoint offset;

  /// The size of the layer (in physical pixels).
  external FlutterSize size;
}

abstract class FlutterLayerContentType {
  /// Indicates that the contents of this layer are rendered by Flutter into a
  /// backing store.
  static const int kFlutterLayerContentTypeBackingStore = 0;

  /// Indicates that the contents of this layer are determined by the embedder.
  static const int kFlutterLayerContentTypePlatformView = 1;
}

/// A structure to represent a 2D point.
class FlutterPoint extends ffi.Struct {
  @ffi.Double()
  external double x;

  @ffi.Double()
  external double y;
}

class _NtRendererPrivate extends ffi.Opaque {}

/// NtSceneLayer:
/// @instance: The %NtTypeInstance associated with this
/// @render: Method for rendering
/// @clean: Method for cleaning
/// @priv: Private data
///
/// A layer in a scene for rendering
class _NtSceneLayer extends ffi.Struct {
  external _imp1.NtTypeInstance instance;

  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<_NtSceneLayer>, ffi.Pointer<_NtRenderer>)>> render;

  external ffi.Pointer<
      ffi.NativeFunction<ffi.Void Function(ffi.Pointer<_NtSceneLayer>)>> clean;

  /// < private >
  external ffi.Pointer<_NtSceneLayerPrivate> priv;
}

class _NtSceneLayerPrivate extends ffi.Opaque {}

/// NtScene:
/// @instance: The %NtTypeInstance associated with this
/// @priv: Private data
///
/// Scene for rendering layers
class _NtScene extends ffi.Struct {
  external _imp1.NtTypeInstance instance;

  /// < private >
  external ffi.Pointer<_NtScenePrivate> priv;
}

class _NtScenePrivate extends ffi.Opaque {}

/// NtScene:
/// @instance: The %NtTypeInstance associated with this
/// @priv: Private data
///
/// Scene for rendering layers
typedef NtScene = _NtScene;

/// NtSceneLayer:
/// @instance: The %NtTypeInstance associated with this
/// @render: Method for rendering
/// @clean: Method for cleaning
/// @priv: Private data
///
/// A layer in a scene for rendering
typedef NtSceneLayer = _NtSceneLayer;

/// NtRenderer:
/// @instance: The %NtTypeInstance associated with this
/// @is_software: Method for getting whether or not the renderer is doing software rendering
/// @get_config: Method for getting the renderer configuration for Flutter
/// @get_compositor: Method for getting the compositor for Flutter
/// @wait_sync: Method for causing the renderer to wait for synchronization
/// @render: Method for causing the renderer to perform the rendering action
/// @pre_render: Signal triggered before rendering begins
/// @post_render: Signal triggered once rendering is done
///
/// Base type for a renderer
typedef NtRenderer = _NtRenderer;