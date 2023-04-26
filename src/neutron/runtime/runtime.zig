const std = @import("std");
const xev = @import("xev");
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
      .engine = null,
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
        .custom_task_runners = &self.task_runners,
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
      .platform_id = std.Thread.getCurrentId(),
      .loop = try xev.Loop.init(.{}),
    };

    self.platform_task_runner.user_data = self;
    self.render_task_runner.user_data = self;

    self.task_runners.platform_task_runner = &self.platform_task_runner;
    self.task_runners.render_task_runner = &self.render_task_runner;

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

    self.project_args.compositor = @constCast(&self.displaykit.toBase()).toContext().renderer.toBase().getCompositorImpl();
  }

  pub fn ref(self: *Self, dest: *Self, t: Type) !void {
    dest.* = .{
      .type = t,
      .mode = self.mode,
      .ipc = try self.ipc.ref(t.allocator),
      .loop = self.loop,
      .platform_id = self.platform_id,
    };
  }

  pub fn unref(self: *Self) void {
    for (self.ipcs.items) |*ipc_obj| {
      ipc_obj.unref();
    }

    self.loop.deinit();

    self.ipcs.deinit();
    self.type.allocator.free(self.dir);
  }
};

const Task = struct {
  runtime: *Self,
  completion: xev.Completion,
  flutter: flutter.c.FlutterTask,

  fn init(runtime: *Self, task: flutter.c.FlutterTask, time: u64) !*Task {
    const self = try runtime.type.allocator.create(Task);
    self.* = .{
      .runtime = runtime,
      .completion = undefined,
      .flutter = task,
    };

    runtime.loop.timer(&self.completion, time, @ptrCast(*anyopaque, @alignCast(@alignOf(anyopaque), self)), Task.callback);
    return self;
  }

  fn callback(ud: ?*anyopaque, loop: *xev.Loop, completion: *xev.Completion, res: xev.Result) xev.CallbackAction {
    _ = loop;
    _ = completion;
    _ = res;

    const self = @ptrCast(*Task, @alignCast(@alignOf(Task), ud.?));
    defer self.runtime.type.allocator.destroy(self);

    std.debug.print("{}\n", .{ self });

    _ = self.runtime.proc_table.RunTask.?(self.runtime.engine, &self.flutter);
    return .disarm;
  }
};

pub const Type = elemental.Type(Self, Params, Impl);

@"type": Type,
dir: []const u8,
ipcs: std.ArrayList(ipc.Ipc),
displaykit: displaykit.Backend,
mode: Mode,
loop: xev.Loop,
engine: flutter.c.FlutterEngine,
project_args: flutter.c.FlutterProjectArgs,
proc_table: flutter.c.FlutterEngineProcTable,
platform_id: std.Thread.Id,
platform_task_mutex: std.Thread.Mutex = .{},
platform_task_runner: flutter.c.FlutterTaskRunnerDescription = .{
  .struct_size = @sizeOf(flutter.c.FlutterTaskRunnerDescription),
  .user_data = null,
  .identifier = 0,
  .runs_task_on_current_thread_callback = (struct {
    fn callback(_self: ?*anyopaque) callconv(.C) bool {
      const self = Type.fromOpaque(_self.?);
      return self.platform_id == std.Thread.getCurrentId();
    }
  }).callback,
  .post_task_callback = (struct {
    fn callback(task: flutter.c.FlutterTask, time: u64, _self: ?*anyopaque) callconv(.C) void {
      const self = Type.fromOpaque(_self.?);

      self.platform_task_mutex.lock();

      _ = Task.init(self, task, time) catch |err| {
        std.debug.print("Failed to create task: {s}\n", .{ @errorName(err) });
      };

      self.platform_task_mutex.unlock();
    }
  }).callback,
},
render_task_mutex: std.Thread.Mutex = .{},
render_task_runner: flutter.c.FlutterTaskRunnerDescription = .{
  .struct_size = @sizeOf(flutter.c.FlutterTaskRunnerDescription),
  .user_data = null,
  .identifier = 0,
  .runs_task_on_current_thread_callback = (struct {
    fn callback(_self: ?*anyopaque) callconv(.C) bool {
      const self = Type.fromOpaque(_self.?);
      return self.platform_id == std.Thread.getCurrentId();
    }
  }).callback,
  .post_task_callback = (struct {
    fn callback(task: flutter.c.FlutterTask, time: u64, _self: ?*anyopaque) callconv(.C) void {
      const self = Type.fromOpaque(_self.?);

      self.render_task_mutex.lock();

      _ = Task.init(self, task, time) catch |err| {
        std.debug.print("Failed to create task: {s}\n", .{ @errorName(err) });
      };

      self.render_task_mutex.unlock();
    }
  }).callback,
},
task_runners: flutter.c.FlutterCustomTaskRunners = .{
  .struct_size = @sizeOf(flutter.c.FlutterCustomTaskRunners),
  .platform_task_runner = null,
  .render_task_runner = null,
  .thread_priority_setter = null,
},

pub usingnamespace Type.Impl;

pub fn notifyDisplays(self: *Self) !void {
  const outputs = try @constCast(&self.displaykit.toBase()).toContext().getOutputs();
  defer outputs.unref();

  if (outputs.items.len == 0) {
    self.loop.stop();
  } else {
    const displays = try self.type.allocator.alloc(flutter.c.FlutterEngineDisplay, outputs.items.len);
    defer self.type.allocator.free(displays);

    for (outputs.items, displays) |output, *display| {
      display.* = .{
        .struct_size = @sizeOf(flutter.c.FlutterEngineDisplay),
        .display_id = output.getId(),
        .single_display = false,
        .refresh_rate = std.math.lossyCast(f64, output.getRefreshRate()),
      };
    }

    const result = self.proc_table.NotifyDisplayUpdate.?(self.engine, flutter.c.kFlutterEngineDisplaysUpdateTypeStartup, displays.ptr, displays.len);
    if (result != flutter.c.kSuccess) return error.EngineFail;
  }
}

pub fn run(self: *Self) !void {
  const result = self.proc_table.Run.?(flutter.c.FLUTTER_ENGINE_VERSION, @constCast(&self.displaykit.toBase()).toContext().renderer.toBase().getEngineImpl(), &self.project_args, self, &self.engine);
  if (result != flutter.c.kSuccess) return error.EngineFail;

  try self.notifyDisplays();
  try self.loop.run(.until_done);
}
