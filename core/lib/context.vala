namespace Neutron {
  internal static Context? global_context;

  public class Context : GLib.Object, GLib.Initable {
    public static unowned Context? get_global() {
      if (global_context == null) {
#if HAS_LIBPEAS
        try {
          global_context = new PeasContext();
            GLib.debug(N_("Global context uses libpeas"));
          return global_context;
        } catch (GLib.Error e) {
          GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
          global_context = null;
        }
#endif
#if HAS_GMODULE
        if (GLib.Module.supported()) {
          try {
            global_context = new GModuleContext();
            GLib.debug(N_("Global context uses GModule"));
            return global_context;
          } catch (GLib.Error e) {
            GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
            global_context = null;
          }
        }
#endif

        try {
          global_context = new Context();
          GLib.debug(N_("Using base context as the global context"));
          return global_context;
        } catch (GLib.Error e) {
          GLib.critical(N_("Failed to create a new context: %s:%d: %s"), e.domain.to_string(), e.code, e.message);
          global_context = null;
        }
      }
      return global_context;
    }

    public Context(GLib.Cancellable? cancellable = null) throws GLib.Error {
      Object();
      this.init(cancellable);
    }

    construct {
      GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
      GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALDIR);
    }

    public bool init(GLib.Cancellable? cancellable = null) throws GLib.Error {
      return true;
    }
  }
}
