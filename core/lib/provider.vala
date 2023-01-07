namespace Neutron {
  public interface Provider : GLib.Object {
    public abstract Context context { get; construct; }
  }
}
