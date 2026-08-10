import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { createComputed, createState } from "ags"
import { connectToAp, selectedAp } from "../services/wifi"

export const PasswordPrompt = () => {
  const [ap, setAp] = selectedAp
  const [password, setPassword] = createState("")
  const visible = createComputed(() => ap.peek() !== null)

  function submit() {
    const target = ap.peek()
    if (!target) return
    connectToAp(target, password.peek())
    setPassword("")
    setAp(null)
  }

  return (
    <box class="password-prompt" vertical={true} spacing={8} visible={visible}>
      <box spacing={8}>
        <label
          class="password-title"
          hexpand={true}
          halign="start"
          ellipsize="end"
          label={ap.as(
            (selected) =>
              selected ? `Enter password for "${selected.ssid || "hidden network"}"` : "",
          )}
        />
        <button class="password-cancel" onClicked={() => setAp(null)}>
          <icon name="window-close-symbolic" />
        </button>
      </box>
      <box spacing={8}>
        <entry
          class="password-entry"
          hexpand={true}
          visibility={false}
          placeholderText="Network password"
          text={password}
          onNotifyText={(self: Gtk.Entry) => setPassword(self.text)}
          onActivate={submit}
          $={(self: Gtk.Widget) => {
            const controller = Gtk.EventControllerKey.new()
            controller.connect("key-released", (_c, keyval) => {
              if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) submit()
            })
            self.add_controller(controller)
          }}
        />
        <button class="password-ok" onClicked={submit} tooltipText="Connect">
          <icon name="emblem-ok-symbolic" />
        </button>
      </box>
    </box>
  )
}

export default PasswordPrompt