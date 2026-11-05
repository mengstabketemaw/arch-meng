# Make Backspace go back in Nautilus (same as Alt+Left / the header-bar back button).
#
# The shortcut runs in the BUBBLE phase, so text fields (location bar, search,
# rename) still get Backspace first and keep deleting characters normally.
# Requires: nautilus-python
import gi

gi.require_version("Gtk", "4.0")
from gi.repository import GLib, GObject, Gtk, Nautilus  # noqa: E402


def _attach(win):
    if win.__gtype__.name != "NautilusWindow" or getattr(win, "_backspace_back", False):
        return
    ctrl = Gtk.ShortcutController()
    ctrl.set_propagation_phase(Gtk.PropagationPhase.BUBBLE)
    ctrl.add_shortcut(
        Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string("BackSpace"),
            Gtk.NamedAction.new("win.back"),
        )
    )
    win.add_controller(ctrl)
    win._backspace_back = True


def _scan(model, *_):
    for i in range(model.get_n_items()):
        _attach(model.get_item(i))


def _setup():
    toplevels = Gtk.Window.get_toplevels()
    toplevels.connect("items-changed", _scan)
    _scan(toplevels)
    return GLib.SOURCE_REMOVE


class BackspaceBack(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()
        GLib.idle_add(_setup)
