const std = @import("std");
const elemental = @import("../elemental.zig");
const displaykit = @import("../displaykit.zig");
const graphics = @import("../graphics.zig");
const flutter = @import("../flutter.zig");
const ipc = @import("ipc.zig");
const Self = @This();

pub const Mode = enum {
  compositor,
  application,

  pub fn getIpcType(self: Mode) ipc.Type {
    return switch (self) {
      .compositor => .server,
      .application => .client,
    };
  }
};

pub const Params = struct {
  mode: Mode = .application,
  dir: ?[]const u8,
  ipcs: ?[]ipc.Params = null,
  display: ?displaykit.Params = null,
  renderer: ?graphics.renderer.Params = null,
  application_path: []const u8,
};

const Impl = struct {
  pub fn construct(self: *Self, params: Params, t: Type) !void {
    var proc_table: flutter.c.FlutterEngineProcTable = undefined;
    if (flutter.c.FlutterEngineGetProcAddresses(&proc_table) != flutter.c.kSuccess) return error.EngineFail;

    var aot_data: flutter.c.FlutterEngineAOTData = undefined;
    if (proc_table.RunsAOTCompiledDartCode.?()) {
      const aot_source = flutter.c.FlutterEngineAOTDataSource {
        .unnamed_0 = .{
          .elf_path = try std.fs.path.joinZ(t.allocator, &.{
            params.application_path,
            "lib",
            "libapp.so",
          }),
        },
        .type = flutter.c.kFlutterEngineAOTDataSourceTypeElfPath,
      };

      if (flutter.c.FlutterEngineCreateAOTData(&aot_source, &aot_data) != flutter.c.kSuccess) return error.EngineFail;
    }

    self.* = .{
      .type = t,
      .mode = params.mode,
      .dir = try (if (params.dir) |value| t.allocator.dupe(u8, value)
        else (if (std.os.getenv("XDG_RUNTIME_DIR")) |xdg_runtime_dir| t.allocator.dupe(u8, xdg_runtime_dir) else std.process.getCwdAlloc(t.allocator))),
      .ipcs = std.ArrayList(ipc.Ipc).init(t.allocator),
      .displaykit = undefined,
      .engine = undefined,
      .project_args = .{
        .struct_size = @sizeOf(flutter.c.FlutterProjectArgs),
        .icu_data_path = try std.fs.path.joinZ(self.type.allocator, &.{
          params.application_path,
          "data",
          "icudtl.dat",
        }),
        .assets_path = try std.fs.path.joinZ(self.type.allocator, &.{
          params.application_path,
          "data",
          "flutter_assets"
        }),
        .command_line_argc = 0,
        .command_line_argv = null,
        .vsync_callback = null,
        .platform_message_callback = null,
        .log_message_callback = null,
        .log_tag = null,
        .compositor = null,
        .main_path__unused__ = null,
        .packages_path__unused__ = null,
        .vm_snapshot_data = null,
        .vm_snapshot_data_size = 0,
        .vm_snapshot_instructions = null,
        .vm_snapshot_instructions_size = 0,
        .isolate_snapshot_data = null,
        .isolate_snapshot_data_size = 0,
        .isolate_snapshot_instructions = null,
        .isolate_snapshot_instructions_size = 0,
        .root_isolate_create_callback = null,
        .update_semantics_node_callback = null,
        .update_semantics_custom_action_callback = null,
        .persistent_cache_path = null,
        .is_persistent_cache_read_only = false,
        .custom_dart_entrypoint = null,
        .custom_task_runners = null,
        .shutdown_dart_vm_when_done = true,
        .dart_old_gen_heap_size = -1,
        .aot_data = aot_data,
        .compute_platform_resolved_locale_callback = null,
        .dart_entrypoint_argc = 0,
        .dart_entrypoint_argv = null,
        .on_pre_engine_restart_callback = null,
        .update_semantics_callback = null,
        .update_semantics_callback2 = null,
      },
      .proc_table = proc_table,
      .has_flutter = false,
    };

    errdefer t.allocator.free(self.dir);
    errdefer self.ipcs.deinit();

    if (params.ipcs) |ipcs| {
      for (ipcs) |ipc_params| {
        try self.ipcs.append(try ipc.Ipc.init(ipc_params, self, self.type.allocator));
      }
    }

    // TODO: determine a compatible displaykit backend based on the OS
    self.displaykit = try displaykit.Backend.init(if (params.display) |value| value else .{
      .wlroots = .{
        .base = .{
          .type = .compositor,
        },
      },
    }, params.renderer, self, t.allocator);

    var result = self.proc_table.Initialize.?(flutter.c.FLUTTER_ENGINE_VERSION, @constCast(&self.displaykit.toBase()).toContext().renderer.toBase().getEngineImpl(), &self.project_args, self, &self.engine);
    if (result != flutter.c.kSuccess) return error.EngineFail;

    self.has_flutter = true;
    try @constCast(&self.displaykit.toBase()).toContext().notifyFlutter(self);
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .mode = self.mode,
      .ipc = try self.ipc.ref(t.allocator),
      .has_flutter = self.has_flutter,
    };
  }

  pub fn unref(self: *Self) void {
    for (self.ipcs.items) |*ipc_obj| {
      ipc_obj.unref();
    }

    self.ipcs.deinit();
    self.type.allocator.free(self.dir);
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
dir: []const u8,
ipcs: std.ArrayList(ipc.Ipc),
displaykit: displaykit.Backend,
mode: Mode,
engine: flutter.c.FlutterEngine,
project_args: flutter.c.FlutterProjectArgs,
proc_table: flutter.c.FlutterEngineProcTable,
has_flutter: bool,

pub usingnamespace Type.Impl;

pub fn run(self: *Self) !void {
  const result = self.proc_table.RunInitialized.?(self.engine);
  if (result != flutter.c.kSuccess) return error.EngineFail;
}
